const AWSXRay = require('aws-xray-sdk');
const inventoryModel = require('../models/inventoryModel');

exports.createItem = async (req, res) => {
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
    
    // Create inventory item
    const result = await inventoryModel.create({
      name,
      category,
      quantity,
      price,
      description,
      sku
    });
    
    // Return success response
    return res.status(201).json({
      success: true,
      id: result.id,
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
};

exports.getAllItems = async (req, res) => {
  try {
    const result = await inventoryModel.getAll();
    
    return res.status(200).json({
      success: true,
      items: result.items,
      count: result.count
    });
  } catch (error) {
    console.error('Error fetching inventory items:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while fetching inventory items.'
    });
  }
};

exports.getItemById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const item = await inventoryModel.getById(id);
    
    if (!item) {
      return res.status(404).json({
        success: false,
        error: 'Inventory item not found.'
      });
    }
    
    return res.status(200).json({
      success: true,
      item
    });
  } catch (error) {
    console.error('Error fetching inventory item:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while fetching the inventory item.'
    });
  }
};

exports.updateItem = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, category, quantity, price, description, sku } = req.body;
    
    // Validate required fields
    if (!name || !category || !quantity || !price) {
      return res.status(400).json({
        success: false,
        error: 'Name, category, quantity, and price are required fields.'
      });
    }
    
    const updatedItem = await inventoryModel.update(id, {
      name,
      category,
      quantity,
      price,
      description,
      sku
    });
    
    if (!updatedItem) {
      return res.status(404).json({
        success: false,
        error: 'Inventory item not found.'
      });
    }
    
    return res.status(200).json({
      success: true,
      message: 'Inventory item updated successfully.',
      item: updatedItem
    });
  } catch (error) {
    console.error('Error updating inventory item:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while updating the inventory item.'
    });
  }
};

exports.deleteItem = async (req, res) => {
  try {
    const { id } = req.params;
    
    const success = await inventoryModel.delete(id);
    
    if (!success) {
      return res.status(404).json({
        success: false,
        error: 'Inventory item not found.'
      });
    }
    
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
};