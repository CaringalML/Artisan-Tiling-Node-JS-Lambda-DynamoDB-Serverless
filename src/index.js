const express = require('express');
const serverless = require('serverless-http');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');
const AWS = require('aws-sdk');

// Initialize the app
const app = express();
app.use(bodyParser.json());

// Initialize DynamoDB client
const dynamoDb = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.DYNAMODB_TABLE;
const CORS_ORIGIN = process.env.CORS_ORIGIN || 'https://artisantiling.co.nz';

// CORS middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', CORS_ORIGIN);
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
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
    
    // Validate required fields
    if (!name || !email || !message) {
      return res.status(400).json({
        success: false,
        error: 'Name, email, and message are required fields.'
      });
    }
    
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
    console.error('Error processing contact form:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while processing your request.'
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  return res.status(200).json({ status: 'ok' });
});

// Create handler for AWS Lambda
const handler = serverless(app);

// Export handler for Lambda
module.exports.handler = async (event, context) => {
  return await handler(event, context);
};