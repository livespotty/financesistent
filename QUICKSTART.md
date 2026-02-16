# Quick Start Guide

## Prerequisites

Before you begin, you need to install Flutter on your system.

### Installing Flutter

#### macOS
```bash
# Install using Homebrew (recommended)
brew install --cask flutter

# Or download from official site
# Visit: https://docs.flutter.dev/get-started/install/macos
```

#### Windows
1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add `C:\src\flutter\bin` to your PATH

#### Linux
```bash
# Download Flutter
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$PATH:$HOME/development/flutter/bin"
```

### Verify Flutter Installation

```bash
flutter doctor
```

This command checks your environment and displays a report. Follow any instructions to install missing dependencies.

## Setup FinanceSistent

### Option 1: Automated Setup (Recommended)

```bash
cd /Users/petermendis/Documents/anti-gravity/livespotty/financesistent
./setup.sh
```

This script will:
- ✅ Check Flutter installation
- ✅ Enable desktop support for your platform
- ✅ Install all dependencies
- ✅ Generate required code files

### Option 2: Manual Setup

```bash
# 1. Navigate to project directory
cd /Users/petermendis/Documents/anti-gravity/livespotty/financesistent

# 2. Enable desktop support (macOS example)
flutter config --enable-macos-desktop

# 3. Install dependencies
flutter pub get

# 4. Generate code
dart run build_runner build --delete-conflicting-outputs
```

### Enable AI Features (Optional)
To use auto-categorization powered by AI:
1. Install [Ollama](https://ollama.com/)
2. Run `ollama pull gemma3`
3. Start the server: `ollama serve`

## Running the Application

### Quick Run
```bash
./run.sh
```

### Manual Run
```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

## First Time Setup

When you first run the application:

1. **Create an Account**
   - Click "Add Account" on the dashboard
   - Choose account type (Asset, Expense, Revenue, or Liability)
   - Enter account details

2. **Add Your First Transaction**
   - Click the "+" button
   - Select transaction type (Withdrawal, Deposit, or Transfer)
   - Fill in the details

3. **Explore Features**
   - View your dashboard for financial overview
   - Check transactions history
   - Set up budgets (coming soon)
   - Generate reports (coming soon)

## Troubleshooting

### "Flutter not found"
- Make sure Flutter is installed and added to your PATH
- Run `flutter doctor` to verify installation

### "No devices found"
- Enable desktop support: `flutter config --enable-macos-desktop`
- Restart your terminal

### Code generation errors
- Delete generated files: `find . -name "*.g.dart" -delete`
- Run build_runner again: `dart run build_runner build --delete-conflicting-outputs`

### Database errors
- Delete the database file: `rm ~/Documents/financesistent.sqlite`
- Restart the application

## Development Mode

For development with hot reload:
```bash
flutter run -d macos --debug
```

## Building for Production

```bash
# macOS
flutter build macos --release

# The app will be in: build/macos/Build/Products/Release/FinanceSistent.app
```

## Need Help?

- Check the main [README.md](README.md) for detailed documentation
- Review Flutter documentation: https://docs.flutter.dev/
- Open an issue on GitHub

---

**Happy tracking! 💰**
