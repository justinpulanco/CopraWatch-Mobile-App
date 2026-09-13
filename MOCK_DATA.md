# Mock Data Configuration

## Overview

CopraWatch uses realistic mock data to simulate IoT sensor readings and application state. This allows full feature testing without hardware connectivity.

---

## Mock Data Generation

### Sensor Data Provider (`lib/features/monitor/services/sensor_provider.dart`)

The `SensorNotifier` generates realistic 24-hour sensor data with natural variations:

#### Temperature Data
- **Range**: 30-80°C
- **Base Value**: 60°C (optimal)
- **Pattern**: Sinusoidal variation over 24 hours
- **Noise**: ±1°C random variation
- **Update**: Every 5 seconds with new reading

#### Humidity Data
- **Range**: 5-95%
- **Base Value**: 12% (optimal)
- **Pattern**: Cosine variation over 24 hours
- **Noise**: ±0.5% random variation
- **Update**: Every 5 seconds with new reading

#### Moisture Level
- **Range**: 5-50%
- **Base Value**: 13.5% (starting point)
- **Pattern**: Gradual decrease (-0.15% per hour)
- **Noise**: ±0.5 random variation
- **Target**: 12% (optimal drying point)

#### Solar Irradiance
- **Range**: 0-1200 W/m²
- **Pattern**: Day/night simulation (peak at "noon")
- **Noise**: ±50 random variation
- **Peak**: ~1000 W/m² at "12 hours"

### Chart Data Limit
- Maximum 50 data points stored
- Oldest point removed when new point added
- Provides smooth scrolling and performance

---

## Mock Batch Data

### Current Active Batch (Dashboard)

```
Batch {
  id: "batch_1",
  name: "Batch #2024-01-001",
  startDate: 24 hours ago,
  status: "active",
  initialMoisture: 45.0%,
  finalMoisture: 28.0% (current),
  readings: [Generated sensor readings],
  dryingProgress: ~50%
}
```

### Completed Batches (History)

```
Batch 1:
  name: "Batch #2024-01-001",
  duration: 48 hours,
  initialMoisture: 45.0%,
  finalMoisture: 12.5%,
  qualityResult: "Optimally-Dried",
  confidence: 0.92 (92%)

Batch 2:
  name: "Batch #2024-01-002",
  duration: 48 hours,
  initialMoisture: 48.0%,
  finalMoisture: 13.0%,
  qualityResult: "Optimally-Dried",
  confidence: 0.88 (88%)

Batch 3 (Active):
  name: "Batch #2024-01-003",
  duration: 18 hours (ongoing),
  initialMoisture: 46.0%,
  finalMoisture: 28.0%,
  status: "active"

Batch 4:
  name: "Batch #2024-01-004",
  duration: 48 hours,
  initialMoisture: 42.0%,
  finalMoisture: 11.8%,
  qualityResult: "Optimally-Dried",
  confidence: 0.95 (95%)

Batch 5 (Over-Dried):
  name: "Batch #2024-01-005",
  duration: 48 hours,
  initialMoisture: 50.0%,
  finalMoisture: 9.5%,
  qualityResult: "Over-Dried",
  confidence: 0.83 (83%)
```

---

## Mock Notifications

### Notification Types and Examples

#### Warning Notifications
```
Title: "High Temperature Alert"
Description: "Temperature exceeded 75°C. Check ventilation."
Type: WARNING
Timestamp: 5 hours ago
Status: READ

Title: "Humidity Alert"
Description: "Humidity level above 25%. Reduce moisture input."
Type: WARNING
Timestamp: 1 day ago
Status: READ
```

#### Success Notifications
```
Title: "Batch Complete"
Description: "Batch #2024-01-001 has completed drying"
Type: SUCCESS
Timestamp: 2 hours ago
Status: UNREAD

Title: "Optimal Drying Conditions"
Description: "All sensors are in optimal range for continued drying"
Type: SUCCESS
Timestamp: 15 hours ago
Status: READ

Title: "Moisture Target Reached"
Description: "Target moisture level of 12% has been reached"
Type: SUCCESS
Timestamp: 1 day, 2 hours ago
Status: READ
```

#### Critical Notifications
```
Title: "Critical: Sensor Offline"
Description: "Humidity sensor is not responding. Immediate action required."
Type: CRITICAL
Timestamp: 8 hours ago
Status: READ
```

#### Information Notifications
```
Title: "Quality Check Available"
Description: "Sample is ready for quality classification"
Type: INFORMATION
Timestamp: 12 hours ago
Status: READ

Title: "Maintenance Reminder"
Description: "Solar panel cleaning recommended for optimal efficiency"
Type: INFORMATION
Timestamp: 24 hours ago
Status: READ
```

### Total Mock Notifications: 8
- Unread: 2
- Read: 6

---

## Mock ML Classification Results

### Possible Results

#### Optimally-Dried (Most Common)
- **Confidence**: 88-95%
- **Appearance**: Perfect color, brittle structure
- **Moisture**: 11.5-13.5%
- **Quality Score**: ⭐⭐⭐⭐⭐

#### Under-Dried
- **Confidence**: 75-85%
- **Appearance**: Darker color, slightly soft
- **Moisture**: 14-20%
- **Quality Score**: ⭐⭐⭐⭐

#### Over-Dried
- **Confidence**: 78-88%
- **Appearance**: Very light color, very brittle
- **Moisture**: 8-11%
- **Quality Score**: ⭐⭐⭐

### Classification Distribution (Mock Analytics)
- Optimally-Dried: 75%
- Under-Dried: 17%
- Over-Dried: 8%

---

## Mock Analytics Data

### Summary Statistics
```
Total Batches: 12
Completed: 11
Active: 1

Average Duration: 48.5 hours
Success Rate: 91.7%
Average Moisture: 12.3%
Quality Score: 4.5/5.0
```

### Weekly Trends
```
Week 1: Avg Duration 48h
Week 2: Avg Duration 50h
Week 3: Avg Duration 48h
Week 4: Avg Duration 52h (current)
```

### Performance Metrics
- Consistency: High
- Quality Score: 4.5/5.0
- Energy Efficiency: 92%
- Solar Utilization: 88%

### AI Recommendations
1. **Optimal Temperature**: Current average is 58.5°C which is ideal. Maintain this range.
2. **Humidity Control**: Increase air circulation during 2-4 PM for better results.
3. **Moisture Target**: 12-13% is your sweet spot. Current average: 12.3%

---

## Mock Connection Status

### Default Status
```
Connection: CONNECTED
Device: Raspberry Pi
IP Address: 192.168.1.100
Port: 5000
Status: Online ✓
Last Sync: Just now
```

### Connection States
1. **Connected**: Green indicator, all data flowing
2. **Connecting**: Yellow indicator, attempting connection
3. **Disconnected**: Red indicator, offline mode
4. **Error**: Red indicator with error message

---

## Mock Camera Image

### Scanner Page Simulation
```
Initial State: "Camera Placeholder - Ready for TensorFlow Lite integration"
After Capture: "Image Ready for Classification"
During Classification: Loading spinner (2 seconds)
Result: One of 3 classification results:
  - "Optimally-Dried" (confidence 92%)
  - "Under-Dried" (confidence 78%)
  - "Over-Dried" (confidence 65%)
```

---

## Data Update Intervals

### Real-Time Updates
- **Sensor Readings**: Every 5 seconds
- **Dashboard Refresh**: Every 5 seconds
- **Notifications**: On demand

### Periodic Updates
- **History Refresh**: Every 60 seconds
- **Analytics Recalculation**: Every 60 seconds
- **Database Sync**: On demand

---

## Mock Data Storage

### In-Memory Storage
- Current batch state in `dashboardStateProvider`
- Sensor readings list in `sensorDataProvider`
- Maximum 50 sensor readings for charts

### Persistent Mock Data
- Batch history in mock function
- Notifications in mock function
- Settings in mock function

### Future Database Storage
- All data will be moved to SQLite
- Sync functionality with Raspberry Pi
- Cloud backup capabilities

---

## Testing with Mock Data

### Recommended Test Scenarios

1. **Dashboard Display**
   - Verify all sensor cards show data
   - Check progress bar animation
   - Confirm connection status

2. **Real-Time Monitoring**
   - Monitor chart updates every 5 seconds
   - Verify smooth data transitions
   - Check sensor value changes

3. **History Browsing**
   - Scroll through 5 batches
   - Filter by status
   - View batch details

4. **Quality Classification**
   - Simulate image capture
   - Verify 2-second classification
   - Check result display

5. **Analytics Viewing**
   - Verify pie chart rendering
   - Check bar chart display
   - View recommendations

6. **Notifications**
   - Test all 4 notification types
   - Filter by type
   - Mark as read

---

## Transitioning to Real Data

### Step 1: Replace Sensor Data
Update `sensor_provider.dart` to call `RaspberryPiService.getSensorData()` instead of generating mock data

### Step 2: Replace Batch History
Update dashboard to fetch from `DatabaseService` instead of mock batches

### Step 3: Replace ML Classification
Update scanner to call `MLService.classifyImage()` with real model

### Step 4: Replace Notifications
Update notifications page to fetch from `DatabaseService` instead of mock list

### Step 5: Replace Settings
Update settings to read from `SharedPreferences` instead of mock values

---

## Performance Considerations

### Mock Data Performance
- Chart rendering: Optimized for 50 data points
- Notification list: Efficient ListView rendering
- Memory usage: ~5-10 MB for all mock data
- CPU usage: Minimal (mock data generation uses <1%)

### Optimization Tips
1. Limit chart data points to 50
2. Use pagination for long lists
3. Lazy load analytics data
4. Implement data caching
5. Use worker isolates for heavy processing

---

## Debugging Mock Data

### Enable Debug Logging
```dart
// In sensor_provider.dart
print('New sensor reading: ${newReading}');

// In dashboard_provider.dart
print('Dashboard state updated: $state');
```

### Verify Data Generation
```dart
// Check if data is being generated
final readings = ref.watch(sensorDataProvider).readings;
print('Total readings: ${readings.length}');
```

### Monitor State Changes
```dart
// Watch for state changes
ref.watch(dashboardStateProvider).addListener((previous, next) {
  print('Dashboard state changed');
});
```

---

**Note**: All mock data is generated deterministically but includes realistic variations. The application is fully functional for demonstration and testing with mock data before real hardware integration.
