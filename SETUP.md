# CopraWatch Setup Guide

## Initial Setup

### Step 1: Download Fonts

Create the `assets/fonts/` directory and download Google Fonts Poppins:

```bash
mkdir -p assets/fonts
```

Download these files from [Google Fonts - Poppins](https://fonts.google.com/specimen/Poppins):
- `Poppins-Regular.ttf`
- `Poppins-Bold.ttf`
- `Poppins-SemiBold.ttf`
- `Poppins-Medium.ttf`
- `Poppins-Light.ttf`

Place them in `assets/fonts/` directory.

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Generate Code (if using riverpod_generator)

```bash
flutter pub run build_runner build
```

### Step 4: Run the Application

```bash
flutter run
```

---

## Project Setup Verification

### Check Flutter Installation
```bash
flutter doctor
```

Expected output:
- Flutter SDK ✓
- Android toolchain ✓
- Dart ✓

### Verify Dependencies
```bash
flutter pub outdated
```

All dependencies should have matching versions with pubspec.yaml.

---

## Development Environment Setup

### Android Studio
1. Install Flutter plugin
2. Install Dart plugin
3. Create or open Android emulator

### VS Code
1. Install Flutter extension
2. Install Dart extension
3. Select Flutter SDK path

---

## File Structure Verification

Ensure all these directories exist:

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart ✓
│   ├── theme/
│   │   └── app_theme.dart ✓
│   ├── routes/
│   │   └── app_router.dart ✓
│   └── widgets/
│       ├── sensor_card.dart ✓
│       ├── dashboard_card.dart ✓
│       ├── status_chip.dart ✓
│       ├── custom_progress_bar.dart ✓
│       ├── notification_card.dart ✓
│       ├── custom_app_bar.dart ✓
│       ├── empty_state_widget.dart ✓
│       ├── loading_widget.dart ✓
│       ├── history_card.dart ✓
│       └── custom_bottom_navigation.dart ✓
│
├── features/
│   ├── dashboard/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── dashboard_page.dart ✓
│   │   │   ├── widgets/
│   │   │   │   └── batch_card.dart ✓
│   │   │   └── models/
│   │   │       └── dashboard_state.dart ✓
│   │   └── services/
│   │       └── dashboard_provider.dart ✓
│   │
│   ├── monitor/
│   │   ├── presentation/
│   │   │   └── pages/
│   │   │       └── monitor_page.dart ✓
│   │   └── services/
│   │       └── sensor_provider.dart ✓
│   │
│   ├── scanner/
│   │   └── presentation/
│   │       └── pages/
│   │           └── scanner_page.dart ✓
│   │
│   ├── history/
│   │   └── presentation/
│   │       └── pages/
│   │           └── history_page.dart ✓
│   │
│   ├── analytics/
│   │   └── presentation/
│   │       └── pages/
│   │           └── analytics_page.dart ✓
│   │
│   ├── notifications/
│   │   └── presentation/
│   │       └── pages/
│   │           └── notifications_page.dart ✓
│   │
│   └── settings/
│       └── presentation/
│           └── pages/
│               └── settings_page.dart ✓
│
├── models/
│   ├── batch_model.dart ✓
│   └── notification_model.dart ✓
│
├── services/
│   ├── raspberry_pi_service.dart ✓
│   ├── api_service.dart ✓
│   ├── database_service.dart ✓
│   ├── ml_service.dart ✓
│   └── camera_service.dart ✓
│
└── main.dart ✓
```

---

## Configuration

### pubspec.yaml Verification

Ensure all dependencies are correctly listed:

```yaml
dependencies:
  flutter:
    sdk: flutter
  riverpod: ^2.5.1
  flutter_riverpod: ^2.5.1
  go_router: ^14.0.0
  google_fonts: ^6.1.0
  fl_chart: ^0.68.0
  intl: ^0.19.0
  uuid: ^4.0.0
  connectivity_plus: ^6.0.0
  permission_handler: ^11.4.4
  shared_preferences: ^2.2.3
  camera: ^0.11.0
  sqflite: ^2.3.2
  path: ^1.8.3
  http: ^1.2.0
  image_picker: ^1.1.2
  image: ^4.1.7
  tflite_flutter: ^0.10.1
```

### AppConstants Review

Key constants to verify in `lib/core/constants/app_constants.dart`:

```dart
// Sensor thresholds
static const double optimalTemperature = 60.0;
static const double optimalHumidity = 12.0;
static const double optimalMoisture = 12.0;

// Raspberry Pi defaults
static const String raspberryPiDefaultIP = '192.168.1.100';
static const int raspberryPiDefaultPort = 5000;

// UI constants
static const double defaultPadding = 16.0;
static const double defaultBorderRadius = 12.0;
```

---

## First Run Checklist

- [ ] Flutter environment setup complete
- [ ] All dependencies installed (`flutter pub get`)
- [ ] Font files downloaded and placed in `assets/fonts/`
- [ ] No build errors (`flutter analyze`)
- [ ] App runs successfully (`flutter run`)
- [ ] Dashboard screen displays correctly
- [ ] Bottom navigation works
- [ ] Mock data loads

---

## Testing the Application

### Dashboard Screen
1. Tap notification icon → Notifications page
2. Tap settings icon → Settings page
3. Check connection status indicator
4. Verify sensor cards display mock data
5. Tap "View Analytics" → Analytics page
6. Tap "Scan Copra Quality" → Scanner page

### Monitor Screen
1. Tap Monitor in bottom navigation
2. Verify line charts render
3. Check all sensor cards display data
4. Verify connection status

### Scanner Screen
1. Tap Camera button → Image ready
2. Tap Classify button → Simulates classification
3. Verify result card displays
4. Tap Clear button → Reset UI

### History Screen
1. Verify batch cards display
2. Test filter chips (All, Completed, Active)
3. Tap batch card → Show batch details
4. Test delete functionality

### Analytics Screen
1. Verify pie chart renders
2. Check bar chart displays
3. Verify recommendation cards
4. Check metric rows

### Notifications Screen
1. Verify notifications list
2. Test filter tabs
3. Test mark as read
4. Test notification dismissal

### Settings Screen
1. Test IP address input
2. Test port number input
3. Test connection test button
4. Verify all settings sections display

---

## Common Issues & Solutions

### Issue: Build fails with "flutter/material.dart not found"
**Solution**: Run `flutter pub get` and ensure Flutter SDK is properly set.

### Issue: Fonts not displaying correctly
**Solution**: 
1. Verify font files are in `assets/fonts/`
2. Check pubspec.yaml font configuration
3. Run `flutter pub get`
4. Restart app

### Issue: Charts not rendering
**Solution**: 
1. Verify fl_chart dependency version matches
2. Check that sensor data is being generated
3. Ensure ListView has fixed height for LineChart

### Issue: Navigation not working
**Solution**: 
1. Verify AppRoutes constants match route paths
2. Check GoRouter configuration
3. Ensure all page constructors match route definitions

### Issue: Mock data not updating in real-time
**Solution**: Check sensor_provider.dart timer is initialized in initState

---

## Deployment Preparation

### Before Release Build

1. Update version in pubspec.yaml
2. Update app_constants.dart with production settings
3. Disable debug logging
4. Test on real device
5. Verify all permissions in AndroidManifest.xml and Info.plist

### Android Release

```bash
# Create release APK
flutter build apk --release

# Create App Bundle for Play Store
flutter build appbundle --release
```

### iOS Release

```bash
# Create release build
flutter build ios --release

# Archive for App Store
flutter build ios --release -t ios/Runner/GeneratedPluginRegistrant.m
```

---

## Performance Optimization

### Suggestions for Production
1. Implement image caching for quality predictions
2. Add pagination for history lists
3. Optimize chart data (max 50 points)
4. Implement lazy loading for analytics
5. Use worker isolates for heavy computations

---

## Debugging Tips

### Enable Debug Logging
Add to main.dart:
```dart
// In main() before runApp()
debugPrintBeginFrameBanner = true;
debugPrintEndFrameBanner = true;
```

### Performance Profiling
```bash
flutter run --profile
```

### Memory Analysis
```bash
flutter run --release
# Then use Android Studio/VS Code profiler
```

---

## Next Steps

1. **Raspberry Pi Integration**: Replace mock data with real API calls
2. **TensorFlow Lite Setup**: Add ML model to assets and implement inference
3. **Camera Integration**: Replace camera placeholder with real camera
4. **Database Setup**: Migrate from mock data to SQLite
5. **Notifications**: Implement push notifications
6. **Testing**: Add unit and widget tests
7. **CI/CD**: Set up GitHub Actions for automated builds

---

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Material Design 3](https://m3.material.io)
- [Google Fonts](https://fonts.google.com)
- [fl_chart Documentation](https://www.example.com)

---

**Setup Complete!** ✓

Your CopraWatch application is now ready for development and testing.
