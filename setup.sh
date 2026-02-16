#!/bin/bash

# FinanceSistent Setup Script
# This script will help you set up and run the FinanceSistent application

set -e

echo "🚀 FinanceSistent Setup Script"
echo "================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    echo ""
    echo "Please install Flutter first:"
    echo "  macOS: https://docs.flutter.dev/get-started/install/macos"
    echo "  Windows: https://docs.flutter.dev/get-started/install/windows"
    echo "  Linux: https://docs.flutter.dev/get-started/install/linux"
    echo ""
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Check Flutter doctor
echo "📋 Running Flutter doctor..."
flutter doctor
echo ""

# Enable desktop support based on platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Enabling macOS desktop support..."
    flutter config --enable-macos-desktop
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Enabling Linux desktop support..."
    flutter config --enable-linux-desktop
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "🪟 Enabling Windows desktop support..."
    flutter config --enable-windows-desktop
fi
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo ""

# Run code generation
echo "⚙️  Generating code (Freezed, Drift, Riverpod)..."
dart run build_runner build --delete-conflicting-outputs
echo ""

echo "✨ Setup complete!"
echo ""
echo "To run the application:"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  flutter run -d macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "  flutter run -d linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "  flutter run -d windows"
fi
echo ""
echo "Or simply run: ./run.sh"
echo ""
