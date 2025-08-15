# ReadyPing - Restaurant Ordering System

A complete restaurant ordering system with real-time notifications, QR code scanning, and WhatsApp integration.

## 🏗️ System Architecture

ReadyPing consists of three main components:

- **Customer App** (Flutter) - Mobile app for customers to place orders
- **Restaurant App** (Flutter) - Mobile app for restaurants to manage orders
- **Backend API** (Node.js/Express) - Server with MongoDB database and WhatsApp integration

## 📋 Prerequisites

Before running the system, make sure you have:

- **Flutter SDK** (3.0 or higher)
- **Node.js** (16 or higher)
- **MongoDB** (local or cloud instance)
- **Twilio Account** (for WhatsApp notifications)
- **Git**

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/pkdevadathan/readyping_app.git
cd readyping_app
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd readyping_backend

# Install dependencies
npm install

# Copy environment file
cp env.example .env

# Edit .env file with your configuration
# See Configuration section below

# Start the server
npm start
```

The backend will run on `http://localhost:3000`

### 3. Customer App Setup

```bash
# Navigate to customer app directory
cd readyping_customer

# Get Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### 4. Restaurant App Setup

```bash
# Navigate to restaurant app directory
cd readyping_app

# Get Flutter dependencies
flutter pub get

# Run the app
flutter run
```

## ⚙️ Configuration

### Backend Environment Variables

**⚠️ Security Note:** The examples below are placeholders. Never commit real credentials to version control. Use environment variables or secure secret management systems.

Create a `.env` file in `readyping_backend/` with:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# MongoDB Connection
MONGODB_URI=mongodb://localhost:27017/readyping
# For MongoDB Atlas: Replace with your connection string from Atlas dashboard

# JWT Secret
JWT_SECRET=your_jwt_secret_key_here

# Twilio Configuration (for WhatsApp notifications)
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=whatsapp:+1234567890

# Optional: Email service (for future implementation)
EMAIL_SERVICE=gmail
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
```

### App Configuration

Update the API base URL in both Flutter apps:

**Customer App** (`readyping_customer/lib/services/api_service.dart`):
```dart
static const String baseUrl = 'http://localhost:3000/api';
// Change to your backend URL when deploying
```

**Restaurant App** (`readyping_app/lib/services/api_service.dart`):
```dart
static const String baseUrl = 'http://localhost:3000/api';
// Change to your backend URL when deploying
```

## 📱 Running the Apps

### Customer App Features
- QR code scanning to find restaurants
- Browse restaurant menus
- Place orders with real-time tracking
- Receive WhatsApp notifications when food is ready

### Restaurant App Features
- View incoming orders in real-time
- Update order status (preparing, ready, completed)
- Generate QR codes for customers
- Send WhatsApp notifications to customers

## 🗄️ Database Setup

### MongoDB Setup

#### Option 1: Local MongoDB
1. Install MongoDB locally
2. Start MongoDB service
3. Create a database named `readyping`
4. Use connection string: `mongodb://localhost:27017/readyping`

#### Option 2: MongoDB Atlas (Cloud)
1. Create a free account at [MongoDB Atlas](https://www.mongodb.com/atlas)
2. Create a new cluster
3. Create a database user with read/write permissions
4. Get your connection string from the "Connect" button
5. Replace the placeholder in `.env` with your actual connection string

**Note:** The collections will be created automatically when you first use the app

### Sample Data

You can add sample restaurants and menu items through the API:

```bash
# Add a sample restaurant
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+1234567890",
    "password": "restaurant123",
    "restaurantName": "Sample Restaurant",
    "userType": "restaurant"
  }'
```

## 🔧 Development

### Project Structure

```
readyping_app/
├── readyping_backend/          # Node.js/Express API server
│   ├── src/
│   │   ├── controllers/        # Business logic
│   │   ├── middleware/         # Authentication & validation
│   │   ├── models/            # MongoDB schemas
│   │   ├── routes/            # API endpoints
│   │   └── services/          # External services (WhatsApp)
│   └── package.json
├── readyping_customer/         # Customer Flutter app
│   ├── lib/
│   │   ├── models/            # Data models
│   │   ├── providers/         # State management
│   │   ├── screens/           # UI screens
│   │   ├── services/          # API communication
│   │   └── widgets/           # Reusable components
│   └── pubspec.yaml
├── readyping_app/             # Restaurant Flutter app
│   ├── lib/
│   │   ├── models/            # Data models
│   │   ├── providers/         # State management
│   │   ├── screens/           # UI screens
│   │   ├── services/          # API communication
│   │   └── widgets/           # Reusable components
│   └── pubspec.yaml
└── docs/                      # Documentation
    ├── SYSTEM_DIAGRAMS.md     # Architecture diagrams
    ├── ARCHITECTURE.md        # System overview
    └── PROPOSED_SYSTEM.md     # Design proposal
```

### API Endpoints

#### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/auth/profile` - Get user profile

#### Orders
- `GET /api/orders` - Get all orders
- `POST /api/orders` - Create new order
- `PUT /api/orders/:id` - Update order
- `PUT /api/orders/:id/status` - Update order status

#### QR Codes
- `GET /api/qr/:code` - Get QR code data
- `POST /api/qr/generate` - Generate new QR code

## 🚀 Deployment

### Backend Deployment

1. **Heroku**:
   ```bash
   cd readyping_backend
   heroku create your-app-name
   heroku config:set MONGODB_URI=your_mongodb_atlas_uri
   heroku config:set JWT_SECRET=your_jwt_secret
   git push heroku main
   ```

2. **Railway**:
   - Connect your GitHub repository
   - Set environment variables
   - Deploy automatically

### App Deployment

1. **Customer App**:
   ```bash
   cd readyping_customer
   flutter build apk --release
   # or flutter build ios --release
   ```

2. **Restaurant App**:
   ```bash
   cd readyping_app
   flutter build apk --release
   # or flutter build ios --release
   ```

## 🔐 Security Features

- JWT-based authentication
- Password hashing with bcrypt
- Input validation and sanitization
- CORS configuration
- Rate limiting (can be added)

## 📞 WhatsApp Integration

The system uses Twilio's WhatsApp Business API to send notifications:

1. Set up a Twilio account
2. Configure WhatsApp Sandbox
3. Add your Twilio credentials to `.env`
4. Test with the sandbox number

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

1. **MongoDB Connection Error**:
   - Check if MongoDB is running
   - Verify connection string in `.env`

2. **Flutter Dependencies**:
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Port Already in Use**:
   - Change PORT in `.env` file
   - Kill process using the port

4. **WhatsApp Notifications Not Working**:
   - Verify Twilio credentials
   - Check WhatsApp sandbox setup
   - Ensure phone numbers are in correct format

### Getting Help

- Check the [SYSTEM_DIAGRAMS.md](SYSTEM_DIAGRAMS.md) for architecture details
- Review the [ARCHITECTURE.md](ARCHITECTURE.md) for system overview
- Open an issue on GitHub for bugs or feature requests

## 🎯 Features Roadmap

- [ ] Payment integration (Stripe/PayPal)
- [ ] Email notifications
- [ ] Push notifications
- [ ] Multi-language support
- [ ] Analytics dashboard
- [ ] Inventory management
- [ ] Staff management
- [ ] Customer reviews and ratings

---

**ReadyPing** - Making restaurant ordering seamless and efficient! 🍕📱 