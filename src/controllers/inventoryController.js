const AWSXRay = require('aws-xray-sdk');
const inventoryModel = require('../models/inventoryModel');

exports.createItem = async (req, res) => {
  try {
    const { name, category, quantity, price, description, location, sku } = req.body;
    
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
      location,
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

exports.getItemsByLocation = async (req, res) => {
  try {
    const { location } = req.params;
    
    const items = await inventoryModel.getByLocation(location);
    
    return res.status(200).json({
      success: true,
      items,
      count: items.length
    });
  } catch (error) {
    console.error('Error fetching inventory items by location:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while fetching inventory items by location.'
    });
  }
};

exports.updateItem = async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`Received update request for item ID: ${id}`);
    console.log('Request body:', JSON.stringify(req.body, null, 2));
    
    // Extract fields from request body
    const { name, category, quantity, price, description, location, sku } = req.body;
    
    // Validate required fields
    if (!name && !category && quantity === undefined && price === undefined) {
      console.log('Validation failed: No valid update fields provided');
      return res.status(400).json({
        success: false,
        error: 'At least one field (name, category, quantity, or price) must be provided for update.'
      });
    }
    
    // Create update object with only the fields that are present
    const updateData = {};
    
    if (name !== undefined) updateData.name = name;
    if (category !== undefined) updateData.category = category;
    if (quantity !== undefined) updateData.quantity = quantity;
    if (price !== undefined) updateData.price = price;
    if (description !== undefined) updateData.description = description;
    if (location !== undefined) updateData.location = location;
    if (sku !== undefined) updateData.sku = sku;
    
    console.log('Update data to be sent to model:', JSON.stringify(updateData, null, 2));
    
    // Create X-Ray subsegment for update operation
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('InventoryUpdate');
    
    try {
      // Call model to update item
      const updatedItem = await inventoryModel.update(id, updateData);
      
      if (!updatedItem) {
        subsegment.addAnnotation('itemFound', false);
        subsegment.close();
        
        console.log(`Item with ID ${id} not found for update`);
        return res.status(404).json({
          success: false,
          error: 'Inventory item not found.'
        });
      }
      
      subsegment.addAnnotation('itemFound', true);
      subsegment.addAnnotation('updateSuccess', true);
      subsegment.close();
      
      console.log('Update successful, returning updated item:', JSON.stringify(updatedItem, null, 2));
      
      return res.status(200).json({
        success: true,
        message: 'Inventory item updated successfully.',
        item: updatedItem
      });
    } catch (error) {
      subsegment.addAnnotation('updateSuccess', false);
      subsegment.addError(error);
      subsegment.close();
      
      console.error('Error during update operation:', error);
      throw error; // Re-throw to be caught by outer catch block
    }
  } catch (error) {
    console.error('Error updating inventory item:', error.message);
    console.error(error.stack);
    
    return res.status(500).json({
      success: false,
      error: 'An error occurred while updating the inventory item: ' + error.message
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