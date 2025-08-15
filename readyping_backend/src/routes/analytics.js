const express = require('express');
const Order = require('../models/Order');
const QRCode = require('../models/QRCode');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Get dashboard overview
router.get('/dashboard', auth, async (req, res) => {
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

    // Order statistics
    const orderStats = await Order.aggregate([
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
          totalAmount: { $sum: '$totalAmount' },
          avgAmount: { $avg: '$totalAmount' }
        }
      }
    ]);

    // Revenue statistics
    const revenueStats = await Order.aggregate([
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
          totalRevenue: { $sum: '$totalAmount' },
          avgOrderValue: { $avg: '$totalAmount' },
          totalOrders: { $sum: 1 }
        }
      }
    ]);

    // Notification statistics
    const notificationStats = await Order.aggregate([
      {
        $match: {
          restaurantId: req.user._id,
          ...dateFilter
        }
      },
      {
        $group: {
          _id: null,
          totalNotifications: { $sum: { $cond: ['$notificationSent', 1, 0] } },
          successfulNotifications: {
            $sum: {
              $size: {
                $filter: {
                  input: '$notificationHistory',
                  cond: { $eq: ['$$this.status', 'sent'] }
                }
              }
            }
          }
        }
      }
    ]);

    // QR code statistics
    const qrStats = await QRCode.aggregate([
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

    // Recent orders
    const recentOrders = await Order.find({
      restaurantId: req.user._id
    })
    .sort('-createdAt')
    .limit(5)
    .select('orderId customerName status totalAmount createdAt');

    // Average preparation time
    const avgPrepTime = await Order.aggregate([
      {
        $match: {
          restaurantId: req.user._id,
          readyAt: { $exists: true },
          ...dateFilter
        }
      },
      {
        $addFields: {
          prepTime: {
            $divide: [
              { $subtract: ['$readyAt', '$createdAt'] },
              1000 * 60 // Convert to minutes
            ]
          }
        }
      },
      {
        $group: {
          _id: null,
          avgPrepTime: { $avg: '$prepTime' }
        }
      }
    ]);

    res.json({
      period,
      orderStats: orderStats.reduce((acc, stat) => {
        acc[stat._id] = {
          count: stat.count,
          totalAmount: stat.totalAmount,
          avgAmount: stat.avgAmount
        };
        return acc;
      }, {}),
      revenue: revenueStats[0] || {
        totalRevenue: 0,
        avgOrderValue: 0,
        totalOrders: 0
      },
      notifications: notificationStats[0] || {
        totalNotifications: 0,
        successfulNotifications: 0
      },
      qrCodes: qrStats[0] || {
        totalCodes: 0,
        activeCodes: 0,
        totalScans: 0,
        totalOptIns: 0
      },
      recentOrders,
      avgPrepTime: avgPrepTime[0]?.avgPrepTime || 0
    });
  } catch (error) {
    console.error('❌ Get dashboard analytics error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to fetch dashboard analytics.'
      }
    });
  }
});

// Get order trends
router.get('/orders/trends', auth, async (req, res) => {
  try {
    const { days = 7 } = req.query;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(days));

    const trends = await Order.aggregate([
      {
        $match: {
          restaurantId: req.user._id,
          createdAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            date: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            status: '$status'
          },
          count: { $sum: 1 },
          totalAmount: { $sum: '$totalAmount' }
        }
      },
      {
        $group: {
          _id: '$_id.date',
          statuses: {
            $push: {
              status: '$_id.status',
              count: '$count',
              totalAmount: '$totalAmount'
            }
          },
          totalOrders: { $sum: '$count' },
          totalAmount: { $sum: '$totalAmount' }
        }
      },
      {
        $sort: { _id: 1 }
      }
    ]);

    res.json({ trends });
  } catch (error) {
    console.error('❌ Get order trends error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to fetch order trends.'
      }
    });
  }
});

// Get performance metrics
router.get('/performance', auth, async (req, res) => {
  try {
    const { period = 'month' } = req.query;
    
    let dateFilter = {};
    const now = new Date();
    
    switch (period) {
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
      case 'quarter':
        const quarter = Math.floor(now.getMonth() / 3);
        dateFilter = {
          createdAt: {
            $gte: new Date(now.getFullYear(), quarter * 3, 1)
          }
        };
        break;
    }

    // Average order completion time
    const completionTime = await Order.aggregate([
      {
        $match: {
          restaurantId: req.user._id,
          completedAt: { $exists: true },
          ...dateFilter
        }
      },
      {
        $addFields: {
          completionTime: {
            $divide: [
              { $subtract: ['$completedAt', '$createdAt'] },
              1000 * 60 // Convert to minutes
            ]
          }
        }
      },
      {
        $group: {
          _id: null,
          avgCompletionTime: { $avg: '$completionTime' },
          minCompletionTime: { $min: '$completionTime' },
          maxCompletionTime: { $max: '$completionTime' }
        }
      }
    ]);

    // Notification success rate
    const notificationRate = await Order.aggregate([
      {
        $match: {
          restaurantId: req.user._id,
          notificationSent: true,
          ...dateFilter
        }
      },
      {
        $group: {
          _id: null,
          totalNotifications: { $sum: 1 },
          successfulNotifications: {
            $sum: {
              $size: {
                $filter: {
                  input: '$notificationHistory',
                  cond: { $eq: ['$$this.status', 'sent'] }
                }
              }
            }
          }
        }
      }
    ]);

    // Customer satisfaction (based on order completion rate)
    const satisfaction = await Order.aggregate([
      {
        $match: {
          restaurantId: req.user._id,
          ...dateFilter
        }
      },
      {
        $group: {
          _id: null,
          totalOrders: { $sum: 1 },
          completedOrders: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          cancelledOrders: {
            $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] }
          }
        }
      }
    ]);

    res.json({
      period,
      completionTime: completionTime[0] || {
        avgCompletionTime: 0,
        minCompletionTime: 0,
        maxCompletionTime: 0
      },
      notificationRate: notificationRate[0] || {
        totalNotifications: 0,
        successfulNotifications: 0
      },
      satisfaction: satisfaction[0] || {
        totalOrders: 0,
        completedOrders: 0,
        cancelledOrders: 0
      }
    });
  } catch (error) {
    console.error('❌ Get performance metrics error:', error);
    res.status(500).json({
      error: {
        message: 'Failed to fetch performance metrics.'
      }
    });
  }
});

module.exports = router; 