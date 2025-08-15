const twilio = require('twilio');

class WhatsAppService {
  constructor() {
    // Check if Twilio credentials are available
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
      this.client = twilio(
        process.env.TWILIO_ACCOUNT_SID,
        process.env.TWILIO_AUTH_TOKEN
      );
      this.fromNumber = process.env.TWILIO_WHATSAPP_NUMBER;
      this.isDemoMode = false;
    } else {
      console.log('⚠️  Twilio credentials not found. Running in demo mode.');
      this.isDemoMode = true;
    }
  }

  async sendMessage(to, message, orderId = null) {
    try {
      // Format phone number for WhatsApp
      const formattedNumber = this.formatPhoneNumber(to);
      
      if (this.isDemoMode) {
        // Demo mode - just log the message
        console.log(`📱 DEMO WhatsApp message to ${formattedNumber}:`);
        console.log(`   Order ID: ${orderId || 'N/A'}`);
        console.log(`   Message: ${message}`);
        console.log(`   ──────────────────────────────────────────`);
        
        return {
          success: true,
          messageId: `demo_${Date.now()}`,
          status: 'delivered',
          to: formattedNumber,
          demo: true
        };
      }
      
      const result = await this.client.messages.create({
        body: message,
        from: `whatsapp:${this.fromNumber}`,
        to: `whatsapp:${formattedNumber}`
      });

      console.log(`📱 WhatsApp message sent to ${formattedNumber}:`, result.sid);
      
      return {
        success: true,
        messageId: result.sid,
        status: result.status,
        to: formattedNumber
      };
    } catch (error) {
      console.error('❌ WhatsApp send error:', error);
      return {
        success: false,
        error: error.message,
        to: to
      };
    }
  }

  async sendOrderReadyNotification(order) {
    const message = this.formatOrderReadyMessage(order);
    return this.sendMessage(order.phoneNumber, message, order.orderId);
  }

  async sendOrderUpdateNotification(order, status) {
    const message = this.formatOrderUpdateMessage(order, status);
    return this.sendMessage(order.phoneNumber, message, order.orderId);
  }

  formatOrderReadyMessage(order) {
    const template = order.restaurant?.settings?.notificationTemplate || 
      'Your order #{orderId} is ready! Please collect it from the counter.';
    
    return template
      .replace('#{orderId}', order.orderId)
      .replace('#{customerName}', order.customerName)
      .replace('#{restaurantName}', order.restaurant?.restaurantName || 'Restaurant');
  }

  formatOrderUpdateMessage(order, status) {
    const statusMessages = {
      'preparing': `Your order #${order.orderId} is now being prepared. We'll notify you when it's ready!`,
      'ready': `Your order #${order.orderId} is ready! Please collect it from the counter.`,
      'completed': `Thank you for choosing us! Your order #${order.orderId} has been completed.`,
      'cancelled': `Your order #${order.orderId} has been cancelled. Please contact us if you have any questions.`
    };

    return statusMessages[status] || `Your order #${order.orderId} status has been updated to: ${status}`;
  }

  formatPhoneNumber(phoneNumber) {
    // Remove all non-digit characters
    let cleaned = phoneNumber.replace(/\D/g, '');
    
    // Add country code if not present (assuming +1 for US/Canada)
    if (cleaned.length === 10) {
      cleaned = '1' + cleaned;
    }
    
    // Add + prefix
    return '+' + cleaned;
  }

  async sendBulkNotifications(orders, message) {
    const results = [];
    
    for (const order of orders) {
      const result = await this.sendMessage(order.phoneNumber, message, order.orderId);
      results.push({
        orderId: order.orderId,
        ...result
      });
      
      // Add delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    return results;
  }

  // Demo mode for testing
  async sendDemoMessage(to, message) {
    console.log(`📱 [DEMO] WhatsApp message would be sent to ${to}:`, message);
    return {
      success: true,
      messageId: 'demo-' + Date.now(),
      status: 'delivered',
      to: to,
      demo: true
    };
  }
}

module.exports = new WhatsAppService(); 