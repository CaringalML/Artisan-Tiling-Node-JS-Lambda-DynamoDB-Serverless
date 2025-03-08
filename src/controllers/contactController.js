const AWSXRay = require('aws-xray-sdk');
const contactModel = require('../models/contactModel');

exports.submitContact = async (req, res) => {
  try {
    const { name, email, phone, message, service } = req.body;
    
    // Capture custom data with X-Ray
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('ContactFormValidation');
    
    // Validate required fields
    if (!name || !email || !message) {
      subsegment.addAnnotation('validationError', true);
      subsegment.close();
      return res.status(400).json({
        success: false,
        error: 'Name, email, and message are required fields.'
      });
    }
    
    subsegment.addAnnotation('validationError', false);
    subsegment.close();
    
    // Create contact in database
    const result = await contactModel.create({
      name,
      email,
      phone,
      message,
      service
    });
    
    // Return success response
    return res.status(200).json({
      success: true,
      id: result.id,
      message: 'Contact form submitted successfully.'
    });
  } catch (error) {
    // Capture errors with X-Ray
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('ContactFormError');
    subsegment.addError(error);
    subsegment.close();
    
    console.error('Error processing contact form:', error);
    return res.status(500).json({
      success: false,
      error: 'An error occurred while processing your request.'
    });
  }
};