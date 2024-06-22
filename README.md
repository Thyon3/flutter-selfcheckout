# ScanGo - Self-Checkout Mobile Application

A comprehensive Flutter application for self-service shopping with barcode scanning, cart management, and secure payment processing.

## Features

- **User Authentication**: Secure login and registration with biometric support
- **Barcode Scanning**: Fast product scanning with real-time lookup
- **Shopping Cart**: Intuitive cart management with real-time calculations
- **Payment Integration**: Multiple payment methods with Stripe integration
- **Shopping Lists**: Create and manage shopping lists
- **Order History**: View and export purchase history
- **Multi-language Support**: English and Sinhala language options
- **Dark Mode**: Toggle between light and dark themes
- **Offline Support**: Basic functionality without internet connection
- **Analytics**: Comprehensive user behavior tracking

## Getting Started

### Prerequisites

- Flutter SDK (>= 2.5.0)
- Dart SDK (>= 2.14.0)
- Android Studio / VS Code with Flutter extension
- Firebase project configuration

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd flutter_selfcheckout
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a new Firebase project
   - Add Android and iOS apps
   - Download configuration files
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── screens/           # UI screens
├── widgets/           # Reusable UI components
├── services/          # Business logic and API services
├── models/            # Data models
├── utils/             # Utility functions
└── constants/         # App constants and configuration
```

## Key Technologies

- **Flutter**: Cross-platform mobile development
- **Firebase**: Authentication, database, and analytics
- **Stripe**: Payment processing
- **Local Auth**: Biometric authentication
- **Google Fonts**: Typography
- **Shared Preferences**: Local storage
- **Connectivity Plus**: Network status monitoring

## Architecture

The app follows a clean architecture pattern with:
- **Presentation Layer**: Screens and widgets
- **Business Logic Layer**: Services and utilities
- **Data Layer**: Models and repositories

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please contact the development team.
