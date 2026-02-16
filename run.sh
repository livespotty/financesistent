#!/bin/bash

# FinanceSistent Run Script
# Quick script to run the application

set -e

# Detect platform and run
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🚀 Running FinanceSistent on macOS..."
    flutter run -d macos
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🚀 Running FinanceSistent on Linux..."
    flutter run -d linux
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "🚀 Running FinanceSistent on Windows..."
    flutter run -d windows
else
    echo "❌ Unsupported platform: $OSTYPE"
    exit 1
fi
