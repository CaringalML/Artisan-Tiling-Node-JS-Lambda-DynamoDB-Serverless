const { v4: uuidv4 } = require('uuid');
const { dynamoDb, config } = require('../config/db');

class InventoryModel {
  constructor() {
    this.tableName = config.INVENTORY_TABLE;
  }

  async create(data) {
    const { name, category, quantity, price, description, sku } = data;
    
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
    const { name, category, quantity, price, description, sku } = data;
    
    // Get existing item
    const existingItem = await this.getById(id);
    
    if (!existingItem) {
      return null;
    }
    
    const timestamp = new Date().toISOString();
    
    const updateParams = {
      TableName: this.tableName,
      Key: { id },
      UpdateExpression: 'SET #name = :name, category = :category, quantity = :quantity, price = :price, description = :description, sku = :sku, updatedAt = :updatedAt',
      ExpressionAttributeNames: {
        '#name': 'name' // 'name' is a reserved word in DynamoDB
      },
      ExpressionAttributeValues: {
        ':name': name,
        ':category': category,
        ':quantity': Number(quantity),
        ':price': Number(price),
        ':description': description || existingItem.description || '',
        ':sku': sku || existingItem.sku,
        ':updatedAt': timestamp
      },
      ReturnValues: 'ALL_NEW'
    };
    
    const result = await dynamoDb.update(updateParams).promise();
    
    return result.Attributes;
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
}

module.exports = new InventoryModel();