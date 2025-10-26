import 'air_data_model.dart';

class AirQualityPrediction {
  final DateTime date;
  final int predictedAqi;
  final double confidence;
  final String predictionMethod;
  final Map<String, double> predictedPollutants;

  AirQualityPrediction({
    required this.date,
    required this.predictedAqi,
    required this.confidence,
    required this.predictionMethod,
    required this.predictedPollutants,
  });

  factory AirQualityPrediction.fromMap(Map<String, dynamic> map) {
    return AirQualityPrediction(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      predictedAqi: map['predictedAqi'] ?? 0,
      confidence: map['confidence']?.toDouble() ?? 0.0,
      predictionMethod: map['predictionMethod'] ?? 'linear_regression',
      predictedPollutants: Map<String, double>.from(map['predictedPollutants'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'predictedAqi': predictedAqi,
      'confidence': confidence,
      'predictionMethod': predictionMethod,
      'predictedPollutants': predictedPollutants,
    };
  }

  String get aqiCategory {
    if (predictedAqi <= 50) return 'Good';
    if (predictedAqi <= 100) return 'Moderate';
    if (predictedAqi <= 150) return 'Unhealthy for Sensitive';
    if (predictedAqi <= 200) return 'Unhealthy';
    if (predictedAqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String get confidenceText {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  }
}

class AirQualityDataPoint {
  final DateTime timestamp;
  final int aqi;
  final double pm25;
  final double pm10;
  final double o3;
  final double no2;
  final double so2;
  final double co;

  AirQualityDataPoint({
    required this.timestamp,
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
    required this.so2,
    required this.co,
  });

  factory AirQualityDataPoint.fromAirData(AirData airData) {
    return AirQualityDataPoint(
      timestamp: airData.date,
      aqi: airData.aqi,
      pm25: airData.pm25 ?? 0.0,
      pm10: 0.0, // Not available in current AirData model
      o3: 0.0,   // Not available in current AirData model
      no2: 0.0,  // Not available in current AirData model
      so2: 0.0,  // Not available in current AirData model
      co: airData.co2 ?? 0.0,
    );
  }

  factory AirQualityDataPoint.fromMap(Map<String, dynamic> map) {
    return AirQualityDataPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      aqi: map['aqi'] ?? 0,
      pm25: map['pm25']?.toDouble() ?? 0.0,
      pm10: map['pm10']?.toDouble() ?? 0.0,
      o3: map['o3']?.toDouble() ?? 0.0,
      no2: map['no2']?.toDouble() ?? 0.0,
      so2: map['so2']?.toDouble() ?? 0.0,
      co: map['co']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'aqi': aqi,
      'pm25': pm25,
      'pm10': pm10,
      'o3': o3,
      'no2': no2,
      'so2': so2,
      'co': co,
    };
  }
}
