const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  orderId: {
    type: String,
    required: true,
    unique: true
  },
  restaurantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  customerName: {
    type: String,
    required: true,
    trim: true
  },
  phoneNumber: {
    type: String,
    required: true,
    trim: true
  },
  status: {
    type: String,
    enum: ['pending', 'preparing', 'ready', 'completed', 'cancelled'],
    default: 'pending'
  },
  items: [{
    name: {
      type: String,
      required: true
    },
    quantity: {
      type: Number,
      required: true,
      min: 1
    },
    price: {
      type: Number,
      required: true,
      min: 0
    },
    notes: String
  }],
  totalAmount: {
    type: Number,
    required: true,
    min: 0
  },
  estimatedTime: {
    type: Number, // in minutes
    default: 15
  },
  readyAt: {
    type: Date
  },
  completedAt: {
    type: Date
  },
  notificationSent: {
    type: Boolean,
    default: false
  },
  notificationHistory: [{
    type: {
      type: String,
      enum: ['whatsapp', 'sms', 'email'],
      required: true
    },
    sentAt: {
      type: Date,
      default: Date.now
    },
    status: {
      type: String,
      enum: ['sent', 'delivered', 'failed'],
      default: 'sent'
    },
    message: String,
    error: String
  }],
  notes: {
    type: String,
    trim: true
  },
  priority: {
    type: String,
    enum: ['low', 'normal', 'high', 'urgent'],
    default: 'normal'
  },
  tags: [{
    type: String,
    trim: true
  }]
}, {
  timestamps: true
});

// Indexes for better performance
orderSchema.index({ restaurantId: 1, status: 1 });
orderSchema.index({ restaurantId: 1, createdAt: -1 });
orderSchema.index({ orderId: 1 });

// Virtual for order age
orderSchema.virtual('age').get(function() {
  return Math.floor((Date.now() - this.createdAt) / (1000 * 60)); // minutes
});

// Virtual for time since ready
orderSchema.virtual('timeSinceReady').get(function() {
  if (!this.readyAt) return null;
  return Math.floor((Date.now() - this.readyAt) / (1000 * 60)); // minutes
});

// Method to mark order as ready
orderSchema.methods.markAsReady = function() {
  this.status = 'ready';
  this.readyAt = new Date();
  return this.save();
};

// Method to mark order as completed
orderSchema.methods.markAsCompleted = function() {
  this.status = 'completed';
  this.completedAt = new Date();
  return this.save();
};

// Method to add notification record
orderSchema.methods.addNotification = function(type, message, status = 'sent', error = null) {
  this.notificationHistory.push({
    type,
    message,
    status,
    error
  });
  this.notificationSent = true;
  return this.save();
};

// Ensure virtuals are included in JSON
orderSchema.set('toJSON', { virtuals: true });
orderSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Order', orderSchema); 