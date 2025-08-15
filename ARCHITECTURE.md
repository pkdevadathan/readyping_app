# ReadyPing System Architecture Documentation

## 📋 Table of Contents
1. [System Overview](#system-overview)
2. [Frontend Architecture](#frontend-architecture)
3. [Backend Architecture](#backend-architecture)
4. [Data Flow](#data-flow)
5. [Technology Stack](#technology-stack)
6. [File Structure](#file-structure)
7. [API Endpoints](#api-endpoints)
8. [State Management](#state-management)
9. [Demo Mode](#demo-mode)
10. [Deployment](#deployment)

---

## 🏗️ System Overview

ReadyPing is a comprehensive food service notification system consisting of two main applications:

### **ReadyPing (Customer App)**
- **Purpose**: Customer-facing mobile app for ordering food and getting notified when food is ready
- **Features**: QR scanning, restaurant search, menu browsing, order placement, order tracking
- **Port**: 8081 (Flutter Web)

### **ReadyPingPlus (Restaurant App)**
- **Purpose**: Restaurant counter app for managing orders
- **Features**: Order management, status updates, WhatsApp notifications, QR generation
- **Port**: 8082 (Flutter Web)

### **Backend API Server**
- **Purpose**: Central API server handling all business logic
- **Features**: Authentication, order management, WhatsApp integration
- **Port**: 3000 (Node.js/Express)

---

## 📱 Frontend Architecture

### **Technology Stack**
- **Framework**: Flutter Web
- **Language**: Dart
- **State Management**: Provider Pattern
- **UI Framework**: Material Design 3
- **HTTP Client**: Dio/HTTP package
- **Local Storage**: SharedPreferences

### **Architecture Pattern**
Both apps follow the **Provider Pattern** with a clean separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UI Layer      │    │  Provider Layer │    │  Service Layer  │
│   (Screens)     │◄──►│   (State Mgmt)  │◄──►│   (API Calls)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Key Components**

#### **1. Screens (UI Layer)**
- **SplashScreen**: App initialization and routing
- **LoginScreen**: Authentication interface
- **HomeScreen**: Main dashboard with navigation
- **RestaurantSearchScreen**: Restaurant discovery
- **QRScanScreen**: QR code scanning
- **RestaurantMenuScreen**: Menu browsing and ordering
- **OrdersScreen**: Order history and tracking
- **ProfileScreen**: User profile management
- **OrderDetailsScreen**: Detailed order view

#### **2. Providers (State Management)**
- **AuthProvider**: Authentication state and user data
- **OrderProvider**: Order management and tracking
- **RestaurantProvider**: Restaurant and menu data

#### **3. Services (API Layer)**
- **ApiService**: HTTP communication with backend
- **WhatsAppService**: Notification handling (backend)

#### **4. Models (Data Layer)**
- **Order**: Order data structure
- **Restaurant**: Restaurant information
- **MenuItem**: Menu item details
- **User**: User profile data

---

## 🔧 Backend Architecture

### **Technology Stack**
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB (with demo mode fallback)
- **Authentication**: JWT (JSON Web Tokens)
- **WhatsApp**: Twilio Business API
- **Real-time**: Socket.IO (planned)

### **Architecture Pattern**
The backend follows a **Layered Architecture**:

```
┌─────────────────┐
│   Routes Layer  │  ← API endpoints and request handling
├─────────────────┤
│ Controller Layer│  ← Business logic and request processing
├─────────────────┤
│  Service Layer  │  ← External service integration
├─────────────────┤
│   Model Layer   │  ← Data models and database operations
├─────────────────┤
│ Middleware Layer│  ← Authentication, validation, logging
└─────────────────┘
```

### **Key Components**

#### **1. Routes (API Endpoints)**
- **auth.js**: Authentication endpoints (login, register, OTP)
- **orders.js**: Order management (CRUD operations)
- **qr.js**: QR code generation and management
- **analytics.js**: Analytics and reporting

#### **2. Controllers (Business Logic)**
- **AuthController**: User authentication logic
- **OrderController**: Order processing and management
- **QRController**: QR code generation logic

#### **3. Services (External Integration)**
- **WhatsAppService**: Twilio WhatsApp Business API integration
- **EmailService**: Email notifications (planned)
- **PaymentService**: Payment processing (planned)

#### **4. Models (Data Layer)**
- **User**: User and restaurant data
- **Order**: Order information
- **QRCode**: QR code data

#### **5. Middleware**
- **auth.js**: JWT token validation
- **validation.js**: Request validation
- **errorHandler.js**: Error handling and logging

---

## 🔄 Data Flow

### **Order Placement Flow**
```
1. Customer App (ReadyPing)
   ├── Scan QR / Search Restaurant
   ├── Browse Menu
   ├── Add Items to Cart
   ├── Place Order
   └── Send to Backend API

2. Backend API
   ├── Validate Order
   ├── Store in Database
   ├── Send to Restaurant App
   └── Return Confirmation

3. Restaurant App (ReadyPingPlus)
   ├── Receive New Order
   ├── Display in Active Orders
   ├── Update Status (Ready)
   ├── Send WhatsApp Notification
   └── Mark as Completed
```

### **Authentication Flow**
```
1. User Login
   ├── Enter Credentials
   ├── Send to Backend
   ├── Validate Credentials
   ├── Generate JWT Token
   └── Return Token

2. API Requests
   ├── Include JWT Token
   ├── Validate Token (Middleware)
   ├── Process Request
   └── Return Response
```

---

## 🛠️ Technology Stack

### **Frontend (Flutter)**
```yaml
dependencies:
  flutter: ^3.16.0
  provider: ^6.1.1
  http: ^1.1.0
  shared_preferences: ^2.2.2
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1
  url_launcher: ^6.2.1
  image_picker: ^1.0.4
  permission_handler: ^11.0.1
```

### **Backend (Node.js)**
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^8.0.3",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "twilio": "^4.19.0",
    "socket.io": "^4.7.4",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1"
  }
}
```

---

## 📁 File Structure

```
readyping/
├── readyping_customer/           # Customer App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   │   ├── customer_order.dart
│   │   │   ├── menu_item.dart
│   │   │   └── restaurant.dart
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   ├── order_provider.dart
│   │   │   └── restaurant_provider.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── restaurant_search_screen.dart
│   │   │   ├── qr_scan_screen.dart
│   │   │   ├── restaurant_menu_screen.dart
│   │   │   ├── orders_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── order_details_screen.dart
│   │   ├── services/
│   │   │   └── api_service.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   └── pubspec.yaml
│
├── readyping_app/                # Restaurant App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   │   └── order.dart
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   └── order_provider.dart
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── dashboard_screen.dart
│   │   ├── widgets/
│   │   │   ├── order_card.dart
│   │   │   ├── add_order_dialog.dart
│   │   │   └── qr_code_dialog.dart
│   │   ├── services/
│   │   │   └── api_service.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   └── pubspec.yaml
│
└── readyping_backend/            # Backend API
    ├── src/
    │   ├── server.js
    │   ├── controllers/
    │   ├── middleware/
    │   │   └── auth.js
    │   ├── models/
    │   │   ├── User.js
    │   │   ├── Order.js
    │   │   └── QRCode.js
    │   ├── routes/
    │   │   ├── auth.js
    │   │   ├── orders.js
    │   │   ├── qr.js
    │   │   └── analytics.js
    │   └── services/
    │       └── whatsappService.js
    ├── package.json
    └── .env.example
```

---

## 🔌 API Endpoints

### **Authentication**
```
POST /api/auth/login              # User login
POST /api/auth/register           # User registration
POST /api/auth/send-otp          # Send OTP (legacy)
POST /api/auth/verify-otp        # Verify OTP (legacy)
GET  /api/auth/profile           # Get user profile
PUT  /api/auth/profile           # Update user profile
POST /api/auth/logout            # User logout
```

### **Orders**
```
GET    /api/orders               # Get all orders
POST   /api/orders               # Create new order
GET    /api/orders/:id           # Get specific order
PUT    /api/orders/:id           # Update order
DELETE /api/orders/:id           # Delete order
PUT    /api/orders/:id/status    # Update order status
GET    /api/orders/stats/overview # Get order statistics
```

### **QR Codes**
```
GET  /api/qr/:code              # Get QR code data
POST /api/qr/generate           # Generate new QR code
GET  /api/qr/:code/image        # Get QR code image
```

### **Analytics**
```
GET /api/analytics/orders       # Order analytics
GET /api/analytics/revenue      # Revenue analytics
GET /api/analytics/customers    # Customer analytics
```

---

## 🎯 State Management

### **Provider Pattern Implementation**

#### **AuthProvider**
```dart
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _phoneNumber;
  String? _restaurantName;
  
  // Methods
  Future<bool> loginWithCredentials(String phone, String password);
  Future<void> logout();
  Future<void> initialize();
}
```

#### **OrderProvider**
```dart
class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  
  // Methods
  Future<void> loadOrders();
  Future<bool> createOrder(Map<String, dynamic> orderData);
  Future<bool> updateOrderStatus(String orderId, OrderStatus status);
  Future<bool> deleteOrder(String orderId);
}
```

#### **RestaurantProvider**
```dart
class RestaurantProvider with ChangeNotifier {
  List<Restaurant> _restaurants = [];
  Restaurant? _selectedRestaurant;
  
  // Methods
  Future<void> searchRestaurants(String query);
  Future<Restaurant?> getRestaurantByQR(String qrCode);
  Future<void> loadMenu(String restaurantId);
}
```

---

## 🎭 Demo Mode

### **Purpose**
Demo mode allows both frontend and backend to function without external dependencies (database, WhatsApp API, etc.).

### **Implementation**

#### **Frontend Demo Mode**
- **AuthProvider**: Accepts any valid credentials
- **OrderProvider**: Uses local demo data when API fails
- **RestaurantProvider**: Generates demo restaurant and menu data

#### **Backend Demo Mode**
- **Authentication**: Creates demo users and tokens in memory
- **Orders**: Uses in-memory storage instead of MongoDB
- **WhatsApp**: Logs messages to console instead of sending

### **Demo Data**
```javascript
// Sample demo orders
const demoOrders = [
  {
    id: '1',
    orderId: 'ORD001',
    customerName: 'Rahul Sharma',
    phoneNumber: '+919876543210',
    status: 'pending',
    items: [
      { name: 'Dal Khichdi', quantity: 2, price: 120.0 },
      { name: 'Curd Rice', quantity: 1, price: 80.0 }
    ],
    totalAmount: 320.0
  }
];
```

---

## 🚀 Deployment

### **Frontend Deployment**
```bash
# Build Flutter Web apps
cd readyping_customer
flutter build web

cd ../readyping_app
flutter build web

# Deploy to hosting service (Firebase, Netlify, etc.)
```

### **Backend Deployment**
```bash
# Install dependencies
cd readyping_backend
npm install

# Set environment variables
cp .env.example .env
# Edit .env with production values

# Start production server
npm start
```

### **Environment Variables**
```env
# Backend (.env)
PORT=3000
MONGODB_URI=mongodb://localhost:27017/readyping
JWT_SECRET=your_jwt_secret
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
TWILIO_PHONE_NUMBER=your_twilio_phone
```

---

## 🔮 Future Enhancements

### **Planned Features**
- **Real-time Updates**: Socket.IO integration
- **Push Notifications**: Firebase Cloud Messaging
- **Payment Integration**: UPI, Razorpay
- **Analytics Dashboard**: Advanced reporting
- **Multi-language Support**: Internationalization
- **Offline Mode**: Service worker implementation

### **Scalability Considerations**
- **Database**: MongoDB Atlas for cloud hosting
- **Caching**: Redis for session management
- **Load Balancing**: Multiple server instances
- **CDN**: Static asset delivery optimization
- **Monitoring**: Application performance monitoring

---

## 📞 Support

For technical support or questions about the architecture:
- **Documentation**: This file and inline code comments
- **Demo Mode**: Use for testing without external dependencies
- **Error Handling**: Comprehensive error logging and user feedback

---

*Last Updated: December 2024*
*Version: 1.0.0* 