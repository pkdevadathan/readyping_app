#!/bin/bash

echo "🍕 Deploying ReadyPingPlus Restaurant App..."

# Build the Flutter web app
echo "📦 Building Flutter web app..."
flutter build web --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "�� Next Steps:"
    echo "1. Go to https://netlify.com/"
    echo "2. Sign up/Login with GitHub"
    echo "3. Click 'New site from Git'"
    echo "4. Choose your GitHub repository"
    echo "5. Set build command: flutter build web --release"
    echo "6. Set publish directory: build/web"
    echo "7. Deploy!"
    echo ""
    echo "🌐 Your app will be available at: https://your-restaurant-app-name.netlify.app"
    echo ""
    echo "🍕 Share this link with restaurant staff!"
else
    echo "❌ Build failed!"
    exit 1
fi
