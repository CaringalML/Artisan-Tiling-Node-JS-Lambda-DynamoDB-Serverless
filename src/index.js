const serverless = require('serverless-http');
const app = require('./app');

// Create handler for AWS Lambda
const handler = serverless(app);

// Export handler for Lambda
module.exports.handler = async (event, context) => {
  return await handler(event, context);
};