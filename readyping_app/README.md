# ReadyPing 🍕📱

An affordable, plug-and-play, mobile-first notification system that alerts customers via WhatsApp when their food is ready, thereby reducing counter congestion.

## Features

- **OTP-based Authentication** - Secure login for restaurant staff
- **Order Management** - Add, track, and update order status
- **Real-time Status Updates** - One-click status changes with visual feedback
- **WhatsApp Integration** - Automatic notifications when orders are ready
- **Mobile-First Design** - Optimized for smartphones and tablets
- **Progressive Web App (PWA)** - No installation required, works offline
- **QR Code Generation** - Easy customer opt-in for notifications
- **Order History** - Track completed orders and basic analytics

## Design Principles

- **Minimal Learning Curve** - Simple, intuitive UI for quick adoption
- **Fast Interactions** - One-click status updates, real-time feedback
- **Mobile-First** - Optimized for smartphones and tablets
- **No Installation** - Runs as a Progressive Web App

## Tech Stack

- **Frontend**: Flutter Web
- **State Management**: Provider
- **Styling**: Material Design 3
- **Storage**: Local Storage (SharedPreferences)
- **QR Code**: qr_flutter
- **PWA**: Progressive Web App capabilities

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Web browser (Chrome recommended)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd readyping_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run -d chrome
   ```

4. **Build for production**
   ```bash
   flutter build web
   ```

## Usage

### Demo Mode

The app includes a demo mode for testing:

1. **Login**: Use any phone number and the demo OTP `123456`
2. **Demo Data**: The app automatically generates sample orders
3. **Test Features**: Try adding orders, updating status, and viewing notifications

### Adding Orders

1. Click the "Add Order" button
2. Fill in:
   - Order ID (e.g., ORD001)
   - Customer Name
   - Phone Number
3. Click "Add Order"

### Managing Orders

- **Pending Orders**: Mark as "Ready" to send WhatsApp notification
- **Ready Orders**: Mark as "Completed" to move to history
- **Delete Orders**: Remove orders from the system

### QR Code Feature

- Click the QR code icon in the app bar
- Customers can scan the QR code to opt-in for notifications
- In production, this would link to your restaurant's opt-in page

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── order.dart           # Order data model
├── providers/
│   ├── auth_provider.dart   # Authentication state management
│   └── order_provider.dart  # Order state management
├── screens/
│   ├── login_screen.dart    # OTP-based login
│   └── dashboard_screen.dart # Main dashboard
├── widgets/
│   ├── order_card.dart      # Order display component
│   ├── add_order_dialog.dart # Add order form
│   └── qr_code_dialog.dart  # QR code generator
└── theme/
    └── app_theme.dart       # App styling and colors
```

## Configuration

### WhatsApp Integration

The current version simulates WhatsApp notifications. To integrate with real WhatsApp Business API:

1. Set up WhatsApp Business API account
2. Update the `_sendWhatsAppNotification` method in `order_provider.dart`
3. Add your API credentials and endpoint

### Backend Integration

To connect to a real backend:

1. Update API endpoints in providers
2. Add proper error handling
3. Implement real-time updates (WebSocket/Firebase)

## Deployment

### Web Deployment

1. **Build the app**
   ```bash
   flutter build web --release
   ```

2. **Deploy to hosting service**
   - Firebase Hosting
   - Netlify
   - Vercel
   - Any static hosting service

### PWA Features

The app is configured as a Progressive Web App with:
- Offline support
- Install prompt
- App-like experience
- Push notifications (can be extended)

## Customization

### Branding

Update colors and branding in `lib/theme/app_theme.dart`:
- Primary color
- Secondary color
- Accent color
- Logo and icons

### Features

Add new features by:
1. Creating new models in `lib/models/`
2. Adding providers in `lib/providers/`
3. Creating screens in `lib/screens/`
4. Building widgets in `lib/widgets/`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

---

**ReadyPing** - Making food service smarter, one notification at a time! 🚀
