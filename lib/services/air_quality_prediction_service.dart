import 'dart:math';
import '../models/air_data_model.dart';
import '../models/air_quality_prediction_model.dart';
import '../utils/environment.dart';

class AirQualityPredictionService {
  // Simple linear regression prediction based on historical data
  static AirQualityPrediction predictNextDay(List<AirQualityDataPoint> historicalData) {
    if (historicalData.length < 3) {
      // Not enough data for prediction, return current trend
      final latest = historicalData.last;
      return AirQualityPrediction(
        date: DateTime.now().add(const Duration(days: 1)),
        predictedAqi: latest.aqi,
        confidence: 0.3,
        predictionMethod: 'insufficient_data',
        predictedPollutants: {
          'pm25': latest.pm25,
          'pm10': latest.pm10,
          'o3': latest.o3,
          'no2': latest.no2,
          'so2': latest.so2,
          'co': latest.co,
        },
      );
    }

    // Calculate trend using linear regression
    final trend = _calculateTrend(historicalData);
    final confidence = _calculateConfidence(historicalData);
    
    // Predict next day values
    final nextDay = DateTime.now().add(const Duration(days: 1));
    final predictedAqi = (historicalData.last.aqi + trend).round().clamp(0, 500);
    
    // Predict individual pollutants
    final predictedPollutants = <String, double>{};
    for (final pollutant in ['pm25', 'pm10', 'o3', 'no2', 'so2', 'co']) {
      final pollutantTrend = _calculatePollutantTrend(historicalData, pollutant);
      final currentValue = _getPollutantValue(historicalData.last, pollutant);
      predictedPollutants[pollutant] = (currentValue + pollutantTrend).clamp(0.0, 1000.0);
    }

    return AirQualityPrediction(
      date: nextDay,
      predictedAqi: predictedAqi,
      confidence: confidence,
      predictionMethod: 'linear_regression',
      predictedPollutants: predictedPollutants,
    );
  }

  // Calculate AQI trend using linear regression
  static double _calculateTrend(List<AirQualityDataPoint> data) {
    if (data.length < 2) return 0.0;

    final n = data.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble(); // Time index
      final y = data[i].aqi.toDouble(); // AQI value
      
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    // Linear regression formula: slope = (n*sumXY - sumX*sumY) / (n*sumXX - sumX*sumX)
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    
    // Return trend for next day (scaled by time difference)
    return slope;
  }

  // Calculate trend for specific pollutant
  static double _calculatePollutantTrend(List<AirQualityDataPoint> data, String pollutant) {
    if (data.length < 2) return 0.0;

    final n = data.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = _getPollutantValue(data[i], pollutant);
      
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope;
  }

  // Get pollutant value by name
  static double _getPollutantValue(AirQualityDataPoint data, String pollutant) {
    switch (pollutant) {
      case 'pm25': return data.pm25;
      case 'pm10': return data.pm10;
      case 'o3': return data.o3;
      case 'no2': return data.no2;
      case 'so2': return data.so2;
      case 'co': return data.co;
      default: return 0.0;
    }
  }

  // Calculate prediction confidence based on data consistency
  static double _calculateConfidence(List<AirQualityDataPoint> data) {
    if (data.length < 3) return 0.3;

    // Calculate variance in AQI values
    final aqiValues = data.map((d) => d.aqi.toDouble()).toList();
    final mean = aqiValues.reduce((a, b) => a + b) / aqiValues.length;
    final variance = aqiValues.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / aqiValues.length;
    final standardDeviation = sqrt(variance);

    // Higher variance = lower confidence
    final baseConfidence = 0.8;
    final variancePenalty = (standardDeviation / mean).clamp(0.0, 0.5);
    
    return (baseConfidence - variancePenalty).clamp(0.1, 0.9);
  }

  // Generate historical data for demonstration (in real app, this would come from API)
  static List<AirQualityDataPoint> generateHistoricalData() {
    final now = DateTime.now();
    final data = <AirQualityDataPoint>[];
    
    // Generate 7 days of historical data with some variation
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final baseAqi = 120 + (i * 5); // Slight upward trend
      final variation = Random().nextInt(20) - 10; // Random variation
      final aqi = (baseAqi + variation).clamp(50, 200);
      
      data.add(AirQualityDataPoint(
        timestamp: date,
        aqi: aqi,
        pm25: (aqi * 0.8 + Random().nextInt(10) - 5).clamp(0.0, 200.0),
        pm10: (aqi * 1.2 + Random().nextInt(15) - 7).clamp(0.0, 300.0),
        o3: (aqi * 0.6 + Random().nextInt(8) - 4).clamp(0.0, 150.0),
        no2: (aqi * 0.7 + Random().nextInt(12) - 6).clamp(0.0, 180.0),
        so2: (aqi * 0.3 + Random().nextInt(6) - 3).clamp(0.0, 100.0),
        co: (aqi * 0.1 + Random().nextInt(3) - 1).clamp(0.0, 50.0),
      ));
    }
    
    return data;
  }

  // Get air quality category color
  static String getAqiCategoryColor(int aqi) {
    if (aqi <= 50) return 'green';
    if (aqi <= 100) return 'yellow';
    if (aqi <= 150) return 'orange';
    if (aqi <= 200) return 'red';
    if (aqi <= 300) return 'purple';
    return 'maroon';
  }

  // Get air quality category name
  static String getAqiCategoryName(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
}
