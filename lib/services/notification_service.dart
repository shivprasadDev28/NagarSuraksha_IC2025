import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../models/air_data_model.dart';
import '../providers/air_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static bool _isMonitoring = false;
  static Position? _lastKnownPosition;
  static List<AirData> _pollutionZones = [];

  // Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _isInitialized = true;
  }

  // Request notification permissions
  static Future<bool> requestPermissions() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    
    // Request location permission
    final locationStatus = await Permission.location.request();
    
    // Request background location permission
    final backgroundLocationStatus = await Permission.locationAlways.request();

    return notificationStatus.isGranted && 
           locationStatus.isGranted && 
           backgroundLocationStatus.isGranted;
  }

  // Start monitoring for pollution zones
  static Future<void> startPollutionMonitoring(BuildContext context) async {
    if (_isMonitoring) return;

    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      print('NotificationService: Permissions not granted');
      return;
    }

    _isMonitoring = true;
    print('NotificationService: Started pollution monitoring');

    // Get current pollution zones from air data provider
    final airDataProvider = Provider.of<AirDataProvider>(context, listen: false);
    _pollutionZones = airDataProvider.indianCitiesData
        .where((data) => data.aqi > 150) // High pollution zones (red circles)
        .toList();

    // Start location monitoring
    _startLocationMonitoring();
  }

  // Stop monitoring
  static Future<void> stopPollutionMonitoring() async {
    _isMonitoring = false;
    print('NotificationService: Stopped pollution monitoring');
  }

  // Start location monitoring
  static void _startLocationMonitoring() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Check every 100 meters
      ),
    ).listen((Position position) {
      _checkPollutionZones(position);
    });
  }

  // Check if user is near pollution zones
  static void _checkPollutionZones(Position currentPosition) {
    if (!_isMonitoring) return;

    for (final pollutionZone in _pollutionZones) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        pollutionZone.latitude,
        pollutionZone.longitude,
      );

      // Alert if within 500 meters of high pollution zone
      if (distance <= 500) {
        _sendPollutionAlert(pollutionZone, distance);
        break; // Only send one alert at a time
      }
    }

    _lastKnownPosition = currentPosition;
  }

  // Send pollution alert notification
  static Future<void> _sendPollutionAlert(AirData pollutionZone, double distance) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pollution_alerts',
      'Pollution Alerts',
      channelDescription: 'Notifications for high pollution areas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF0000), // Red color for pollution alerts
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final aqiLevel = _getAQILevel(pollutionZone.aqi);
    final distanceText = distance < 100 ? 'very close' : 'nearby';

    await _notifications.show(
      pollutionZone.aqi.hashCode, // Unique ID based on AQI
      '⚠️ High Pollution Alert',
      'You are $distanceText a high pollution area (AQI: ${pollutionZone.aqi} - $aqiLevel). Please wear a mask and limit outdoor activities.',
      details,
    );

    print('NotificationService: Sent pollution alert for AQI ${pollutionZone.aqi}');
  }

  // Get AQI level description
  static String _getAQILevel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  // Update pollution zones (call this when air data changes)
  static void updatePollutionZones(List<AirData> airDataList) {
    if (!_isMonitoring) return;

    _pollutionZones = airDataList
        .where((data) => data.aqi > 150) // High pollution zones
        .toList();

    print('NotificationService: Updated pollution zones (${_pollutionZones.length} zones)');
  }

  // Send test notification
  static Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      'Alert!!',
      'Wear Mask and Stay Safe',
      details,
    );
  }

  // Check if monitoring is active
  static bool get isMonitoring => _isMonitoring;

  // Get current pollution zones count
  static int get pollutionZonesCount => _pollutionZones.length;
}

