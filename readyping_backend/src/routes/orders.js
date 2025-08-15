const express = require('express');
const Order = require('../models/Order');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const whatsappService = require('../services/whatsappService');

const router = express.Router();

// Store demo orders in memory (in production, use database)
const demoOrders = new Map();

// Get all orders for restaurant
router.get('/', auth, async (req, res) => {
  try {
    const { status, page = 1, limit = 20, sort = '-createdAt' } = req.query;
    
    // Get orders for this restaurant
    const restaurantOrders = Array.from(demoOrders.values())
      .filter(order => order.restaurantId === req.user.id);
    
    // Filter by status if specified
    let filteredOrders = restaurantOrders;
    if (status && status !== 'all') {
      filteredOrders = restaurantOrders.filter(order => order.status === status);
    }
    
    // Sort orders (simplified sorting)
    filteredOrders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    // Pagination
    const total = filteredOrders.length;
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + parseInt(limit);
    const paginatedOrders = filteredOrders.slice(startIndex, endIndex);

    res.json({
      orders: paginatedOrders,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalOrders: total,
        hasNext: endIndex < total,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('❌ Get orders error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to fetch orders.'
      }
    });
  }
});

// Get order statistics (must come before /:orderId route)
router.get('/stats/overview', auth, async (req, res) => {
  try {
    const { period = 'today' } = req.query;
    
    let dateFilter = {};
    const now = new Date();
    
    switch (period) {
      case 'today':
        dateFilter = {
          createdAt: {
            $gte: new Date(now.getFullYear(), now.getMonth(), now.getDate())
          }
        };
        break;
      case 'week':
        dateFilter = {
          createdAt: {
            $gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
          }
        };
        break;
      case 'month':
        dateFilter = {
          createdAt: {
            $gte: new Date(now.getFullYear(), now.getMonth(), 1)
          }
        };
        break;
    }

    const stats = await Order.aggregate([
      {
        $match: {
          restaurantId: req.user._id,
          ...dateFilter
        }
      },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalAmount: { $sum: '$totalAmount' }
        }
      }
    ]);

    const totalOrders = await Order.countDocuments({
      restaurantId: req.user._id,
      ...dateFilter
    });

    const totalRevenue = await Order.aggregate([
      {
        $match: {
          restaurantId: req.user._id,
          status: 'completed',
          ...dateFilter
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$totalAmount' }
        }
      }
    ]);

    res.json({
      stats: stats.reduce((acc, stat) => {
        acc[stat._id] = {
          count: stat.count,
          totalAmount: stat.totalAmount
        };
        return acc;
      }, {}),
      totalOrders,
      totalRevenue: totalRevenue[0]?.total || 0,
      period
    });
  } catch (error) {
    console.error('❌ Get stats error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to fetch statistics.'
      }
    });
  }
});

// Get single order
router.get('/:orderId', auth, async (req, res) => {
  try {
    const order = await Order.findOne({
      orderId: req.params.orderId,
      restaurantId: req.user._id
    }).populate('restaurantId', 'restaurantName');

    if (!order) {
      return res.status(404).json({
        error: {
          message: 'Order not found.'
        }
      });
    }

    res.json({ order });
  } catch (error) {
    console.error('❌ Get order error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to fetch order.'
      }
    });
  }
});

// Create new order
router.post('/', auth, async (req, res) => {
  try {
    const {
      orderId,
      customerName,
      phoneNumber,
      items,
      totalAmount,
      estimatedTime,
      notes,
      priority
    } = req.body;

    if (!orderId || !customerName || !phoneNumber) {
      return res.status(400).json({
        error: {
          message: 'Order ID, customer name, and phone number are required.'
        }
      });
    }

    // Check if order ID already exists in demo orders
    const existingOrder = Array.from(demoOrders.values())
      .find(order => order.orderId === orderId);
    if (existingOrder) {
      return res.status(400).json({
        error: {
          message: 'Order ID already exists.'
        }
      });
    }

    const order = {
      id: `order_${Date.now()}`,
      orderId,
      restaurantId: req.user.id,
      customerName,
      phoneNumber,
      status: 'pending',
      items: items || [],
      totalAmount: totalAmount || 0,
      estimatedTime: estimatedTime || 15,
      notes,
      priority: priority || 'normal',
      createdAt: new Date(),
      notificationSent: false
    };

    // Store in demo orders
    demoOrders.set(order.id, order);

    // Emit real-time update
    const io = req.app.get('io');
    if (io) {
      io.to(`restaurant-${req.user.id}`).emit('order-created', {
        order,
        restaurantId: req.user.id
      });
    }

    res.status(201).json({
      message: 'Order created successfully.',
      order
    });
  } catch (error) {
    console.error('❌ Create order error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to create order.'
      }
    });
  }
});

// Update order status
router.patch('/:orderId/status', auth, async (req, res) => {
  try {
    const { status } = req.body;
    const { orderId } = req.params;

    if (!status) {
      return res.status(400).json({
        error: {
          message: 'Status is required.'
        }
      });
    }

    // Find order in demo orders
    const order = Array.from(demoOrders.values())
      .find(order => order.orderId === orderId && order.restaurantId === req.user.id);

    if (!order) {
      return res.status(404).json({
        error: {
          message: 'Order not found.'
        }
      });
    }

    const oldStatus = order.status;
    order.status = status;

    // Update timestamps based on status
    if (status === 'ready') {
      order.readyAt = new Date();
    } else if (status === 'completed') {
      order.completedAt = new Date();
    }

    // Update notification status
    if (status === 'ready') {
      order.notificationSent = true;
    }

    // Send WhatsApp notification if order is ready
    if (status === 'ready') {
      try {
        const notificationResult = await whatsappService.sendOrderReadyNotification(order);
        console.log('📱 Demo WhatsApp notification sent:', notificationResult);
      } catch (error) {
        console.error('❌ WhatsApp notification error:', error);
      }
    }

    // Emit real-time update
    const io = req.app.get('io');
    if (io) {
      io.to(`restaurant-${req.user.id}`).emit('order-status-updated', {
        orderId,
        status,
        oldStatus,
        restaurantId: req.user.id,
        readyAt: order.readyAt,
        notificationSent: order.notificationSent
      });
    }

    res.json({
      message: 'Order status updated successfully.',
      order
    });
  } catch (error) {
    console.error('❌ Update order status error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to update order status.'
      }
    });
  }
});

// Update order details
router.put('/:orderId', auth, async (req, res) => {
  try {
    const { orderId } = req.params;
    const updateData = req.body;

    const order = await Order.findOne({
      orderId,
      restaurantId: req.user._id
    });

    if (!order) {
      return res.status(404).json({
        error: {
          message: 'Order not found.'
        }
      });
    }

    // Update allowed fields
    const allowedUpdates = ['customerName', 'phoneNumber', 'items', 'totalAmount', 'estimatedTime', 'notes', 'priority', 'tags'];
    allowedUpdates.forEach(field => {
      if (updateData[field] !== undefined) {
        order[field] = updateData[field];
      }
    });

    await order.save();

    // Emit real-time update
    const io = req.app.get('io');
    io.to(`restaurant-${req.user._id}`).emit('order-updated', {
      order,
      restaurantId: req.user._id
    });

    res.json({
      message: 'Order updated successfully.',
      order
    });
  } catch (error) {
    console.error('❌ Update order error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to update order.'
      }
    });
  }
});

// Delete order
router.delete('/:orderId', auth, async (req, res) => {
  try {
    const { orderId } = req.params;

    // Find and delete order from demo orders
    const orderToDelete = Array.from(demoOrders.values())
      .find(order => order.orderId === orderId && order.restaurantId === req.user.id);

    if (!orderToDelete) {
      return res.status(404).json({
        error: {
          message: 'Order not found.'
        }
      });
    }

    // Remove from demo orders
    demoOrders.delete(orderToDelete.id);

    // Emit real-time update
    const io = req.app.get('io');
    if (io) {
      io.to(`restaurant-${req.user.id}`).emit('order-deleted', {
        orderId,
        restaurantId: req.user.id
      });
    }

    res.json({
      message: 'Order deleted successfully.'
    });
  } catch (error) {
    console.error('❌ Delete order error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to delete order.'
      }
    });
  }
});

// Bulk operations
router.post('/bulk/status', auth, async (req, res) => {
  try {
    const { orderIds, status } = req.body;

    if (!orderIds || !Array.isArray(orderIds) || !status) {
      return res.status(400).json({
        error: {
          message: 'Order IDs array and status are required.'
        }
      });
    }

    const orders = await Order.find({
      orderId: { $in: orderIds },
      restaurantId: req.user._id
    });

    const updatePromises = orders.map(order => {
      order.status = status;
      if (status === 'ready') {
        order.readyAt = new Date();
      } else if (status === 'completed') {
        order.completedAt = new Date();
      }
      return order.save();
    });

    await Promise.all(updatePromises);

    // Send notifications for ready orders
    if (status === 'ready' && req.user.whatsappEnabled) {
      const readyOrders = orders.filter(order => order.status === 'ready');
      for (const order of readyOrders) {
        try {
          const notificationResult = await whatsappService.sendOrderReadyNotification(order);
          await order.addNotification('whatsapp', notificationResult.message, notificationResult.success ? 'sent' : 'failed', notificationResult.error);
        } catch (error) {
          console.error('❌ WhatsApp notification error:', error);
          await order.addNotification('whatsapp', 'Order ready notification', 'failed', error.message);
        }
      }
    }

    // Emit real-time updates
    const io = req.app.get('io');
    io.to(`restaurant-${req.user._id}`).emit('bulk-orders-updated', {
      orderIds,
      status,
      restaurantId: req.user._id
    });

    res.json({
      message: `Updated ${orders.length} orders to ${status}.`,
      updatedCount: orders.length
    });
  } catch (error) {
    console.error('❌ Bulk update error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to update orders.'
      }
    });
  }
});

module.exports = router; 