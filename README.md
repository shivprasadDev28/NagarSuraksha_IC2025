Landing page = https://nagarsurakshaindia.netlify.app/
# City Urban Health Monitor (DUHM)

A Flutter app that provides real-time air quality monitoring and crowdsourced urban issue reporting for Delhi.

## Features

- 🌬️ **Real-time Air Quality Monitoring** - Fetches AQI data from WAQI API
- 💧 **Water Issue Reporting** - Crowdsourced water scarcity reporting
- 🏗️ **Urban Development Monitoring** - Report infrastructure issues
- 🗺️ **Interactive Map** - OpenStreetMap integration with issue markers
- 📊 **Analytics Dashboard** - AQI trends and predictions
- 🔐 **User Authentication** - Firebase Authentication
- 📱 **Modern UI** - Clean, responsive design

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Image Storage**: Supabase
- **Maps**: OpenStreetMap (flutter_map)
- **Charts**: fl_chart
- **State Management**: Provider

## Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase account
- Supabase account
- WAQI API token

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
cd mainapp
flutter pub get
```

### 2. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "DUHM"
3. Enable Authentication:
   - Go to Authentication → Sign-in method
   - Enable Email/Password
4. Enable Firestore Database:
   - Go to Firestore Database → Create database
   - Start in test mode
5. Add Android app:
   - Package name: `com.example.duhm`
   - Download `google-services.json` and place it in `android/app/`
6. Add iOS app (if needed):
   - Bundle ID: `com.example.duhm`
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`

### 3. Supabase Setup

1. Go to [Supabase](https://supabase.com/)
2. Create a new project named "DUHM"
3. Note your Project URL and API Key
4. Go to Storage → Create bucket named "issue_images"
5. Set bucket to private

### 4. WAQI API Setup

1. Go to [waqi.info](https://waqi.info)
2. Sign up for a free account
3. Get your API token from the dashboard

### 5. Environment Configuration

Update `lib/utils/environment.dart` with your credentials:

```dart
class Environment {
  // Replace with your actual WAQI API token
  static const String waqiApiToken = 'YOUR_WAQI_API_TOKEN_HERE';
  
  // Replace with your Supabase URL and key
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  // ... rest of the configuration
}
```

### 6. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── air_data_model.dart
│   └── issue_model.dart
├── services/                 # API and data services
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── waqi_service.dart
│   ├── supabase_service.dart
│   └── location_service.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── air_data_provider.dart
│   └── issue_provider.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── main_navigation.dart
│   │   └── home_screen.dart
│   ├── widgets/
│   │   ├── air_quality_card.dart
│   │   ├── water_issues_card.dart
│   │   └── urban_issues_card.dart
│   ├── map_screen.dart
│   ├── analytics_screen.dart
│   └── settings_screen.dart
└── utils/
    └── environment.dart      # Configuration
```

## Firebase Collections

- **Users**: User profiles and authentication data
- **AirData**: Historical air quality data
- **WaterIssues**: Crowdsourced water issue reports
- **UrbanIssues**: Crowdsourced urban development issues

## Development Status

✅ **Completed:**
- Project setup and dependencies
- Data models and services
- Authentication system
- Basic UI screens
- State management with Provider

🚧 **In Progress:**
- Map integration with OpenStreetMap
- Analytics dashboard with charts
- Issue reporting forms
- Image upload functionality

📋 **Planned:**
- Push notifications
- Offline support
- Advanced analytics
- Admin dashboard

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please open an issue in the repository.