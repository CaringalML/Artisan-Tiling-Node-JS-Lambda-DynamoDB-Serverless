const AWS = require('aws-sdk');
const AWSXRay = require('aws-xray-sdk');

// Capture all AWS SDK calls
const XRayAWS = AWSXRay.captureAWS(AWS);

// Initialize DynamoDB client with X-Ray tracing
const dynamoDb = new XRayAWS.DynamoDB.DocumentClient();

// Export environment variables as config
const config = {
  CONTACT_TABLE: process.env.DYNAMODB_TABLE,
  INVENTORY_TABLE: process.env.INVENTORY_TABLE_NAME,
  CORS_ORIGIN: process.env.CORS_ORIGIN || 'https://artisantiling.co.nz'
};

module.exports = {
  dynamoDb,
  config
};