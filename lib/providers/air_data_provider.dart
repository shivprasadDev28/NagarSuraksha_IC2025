import 'package:flutter/material.dart';
import '../models/air_data_model.dart';
import '../services/waqi_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class AirDataProvider extends ChangeNotifier {
  AirData? _currentAirData;
  List<AirData> _historicalData = [];
  List<AirData> _indianCitiesData = [];
  int? _predictedAQI;
  bool _isLoading = false;
  String? _errorMessage;
  double? _currentLatitude;
  double? _currentLongitude;

  AirData? get currentAirData => _currentAirData;
  List<AirData> get historicalData => _historicalData;
  List<AirData> get indianCitiesData => _indianCitiesData;
  int? get predictedAQI => _predictedAQI;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;

  AirDataProvider() {
    _loadHistoricalData();
    _fetchCurrentLocationAndData();
  }

  Future<void> _fetchCurrentLocationAndData() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        await fetchCurrentLocationAirData(position.latitude, position.longitude);
      }
    } catch (e) {
      print('Failed to get current location: $e');
      // Fallback to Delhi if location fails
      await fetchDelhiAirData();
    }
  }

  Future<void> fetchCurrentLocationAirData(double latitude, double longitude) async {
    _setLoading(true);
    _clearError();

    try {
      AirData? airData = await WAQIService.fetchCurrentLocationAirQuality(latitude, longitude);
      if (airData != null) {
        _currentAirData = airData;
        _currentLatitude = latitude;
        _currentLongitude = longitude;
        
        // Save to Firestore
        await FirestoreService.saveAirData(airData);
        
        // Update historical data
        await _loadHistoricalData();
        
        // Calculate prediction
        await _calculatePrediction();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchIndianCitiesAirData() async {
    _setLoading(true);
    _clearError();

    try {
      _indianCitiesData = await WAQIService.fetchIndianCitiesAirQuality();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchDelhiAirData() async {
    _setLoading(true);
    _clearError();

    try {
      AirData? airData = await WAQIService.fetchDelhiAirQuality();
      if (airData != null) {
        _currentAirData = airData;
        
        // Save to Firestore
        await FirestoreService.saveAirData(airData);
        
        // Update historical data
        await _loadHistoricalData();
        
        // Calculate prediction
        await _calculatePrediction();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadHistoricalData() async {
    try {
      _historicalData = await FirestoreService.getAirData(limit: 30);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> _calculatePrediction() async {
    if (_historicalData.isNotEmpty) {
      try {
        _predictedAQI = await WAQIService.predictNextDayAQI(_historicalData);
        notifyListeners();
      } catch (e) {
        _errorMessage = e.toString();
      }
    }
  }

  String getAQIColor(int aqi) {
    return WAQIService.getAQIColor(aqi);
  }

  String getAQIDescription(int aqi) {
    return WAQIService.getAQIDescription(aqi);
  }

  double? getAQITrend() {
    if (_historicalData.length < 2) return null;
    
    int currentAQI = _historicalData.first.aqi;
    int previousAQI = _historicalData[1].aqi;
    
    return ((currentAQI - previousAQI) / previousAQI) * 100;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}

