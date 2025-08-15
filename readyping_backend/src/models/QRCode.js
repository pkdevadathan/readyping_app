const mongoose = require('mongoose');

const qrCodeSchema = new mongoose.Schema({
  restaurantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  code: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  url: {
    type: String,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  scanCount: {
    type: Number,
    default: 0
  },
  optInCount: {
    type: Number,
    default: 0
  },
  settings: {
    autoOptIn: {
      type: Boolean,
      default: true
    },
    requireConfirmation: {
      type: Boolean,
      default: false
    },
    message: {
      type: String,
      default: 'Scan to receive WhatsApp notifications when your food is ready!'
    }
  },
  lastScanned: {
    type: Date
  }
}, {
  timestamps: true
});

// Indexes
qrCodeSchema.index({ restaurantId: 1, isActive: 1 });
qrCodeSchema.index({ code: 1 });

// Method to increment scan count
qrCodeSchema.methods.incrementScan = function() {
  this.scanCount += 1;
  this.lastScanned = new Date();
  return this.save();
};

// Method to increment opt-in count
qrCodeSchema.methods.incrementOptIn = function() {
  this.optInCount += 1;
  return this.save();
};

// Generate unique QR code
qrCodeSchema.statics.generateCode = function() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < 8; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

module.exports = mongoose.model('QRCode', qrCodeSchema); 