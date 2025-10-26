import 'package:flutter/material.dart';
import '../models/air_data_model.dart';
import '../models/air_quality_prediction_model.dart';
import '../services/air_quality_prediction_service.dart';
import '../services/waqi_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  List<AirQualityDataPoint> _historicalData = [];
  AirQualityPrediction? _prediction;
  bool _isLoading = false;
  String? _errorMessage;
  double? _currentLatitude;
  double? _currentLongitude;

  List<AirQualityDataPoint> get historicalData => _historicalData;
  AirQualityPrediction? get prediction => _prediction;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;

  Future<void> loadAnalyticsData() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Load current location air quality data
      final currentAirData = await WAQIService.fetchDelhiAirQuality();
      
      // Generate historical data (in real app, this would come from API)
      _historicalData = AirQualityPredictionService.generateHistoricalData();
      
      // Add current data to historical data
      if (currentAirData != null) {
        _historicalData.add(AirQualityDataPoint.fromAirData(currentAirData));
      }
      
      // Generate prediction
      _prediction = AirQualityPredictionService.predictNextDay(_historicalData);
      
    } catch (e) {
      _errorMessage = 'Failed to load analytics data: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAnalyticsDataForLocation(double latitude, double longitude) async {
    _setLoading(true);
    _errorMessage = null;
    _currentLatitude = latitude;
    _currentLongitude = longitude;

    try {
      // Load current location air quality data
      final currentAirData = await WAQIService.fetchCurrentLocationAirQuality(latitude, longitude);
      
      // Generate historical data based on current location
      _historicalData = _generateLocationBasedHistoricalData(currentAirData);
      
      // Generate prediction based on current location data
      _prediction = _generateLocationBasedPrediction(currentAirData);
      
    } catch (e) {
      _errorMessage = 'Failed to load analytics data: $e';
    } finally {
      _setLoading(false);
    }
  }

  List<AirQualityDataPoint> _generateLocationBasedHistoricalData(AirData? currentData) {
    List<AirQualityDataPoint> historicalData = [];
    final baseAqi = currentData?.aqi ?? 100;
    
    // Generate 7 days of historical data with realistic variations
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      
      // Create realistic AQI variations based on current location
      final variation = (i == 0) ? 0 : (baseAqi * 0.1 * (i / 6)); // Less variation for recent days
      final randomFactor = (date.day % 3) - 1; // Small daily variation
      final aqi = (baseAqi + variation + randomFactor * 5).round().clamp(50, 300);
      
      historicalData.add(AirQualityDataPoint(
        timestamp: date,
        aqi: aqi,
        pm25: (aqi * 0.8 + (date.day % 10)).toDouble(),
        pm10: (aqi * 1.2 + (date.day % 15)).toDouble(),
        o3: (aqi * 0.6 + (date.day % 8)).toDouble(),
        no2: (aqi * 0.7 + (date.day % 12)).toDouble(),
        so2: (aqi * 0.5 + (date.day % 6)).toDouble(),
        co: (aqi * 0.3 + (date.day % 4)).toDouble(),
      ));
    }
    
    return historicalData;
  }

  AirQualityPrediction _generateLocationBasedPrediction(AirData? currentData) {
    final baseAqi = currentData?.aqi ?? 100;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    
    // Generate realistic prediction based on current location data
    final trendFactor = _calculateTrendFactor();
    final weatherFactor = (tomorrow.day % 3) - 1; // Simulate weather impact
    final predictedAqi = (baseAqi + trendFactor + weatherFactor * 8).round().clamp(50, 300);
    
    final confidence = 0.75 + (currentData != null ? 0.15 : 0.0); // Higher confidence with real data
    
    return AirQualityPrediction(
      date: tomorrow,
      predictedAqi: predictedAqi,
      confidence: confidence,
      predictionMethod: 'location_based_ml',
      predictedPollutants: {
        'PM2.5': (predictedAqi * 0.8).toDouble(),
        'PM10': (predictedAqi * 1.2).toDouble(),
        'O3': (predictedAqi * 0.6).toDouble(),
        'NO2': (predictedAqi * 0.7).toDouble(),
        'SO2': (predictedAqi * 0.5).toDouble(),
        'CO': (predictedAqi * 0.3).toDouble(),
      },
    );
  }

  double _calculateTrendFactor() {
    if (_historicalData.length < 2) return 0;
    
    final recent = _historicalData.take(3).toList();
    final trend = (recent.first.aqi - recent.last.aqi) / recent.length;
    return trend * 0.5; // Apply 50% of trend to prediction
  }

  Future<void> refreshData() async {
    if (_currentLatitude != null && _currentLongitude != null) {
      await loadAnalyticsDataForLocation(_currentLatitude!, _currentLongitude!);
    } else {
      await loadAnalyticsData();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get data points for chart (last 7 days)
  List<AirQualityDataPoint> getChartData() {
    if (_historicalData.length <= 7) {
      return _historicalData;
    }
    return _historicalData.sublist(_historicalData.length - 7);
  }

  // Get AQI trend (increasing, decreasing, stable)
  String getAqiTrend() {
    if (_historicalData.length < 2) return 'stable';
    
    final recent = _historicalData.length >= 3 
        ? _historicalData.sublist(_historicalData.length - 3)
        : _historicalData;
    if (recent.length < 2) return 'stable';
    
    final first = recent.first.aqi;
    final last = recent.last.aqi;
    final difference = last - first;
    
    if (difference > 10) return 'increasing';
    if (difference < -10) return 'decreasing';
    return 'stable';
  }

  // Get average AQI for period
  double getAverageAqi() {
    if (_historicalData.isEmpty) return 0.0;
    
    final sum = _historicalData.map((d) => d.aqi).reduce((a, b) => a + b);
    return sum / _historicalData.length;
  }

  // Get peak AQI value
  int getPeakAqi() {
    if (_historicalData.isEmpty) return 0;
    
    return _historicalData.map((d) => d.aqi).reduce((a, b) => a > b ? a : b);
  }

  // Get minimum AQI value
  int getMinAqi() {
    if (_historicalData.isEmpty) return 0;
    
    return _historicalData.map((d) => d.aqi).reduce((a, b) => a < b ? a : b);
  }

  // Get air quality improvement percentage
  double getImprovementPercentage() {
    if (_historicalData.length < 2) return 0.0;
    
    // Calculate improvement based on trend over the period
    final firstWeek = _historicalData.take(3).map((d) => d.aqi).reduce((a, b) => a + b) / 3;
    final lastWeek = _historicalData.skip(_historicalData.length - 3).map((d) => d.aqi).reduce((a, b) => a + b) / 3;
    
    if (firstWeek == 0) return 0.0;
    
    final improvement = ((firstWeek - lastWeek) / firstWeek) * 100;
    return improvement.clamp(-50.0, 50.0); // Cap at reasonable values
  }

  // Get dominant pollutant
  String getDominantPollutant() {
    if (_historicalData.isEmpty) return 'Unknown';
    
    final latest = _historicalData.last;
    final pollutants = {
      'PM2.5': latest.pm25,
      'PM10': latest.pm10,
      'O3': latest.o3,
      'NO2': latest.no2,
      'SO2': latest.so2,
      'CO': latest.co,
    };
    
    return pollutants.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Get health recommendations based on current AQI
  List<String> getHealthRecommendations() {
    if (_historicalData.isEmpty) return ['No data available'];
    
    final currentAqi = _historicalData.last.aqi;
    final recommendations = <String>[];
    
    if (currentAqi <= 50) {
      recommendations.addAll([
        'Air quality is good',
        'Enjoy outdoor activities',
        'Good time for exercise',
      ]);
    } else if (currentAqi <= 100) {
      recommendations.addAll([
        'Air quality is moderate',
        'Sensitive people may experience minor breathing discomfort',
        'Consider reducing outdoor activities if you have respiratory issues',
      ]);
    } else if (currentAqi <= 150) {
      recommendations.addAll([
        'Air quality is unhealthy for sensitive groups',
        'Children, elderly, and people with heart/lung disease should avoid outdoor activities',
        'Everyone should limit prolonged outdoor exertion',
      ]);
    } else if (currentAqi <= 200) {
      recommendations.addAll([
        'Air quality is unhealthy',
        'Avoid outdoor activities',
        'Stay indoors with windows closed',
        'Use air purifiers if available',
      ]);
    } else {
      recommendations.addAll([
        'Air quality is very unhealthy',
        'Stay indoors',
        'Use N95 masks if going outside is necessary',
        'Avoid all outdoor activities',
        'Consider evacuating if possible',
      ]);
    }
    
    return recommendations;
  }
}
