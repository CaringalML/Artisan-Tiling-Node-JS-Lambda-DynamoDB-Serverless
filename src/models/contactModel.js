const { v4: uuidv4 } = require('uuid');
const { dynamoDb, config } = require('../config/db');

class ContactModel {
  constructor() {
    this.tableName = config.CONTACT_TABLE;
  }

  async create(data) {
    const { name, email, phone, message, service } = data;
    
    // Create item for DynamoDB
    const timestamp = new Date().toISOString();
    const id = uuidv4();
    
    const params = {
      TableName: this.tableName,
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
    
    return {
      id,
      success: true
    };
  }
}

module.exports = new ContactModel();