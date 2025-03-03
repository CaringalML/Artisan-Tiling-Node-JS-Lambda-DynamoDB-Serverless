// Local development server
const app = require('./index');
const express = require('express');
const bodyParser = require('body-parser');

// Use port from environment variable or default to 3000
const port = process.env.PORT || 3000;

// Create a standalone Express app for local testing
const localApp = express();

// Setup middleware
localApp.use(bodyParser.json());

// Set environment variables that would be set in Lambda
process.env.DYNAMODB_TABLE = process.env.DYNAMODB_TABLE || 'artisan-tiling-contacts-local';
process.env.CORS_ORIGIN = process.env.CORS_ORIGIN || 'http://localhost:8080';

// Forward all requests to the Lambda handler's Express app routes
localApp.use('/', app);

// Start the server
localApp.listen(port, () => {
  console.log(`Local development server running at http://localhost:${port}`);
  console.log(`Test the API with: curl -X POST http://localhost:${port}/contact \\
  -H "Content-Type: application/json" \\
  -d '{"name":"Test User","email":"test@example.com","phone":"0211234567","message":"Test message","service":"Test Service"}'`);
});