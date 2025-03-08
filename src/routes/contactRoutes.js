const express = require('express');
const router = express.Router();
const contactController = require('../controllers/contactController');

// POST endpoint for contact form
router.post('/', contactController.submitContact);

module.exports = router;