const express = require('express');
const bodyParser = require('body-parser');
const AWSXRay = require('aws-xray-sdk');
const { config } = require('./config/db');

// Import routes
const contactRoutes = require('./routes/contactRoutes');
const inventoryRoutes = require('./routes/inventoryRoutes');
const healthRoutes = require('./routes/healthRoutes');

// Initialize X-Ray
const XRayExpress = AWSXRay.express;

// Initialize the app
const app = express();

// Add X-Ray middleware (should be added before other middleware)
app.use(XRayExpress.openSegment('ContactFormAPI'));

app.use(bodyParser.json());

// CORS middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', config.CORS_ORIGIN);
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  
  next();
});

// Register routes
app.use('/contact', contactRoutes);
app.use('/inventory', inventoryRoutes);
app.use('/health', healthRoutes);

// Close the X-Ray segment after all other middleware
app.use(XRayExpress.closeSegment());

module.exports = app;