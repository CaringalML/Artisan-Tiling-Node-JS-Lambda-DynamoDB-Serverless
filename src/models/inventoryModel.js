const { v4: uuidv4 } = require('uuid');
const { dynamoDb, config } = require('../config/db');
const AWSXRay = require('aws-xray-sdk');

class InventoryModel {
  constructor() {
    this.tableName = config.INVENTORY_TABLE;
  }

  async create(data) {
    const { name, category, quantity, price, description, location, sku } = data;
    
    // Create item for DynamoDB
    const timestamp = new Date().toISOString();
    const id = uuidv4();
    
    const params = {
      TableName: this.tableName,
      Item: {
        id,
        name,
        category,
        quantity: Number(quantity),
        price: Number(price),
        description: description || '',
        location: location || '', // Add the location field
        sku: sku || `SKU-${id.substring(0, 8).toUpperCase()}`,
        createdAt: timestamp,
        updatedAt: timestamp
      }
    };
    
    // Store item in DynamoDB
    await dynamoDb.put(params).promise();
    
    return {
      id,
      success: true
    };
  }

  async getAll() {
    const params = {
      TableName: this.tableName
    };
    
    const result = await dynamoDb.scan(params).promise();
    
    return {
      items: result.Items,
      count: result.Count
    };
  }

  async getById(id) {
    const params = {
      TableName: this.tableName,
      Key: { id }
    };
    
    const result = await dynamoDb.get(params).promise();
    
    return result.Item;
  }

  async update(id, data) {
    try {
      // Add debugging for incoming update request
      console.log(`Updating item with ID: ${id}`);
      console.log('Update data:', JSON.stringify(data, null, 2));
      
      // Get existing item to verify it exists
      const existingItem = await this.getById(id);
      console.log('Existing item:', JSON.stringify(existingItem, null, 2));
      
      if (!existingItem) {
        console.error('Item not found with ID:', id);
        return null;
      }
      
      const { name, category, quantity, price, description, location, sku } = data;
      const timestamp = new Date().toISOString();
      
      // Create a safer update expression and attribute values
      let updateExpression = 'SET updatedAt = :updatedAt';
      let expressionAttributeNames = {};
      let expressionAttributeValues = {
        ':updatedAt': timestamp
      };
      
      // Only include fields that are present in the update data
      if (name !== undefined) {
        updateExpression += ', #itemName = :name';
        expressionAttributeNames['#itemName'] = 'name'; // Use alias for reserved word
        expressionAttributeValues[':name'] = name;
      }
      
      if (category !== undefined) {
        updateExpression += ', category = :category';
        expressionAttributeValues[':category'] = category;
      }
      
      if (quantity !== undefined) {
        updateExpression += ', quantity = :quantity';
        expressionAttributeValues[':quantity'] = Number(quantity);
      }
      
      if (price !== undefined) {
        updateExpression += ', price = :price';
        expressionAttributeValues[':price'] = Number(price);
      }
      
      if (description !== undefined) {
        updateExpression += ', description = :description';
        expressionAttributeValues[':description'] = description || '';
      }
      
      if (location !== undefined) {
        updateExpression += ', #itemLocation = :location'; // Use alias for safety
        expressionAttributeNames['#itemLocation'] = 'location';
        expressionAttributeValues[':location'] = location || '';
      }
      
      if (sku !== undefined) {
        updateExpression += ', sku = :sku';
        expressionAttributeValues[':sku'] = sku || existingItem.sku;
      }
      
      const updateParams = {
        TableName: this.tableName,
        Key: { id },
        UpdateExpression: updateExpression,
        ExpressionAttributeValues: expressionAttributeValues,
        ReturnValues: 'ALL_NEW'
      };
      
      // Only add ExpressionAttributeNames if we have entries
      if (Object.keys(expressionAttributeNames).length > 0) {
        updateParams.ExpressionAttributeNames = expressionAttributeNames;
      }
      
      console.log('DynamoDB update params:', JSON.stringify(updateParams, null, 2));
      
      // Wrap the update operation in an X-Ray subsegment for tracing
      const segment = AWSXRay.getSegment();
      const subsegment = segment.addNewSubsegment('DynamoDBUpdate');
      
      try {
        const result = await dynamoDb.update(updateParams).promise();
        subsegment.close();
        
        console.log('Update succeeded, returning updated item:', JSON.stringify(result.Attributes, null, 2));
        return result.Attributes;
      } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        console.error('DynamoDB update operation failed:', error);
        throw error;
      }
    } catch (error) {
      console.error('Error in update method:', error);
      throw error;
    }
  }

  async delete(id) {
    // Check if item exists
    const existingItem = await this.getById(id);
    
    if (!existingItem) {
      return false;
    }
    
    const deleteParams = {
      TableName: this.tableName,
      Key: { id }
    };
    
    await dynamoDb.delete(deleteParams).promise();
    
    return true;
  }
  
  // You'll also need this method for the getItemsByLocation functionality
  async getByLocation(location) {
    const params = {
      TableName: this.tableName,
      FilterExpression: 'location = :location',
      ExpressionAttributeValues: {
        ':location': location
      }
    };
    
    const result = await dynamoDb.scan(params).promise();
    
    return result.Items;
  }
}

module.exports = new InventoryModel();