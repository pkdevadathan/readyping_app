const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Store OTPs temporarily (in production, use Redis)
const otpStore = new Map();

// Generate and send OTP
router.post('/send-otp', async (req, res) => {
  try {
    const { phoneNumber, restaurantName, userType = 'customer' } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({
        error: {
          message: 'Phone number is required.'
        }
      });
    }

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store OTP with expiration (5 minutes)
    otpStore.set(phoneNumber, {
      otp,
      expiresAt: Date.now() + 5 * 60 * 1000,
      restaurantName: restaurantName || `Restaurant ${phoneNumber.substring(phoneNumber.length - 4)}`,
      userType: userType
    });

    // In production, integrate with SMS service like Twilio
    console.log(`📱 Demo OTP for ${phoneNumber}: ${otp}`);

    res.json({
      message: 'OTP sent successfully.',
      phoneNumber,
      demo: true, // Indicates this is demo mode
      otp: otp // Always show OTP in demo mode
    });
  } catch (error) {
    console.error('❌ Send OTP error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to send OTP.'
      }
    });
  }
});

// Verify OTP and login
router.post('/verify-otp', async (req, res) => {
  try {
    const { phoneNumber, otp } = req.body;

    if (!phoneNumber || !otp) {
      return res.status(400).json({
        error: {
          message: 'Phone number and OTP are required.'
        }
      });
    }

    // Check if OTP exists and is valid
    const storedOTP = otpStore.get(phoneNumber);
    
    if (!storedOTP || storedOTP.otp !== otp || Date.now() > storedOTP.expiresAt) {
      return res.status(400).json({
        error: {
          message: 'Invalid or expired OTP.'
        }
      });
    }

    // Create demo user data based on user type
    const user = {
      id: `user_${Date.now()}`,
      phoneNumber,
      name: storedOTP.userType === 'customer' ? `Customer ${phoneNumber.substring(phoneNumber.length - 4)}` : null,
      restaurantName: storedOTP.userType === 'restaurant' ? storedOTP.restaurantName : null,
      email: null,
      role: storedOTP.userType === 'customer' ? 'customer' : 'owner',
      isActive: true,
      whatsappEnabled: true,
      settings: {},
      createdAt: new Date(),
      lastLogin: new Date()
    };

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    // Clear OTP
    otpStore.delete(phoneNumber);

    res.json({
      message: 'Login successful.',
      token,
      user: {
        id: user.id,
        restaurantName: user.restaurantName,
        phoneNumber: user.phoneNumber,
        role: user.role,
        settings: user.settings
      }
    });
  } catch (error) {
    console.error('❌ Verify OTP error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to verify OTP.'
      }
    });
  }
});

// Register new restaurant
router.post('/register', async (req, res) => {
  try {
    const { restaurantName, phoneNumber, email, password } = req.body;

    if (!restaurantName || !phoneNumber) {
      return res.status(400).json({
        error: {
          message: 'Restaurant name and phone number are required.'
        }
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ phoneNumber });
    if (existingUser) {
      return res.status(400).json({
        error: {
          message: 'User with this phone number already exists.'
        }
      });
    }

    // Create new user
    const user = new User({
      restaurantName,
      phoneNumber,
      email,
      password,
      role: 'owner'
    });

    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'Registration successful.',
      token,
      user: {
        id: user._id,
        restaurantName: user.restaurantName,
        phoneNumber: user.phoneNumber,
        role: user.role,
        settings: user.settings
      }
    });
  } catch (error) {
    console.error('❌ Registration error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to register.'
      }
    });
  }
});

// Get current user profile
router.get('/profile', auth, async (req, res) => {
  try {
    res.json({
      user: {
        id: req.user._id || req.user.id,
        name: req.user.name,
        restaurantName: req.user.restaurantName,
        phoneNumber: req.user.phoneNumber,
        email: req.user.email,
        role: req.user.role,
        settings: req.user.settings,
        lastLogin: req.user.lastLogin
      }
    });
  } catch (error) {
    console.error('❌ Get profile error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to get profile.'
      }
    });
  }
});

// Update user profile
router.put('/profile', auth, async (req, res) => {
  try {
    const { restaurantName, email, settings } = req.body;

    if (restaurantName) req.user.restaurantName = restaurantName;
    if (email) req.user.email = email;
    if (settings) req.user.settings = { ...req.user.settings, ...settings };

    await req.user.save();

    res.json({
      message: 'Profile updated successfully.',
      user: {
        id: req.user._id,
        restaurantName: req.user.restaurantName,
        phoneNumber: req.user.phoneNumber,
        email: req.user.email,
        role: req.user.role,
        settings: req.user.settings
      }
    });
  } catch (error) {
    console.error('❌ Update profile error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to update profile.'
      }
    });
  }
});

// Logout (client-side token removal)
router.post('/logout', auth, async (req, res) => {
  try {
    // In a more secure setup, you might want to blacklist the token
    res.json({
      message: 'Logout successful.'
    });
  } catch (error) {
    console.error('❌ Logout error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to logout.'
      }
    });
  }
});

module.exports = router; 