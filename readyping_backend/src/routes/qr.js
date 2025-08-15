const express = require('express');
const QRCode = require('../models/QRCode');
const { auth } = require('../middleware/auth');
const QR = require('qrcode');

const router = express.Router();

// Get all QR codes for restaurant
router.get('/', auth, async (req, res) => {
  try {
    const qrCodes = await QRCode.find({ restaurantId: req.user._id })
      .sort('-createdAt');

    res.json({ qrCodes });
  } catch (error) {
    console.error('❌ Get QR codes error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to fetch QR codes.'
      }
    });
  }
});

// Get QR code statistics
router.get('/stats/overview', auth, async (req, res) => {
  try {
    const stats = await QRCode.aggregate([
      {
        $match: { restaurantId: req.user._id }
      },
      {
        $group: {
          _id: null,
          totalCodes: { $sum: 1 },
          activeCodes: { $sum: { $cond: ['$isActive', 1, 0] } },
          totalScans: { $sum: '$scanCount' },
          totalOptIns: { $sum: '$optInCount' }
        }
      }
    ]);

    const recentScans = await QRCode.find({
      restaurantId: req.user._id,
      lastScanned: { $exists: true }
    })
    .sort('-lastScanned')
    .limit(5)
    .select('name scanCount lastScanned');

    res.json({
      stats: stats[0] || {
        totalCodes: 0,
        activeCodes: 0,
        totalScans: 0,
        totalOptIns: 0
      },
      recentScans
    });
  } catch (error) {
    console.error('❌ Get QR stats error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to fetch QR code statistics.'
      }
    });
  }
});

// Generate QR code image (must come before /:code route)
router.get('/:code/image', async (req, res) => {
  try {
    const { code } = req.params;
    const { size = 200, format = 'png' } = req.query;

    const qrCode = await QRCode.findOne({ 
      code,
      isActive: true 
    });

    if (!qrCode) {
      return res.status(404).json({
        error: {
          message: 'QR code not found or inactive.'
        }
      });
    }

    const qrImage = await QR.toDataURL(qrCode.url, {
      width: parseInt(size),
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    res.json({
      image: qrImage,
      url: qrCode.url
    });
  } catch (error) {
    console.error('❌ Generate QR image error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to generate QR code image.'
      }
    });
  }
});

// Get QR code by code (for customer opt-in)
router.get('/:code', async (req, res) => {
  try {
    const { code } = req.params;

    const qrCode = await QRCode.findOne({ 
      code,
      isActive: true 
    }).populate('restaurantId', 'restaurantName');

    if (!qrCode) {
      return res.status(404).json({
        error: {
          message: 'QR code not found or inactive.'
        }
      });
    }

    // Increment scan count
    await qrCode.incrementScan();

    res.json({
      qrCode: {
        id: qrCode._id,
        name: qrCode.name,
        description: qrCode.description,
        restaurantName: qrCode.restaurantId.restaurantName,
        settings: qrCode.settings
      }
    });
  } catch (error) {
    console.error('❌ Get QR code error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to fetch QR code.'
      }
    });
  }
});

// Create new QR code
router.post('/', auth, async (req, res) => {
  try {
    const { name, description, settings } = req.body;

    if (!name) {
      return res.status(400).json({
        error: {
          message: 'QR code name is required.'
        }
      });
    }

    // Generate unique code
    let code;
    let isUnique = false;
    while (!isUnique) {
      code = QRCode.generateCode();
      const existing = await QRCode.findOne({ code });
      if (!existing) {
        isUnique = true;
      }
    }

    // Generate URL for customer opt-in
    const baseUrl = process.env.FRONTEND_URL || 'http://localhost:8080';
    const url = `${baseUrl}/optin?code=${code}&restaurant=${req.user._id}`;

    const qrCode = new QRCode({
      restaurantId: req.user._id,
      code,
      name,
      description,
      url,
      settings: settings || {}
    });

    await qrCode.save();

    res.status(201).json({
      message: 'QR code created successfully.',
      qrCode
    });
  } catch (error) {
    console.error('❌ Create QR code error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to create QR code.'
      }
    });
  }
});

// Update QR code
router.put('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const qrCode = await QRCode.findOne({
      _id: id,
      restaurantId: req.user._id
    });

    if (!qrCode) {
      return res.status(404).json({
        error: {
          message: 'QR code not found.'
        }
      });
    }

    // Update allowed fields
    const allowedUpdates = ['name', 'description', 'isActive', 'settings'];
    allowedUpdates.forEach(field => {
      if (updateData[field] !== undefined) {
        qrCode[field] = updateData[field];
      }
    });

    await qrCode.save();

    res.json({
      message: 'QR code updated successfully.',
      qrCode
    });
  } catch (error) {
    console.error('❌ Update QR code error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to update QR code.'
      }
    });
  }
});

// Delete QR code
router.delete('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;

    const qrCode = await QRCode.findOneAndDelete({
      _id: id,
      restaurantId: req.user._id
    });

    if (!qrCode) {
      return res.status(404).json({
        error: {
          message: 'QR code not found.'
        }
      });
    }

    res.json({
      message: 'QR code deleted successfully.'
    });
  } catch (error) {
    console.error('❌ Delete QR code error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to delete QR code.'
      }
    });
  }
});

module.exports = router; 