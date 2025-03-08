const express = require('express');
const router = express.Router();
const inventoryController = require('../controllers/inventoryController');

// CREATE - Inventory item
router.post('/', inventoryController.createItem);

// READ - Get all inventory items
router.get('/', inventoryController.getAllItems);

// READ - Get inventory item by ID
router.get('/:id', inventoryController.getItemById);

// UPDATE - Update inventory item
router.put('/:id', inventoryController.updateItem);

// DELETE - Delete inventory item
router.delete('/:id', inventoryController.deleteItem);

module.exports = router;