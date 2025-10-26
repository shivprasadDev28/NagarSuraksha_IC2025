import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  bool _isMonitoring = false;
  bool _hasPermissions = false;
  int _pollutionZonesCount = 0;

  bool get isMonitoring => _isMonitoring;
  bool get hasPermissions => _hasPermissions;
  int get pollutionZonesCount => _pollutionZonesCount;

  // Initialize notification service
  Future<void> initialize() async {
    await NotificationService.initialize();
    _checkPermissions();
  }

  // Check if we have required permissions
  Future<void> _checkPermissions() async {
    _hasPermissions = await NotificationService.requestPermissions();
    notifyListeners();
  }

  // Start pollution monitoring
  Future<void> startMonitoring(BuildContext context) async {
    if (_isMonitoring) return;

    await NotificationService.startPollutionMonitoring(context);
    _isMonitoring = NotificationService.isMonitoring;
    _pollutionZonesCount = NotificationService.pollutionZonesCount;
    notifyListeners();
  }

  // Stop pollution monitoring
  Future<void> stopMonitoring() async {
    await NotificationService.stopPollutionMonitoring();
    _isMonitoring = false;
    notifyListeners();
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    await NotificationService.sendTestNotification();
  }

  // Update pollution zones
  void updatePollutionZones() {
    _pollutionZonesCount = NotificationService.pollutionZonesCount;
    notifyListeners();
  }
}

