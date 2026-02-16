# FinanceSistent 💰

A beautiful, modern desktop personal finance manager built with Flutter, inspired by [Firefly III](https://github.com/firefly-iii/firefly-iii/).

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features

### Current Features
- 📊 **Beautiful Dashboard** - Modern, gradient-based UI with real-time statistics
- 💳 **Account Management** - Track multiple accounts (asset, expense, revenue, liability)
- 💸 **Transaction Tracking** - Record withdrawals, deposits, and transfers
- 🎨 **Dark Mode Support** - Automatic theme switching based on system preferences
- 💾 **Local Database** - All data stored locally using SQLite (Drift)
- 📱 **Desktop-First Design** - Optimized for desktop with navigation rail

### Planned Features
- 📈 **Budgets** - Set and track spending budgets by category
- 🐷 **Piggy Banks** - Save towards specific goals
- 📊 **Reports & Charts** - Visualize your financial data
- 🏷️ **Categories & Tags** - Organize transactions
- 🔄 **Recurring Transactions** - Automate regular income/expenses
- 📋 **Rules Engine** - Auto-categorize transactions
- 🌍 **Multi-Currency Support** - Track finances in multiple currencies
- 📤 **Import/Export** - CSV and JSON support

## 🚀 Getting Started

### Prerequisites

1. **Install Flutter**
   
   Follow the official Flutter installation guide for your platform:
   - [macOS](https://docs.flutter.dev/get-started/install/macos)
   - [Windows](https://docs.flutter.dev/get-started/install/windows)
   - [Linux](https://docs.flutter.dev/get-started/install/linux)

   Verify installation:
   ```bash
   flutter doctor
   ```

2. **Enable Desktop Support**
   
   ```bash
   # For macOS
   flutter config --enable-macos-desktop
   
   # For Windows
   flutter config --enable-windows-desktop
   
   # For Linux
   flutter config --enable-linux-desktop
   ```

3. **(Optional) Enable AI Features**
   
   To use AI auto-categorization:
   - Install [Ollama](https://ollama.com/)
   - Pull the model: `ollama pull gemma3`
   -  Ensure Ollama is running (`ollama serve`)

### Installation

1. **Clone or navigate to the project**
   ```bash
   cd /Users/petermendis/Documents/anti-gravity/livespotty/financesistent
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (for Freezed, Drift, and Riverpod)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**
   ```bash
   # For macOS
   flutter run -d macos
   
   # For Windows
   flutter run -d windows
   
   # For Linux
   flutter run -d linux
   ```

## 🏗️ Project Structure

```
lib/
├── main.dart                          # App entry point
├── domain/
│   └── models/                        # Domain models
│       ├── account.dart               # Account entity
│       ├── transaction.dart           # Transaction entity
│       ├── category.dart              # Category entity
│       ├── budget.dart                # Budget entity
│       └── piggy_bank.dart            # Piggy bank entity
├── data/
│   ├── database/
│   │   └── database.dart              # Drift database schema
│   └── repositories/                  # Data repositories
│       ├── account_repository.dart
│       └── transaction_repository.dart
├── providers/
│   └── providers.dart                 # Riverpod providers
└── presentation/
    ├── app.dart                       # Main app widget
    ├── theme/
    │   └── app_theme.dart             # App theming
    ├── screens/                       # App screens
    │   ├── home_screen.dart
    │   ├── transactions_screen.dart
    │   ├── accounts_screen.dart
    │   ├── budgets_screen.dart
    │   └── reports_screen.dart
    └── widgets/                       # Reusable widgets
        ├── stat_card.dart
        ├── account_card.dart
        └── transaction_list_item.dart
```

## 🎨 Architecture

This project follows **Clean Architecture** principles with three main layers:

1. **Domain Layer** - Business entities and logic (models)
2. **Data Layer** - Data sources and repositories (database, repositories)
3. **Presentation Layer** - UI components and state management (screens, widgets, providers)

### Key Technologies

- **State Management**: [Riverpod](https://riverpod.dev/) - Type-safe, compile-time dependency injection
- **Database**: [Drift](https://drift.simonbinder.eu/) - Type-safe SQL database for Flutter
- **Immutability**: [Freezed](https://pub.dev/packages/freezed) - Code generation for immutable classes
- **UI Components**: Material 3 with custom theming
- **Charts**: [FL Chart](https://pub.dev/packages/fl_chart) - Beautiful charts (planned)

## 💾 Database Schema

The app uses SQLite with the following tables:

- **Accounts** - Financial accounts (checking, savings, credit cards, etc.)
- **Transactions** - Financial transactions (income, expenses, transfers)
- **Categories** - Transaction categories (hierarchical)
- **Budgets** - Spending budgets with time periods
- **PiggyBanks** - Savings goals

All data is stored locally in `~/Documents/financesistent.sqlite`

## 🎯 Comparison with Firefly III

| Feature | Firefly III | FinanceSistent |
|---------|-------------|----------------|
| Platform | Web (PHP/Laravel) | Desktop (Flutter) |
| Deployment | Self-hosted server | Local application |
| Database | MySQL/PostgreSQL | SQLite |
| Multi-user | ✅ Yes | ❌ No (single-user) |
| Mobile | Via web browser | Planned native apps |
| Offline | ❌ No | ✅ Yes |
| Setup complexity | High | Low |

## 🛠️ Development

### Running in Development Mode

```bash
flutter run -d macos --debug
```

### Building for Production

```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

The built application will be in:
- macOS: `build/macos/Build/Products/Release/`
- Windows: `build/windows/runner/Release/`
- Linux: `build/linux/x64/release/bundle/`

### Code Generation

When you modify models or add new providers, run:

```bash
dart run build_runner watch
```

This will automatically regenerate code when files change.

## 🤝 Contributing

Contributions are welcome! This is a personal project, but feel free to:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgements

- Inspired by [Firefly III](https://github.com/firefly-iii/firefly-iii/)
- Built with [Flutter](https://flutter.dev/)
- Icons from [Font Awesome](https://fontawesome.com/)

## 📧 Contact

For questions or suggestions, please open an issue on GitHub.

---

**Note**: This is a personal finance manager designed for individual use. All data is stored locally on your device and never transmitted to external servers.
