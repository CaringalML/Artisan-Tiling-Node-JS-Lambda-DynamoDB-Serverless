const express = require('express');
const serverless = require('serverless-http');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');
const AWS = require('aws-sdk');
const AWSXRay = require('aws-xray-sdk');

// Initialize X-Ray
const XRayExpress = AWSXRay.express;
// Capture all AWS SDK calls
const XRayAWS = AWSXRay.captureAWS(AWS);

// Initialize the app
const app = express();

// Add X-Ray middleware (should be added before other middleware)
app.use(XRayExpress.openSegment('ContactFormAPI'));

app.use(bodyParser.json());

// Initialize DynamoDB client with X-Ray tracing
const dynamoDb = new XRayAWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.DYNAMODB_TABLE;
const INVENTORY_TABLE_NAME = process.env.INVENTORY_TABLE_NAME;
const CORS_ORIGIN = process.env.CORS_ORIGIN || 'https://artisantiling.co.nz';

// CORS middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', CORS_ORIGIN);
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  
  next();
});

// POST endpoint for contact form
app.post('/contact', async (req, res) => {
  try {
    const { name, email, phone, message, service } = req.body;
    
    // Capture custom data with X-Ray
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('ContactFormValidation');
    
    // Validate required fields
    if (!name || !email || !message) {
      subsegment.addAnnotation('validationError', true);
      subsegment.close();
      return res.status(400).json({
        success: false,
        error: 'Name, email, and message are required fields.'
      });
    }
    
    subsegment.addAnnotation('validationError', false);
    subsegment.close();
    
    // Create item for DynamoDB
    const timestamp = new Date().toISOString();
    const id = uuidv4();
    
    const params = {
      TableName: TABLE_NAME,
      Item: {
        id,
        name,
        email,
        phone: phone || '',
        message,
        service: service || 'Not specified',
        createdAt: timestamp
      }
    };
    
    // Store item in DynamoDB
    await dynamoDb.put(params).promise();
    
    // Return success response
    return res.status(200).json({
      success: true,
      id,
      message: 'Contact form submitted successfully.'
    });
  } catch (error) {
    // Capture errors with X-Ray
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('ContactFormError');
    subsegment.addError(error);
    subsegment.close();
    
    console.error('Error processing contact form:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while processing your request.'
    });
  }
});

// CREATE - Inventory item
app.post('/inventory', async (req, res) => {
  try {
    const { name, category, quantity, price, description, sku } = req.body;
    
    // Capture custom data with X-Ray
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('InventoryValidation');
    
    // Validate required fields
    if (!name || !category || !quantity || !price) {
      subsegment.addAnnotation('validationError', true);
      subsegment.close();
      return res.status(400).json({
        success: false,
        error: 'Name, category, quantity, and price are required fields.'
      });
    }
    
    subsegment.addAnnotation('validationError', false);
    subsegment.close();
    
    // Create item for DynamoDB
    const timestamp = new Date().toISOString();
    const id = uuidv4();
    
    const params = {
      TableName: INVENTORY_TABLE_NAME,
      Item: {
        id,
        name,
        category,
        quantity: Number(quantity),
        price: Number(price),
        description: description || '',
        sku: sku || `SKU-${id.substring(0, 8).toUpperCase()}`,
        createdAt: timestamp,
        updatedAt: timestamp
      }
    };
    
    // Store item in DynamoDB
    await dynamoDb.put(params).promise();
    
    // Return success response
    return res.status(201).json({
      success: true,
      id,
      message: 'Inventory item created successfully.'
    });
  } catch (error) {
    // Capture errors with X-Ray
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('InventoryError');
    subsegment.addError(error);
    subsegment.close();
    
    console.error('Error creating inventory item:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while processing your request.'
    });
  }
});

// READ - Get all inventory items
app.get('/inventory', async (req, res) => {
  try {
    const params = {
      TableName: INVENTORY_TABLE_NAME
    };
    
    const result = await dynamoDb.scan(params).promise();
    
    return res.status(200).json({
      success: true,
      items: result.Items,
      count: result.Count
    });
  } catch (error) {
    console.error('Error fetching inventory items:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while fetching inventory items.'
    });
  }
});

// READ - Get inventory item by ID
app.get('/inventory/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const params = {
      TableName: INVENTORY_TABLE_NAME,
      Key: { id }
    };
    
    const result = await dynamoDb.get(params).promise();
    
    if (!result.Item) {
      return res.status(404).json({
        success: false,
        error: 'Inventory item not found.'
      });
    }
    
    return res.status(200).json({
      success: true,
      item: result.Item
    });
  } catch (error) {
    console.error('Error fetching inventory item:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while fetching the inventory item.'
    });
  }
});

// UPDATE - Update inventory item
app.put('/inventory/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, category, quantity, price, description, sku } = req.body;
    
    // Check if item exists
    const getParams = {
      TableName: INVENTORY_TABLE_NAME,
      Key: { id }
    };
    
    const existingItem = await dynamoDb.get(getParams).promise();
    
    if (!existingItem.Item) {
      return res.status(404).json({
        success: false,
        error: 'Inventory item not found.'
      });
    }
    
    // Validate required fields
    if (!name || !category || !quantity || !price) {
      return res.status(400).json({
        success: false,
        error: 'Name, category, quantity, and price are required fields.'
      });
    }
    
    const timestamp = new Date().toISOString();
    
    const updateParams = {
      TableName: INVENTORY_TABLE_NAME,
      Key: { id },
      UpdateExpression: 'SET #name = :name, category = :category, quantity = :quantity, price = :price, description = :description, sku = :sku, updatedAt = :updatedAt',
      ExpressionAttributeNames: {
        '#name': 'name' // 'name' is a reserved word in DynamoDB
      },
      ExpressionAttributeValues: {
        ':name': name,
        ':category': category,
        ':quantity': Number(quantity),
        ':price': Number(price),
        ':description': description || existingItem.Item.description || '',
        ':sku': sku || existingItem.Item.sku,
        ':updatedAt': timestamp
      },
      ReturnValues: 'ALL_NEW'
    };
    
    const result = await dynamoDb.update(updateParams).promise();
    
    return res.status(200).json({
      success: true,
      message: 'Inventory item updated successfully.',
      item: result.Attributes
    });
  } catch (error) {
    console.error('Error updating inventory item:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while updating the inventory item.'
    });
  }
});

// DELETE - Delete inventory item
app.delete('/inventory/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if item exists
    const getParams = {
      TableName: INVENTORY_TABLE_NAME,
      Key: { id }
    };
    
    const existingItem = await dynamoDb.get(getParams).promise();
    
    if (!existingItem.Item) {
      return res.status(404).json({
        success: false,
        error: 'Inventory item not found.'
      });
    }
    
    const deleteParams = {
      TableName: INVENTORY_TABLE_NAME,
      Key: { id }
    };
    
    await dynamoDb.delete(deleteParams).promise();
    
    return res.status(200).json({
      success: true,
      message: 'Inventory item deleted successfully.'
    });
  } catch (error) {
    console.error('Error deleting inventory item:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while deleting the inventory item.'
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  return res.status(200).json({ status: 'ok' });
});

// Close the X-Ray segment after all other middleware
app.use(XRayExpress.closeSegment());

// Create handler for AWS Lambda
const handler = serverless(app);

// Export handler for Lambda
module.exports.handler = async (event, context) => {
  return await handler(event, context);
};