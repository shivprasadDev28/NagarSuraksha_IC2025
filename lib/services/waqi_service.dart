import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_data_model.dart';
import '../utils/environment.dart';

class WAQIService {
  static const String _baseUrl = 'https://api.waqi.info/feed';

  // Fetch air quality data for a specific location
  static Future<AirData?> fetchAirQualityData(double latitude, double longitude) async {
    try {
      String url = '$_baseUrl/geo:$latitude;$longitude/?token=${Environment.waqiApiToken}';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'ok' && data['data'] != null) {
          Map<String, dynamic> airData = data['data'];
          
          // Extract AQI data
          int aqi = airData['aqi'] ?? 0;
          Map<String, dynamic> iaqi = airData['iaqi'] ?? {};
          
          double? pm25 = iaqi['pm25']?['v']?.toDouble();
          double? co2 = iaqi['co']?['v']?.toDouble();
          double? temperature = iaqi['t']?['v']?.toDouble();
          
          // Determine risk level based on AQI
          String riskLevel = _getRiskLevel(aqi);
          
          return AirData(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            date: DateTime.now(),
            aqi: aqi,
            pm25: pm25,
            co2: co2,
            temperature: temperature,
            riskLevel: riskLevel,
            latitude: latitude,
            longitude: longitude,
          );
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to fetch air quality data: $e');
    }
  }

  // Fetch air quality data for Delhi (default location)
  static Future<AirData?> fetchDelhiAirQuality() async {
    return await fetchAirQualityData(
      Environment.defaultLatitude,
      Environment.defaultLongitude,
    );
  }

  // Get risk level based on AQI value
  static String _getRiskLevel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  // Predict next day AQI using simple moving average
  static Future<int> predictNextDayAQI(List<AirData> historicalData) async {
    if (historicalData.length < 7) {
      // If not enough data, return current AQI
      return historicalData.isNotEmpty ? historicalData.first.aqi : 50;
    }

    // Calculate 7-day moving average
    List<int> recentAQIs = historicalData.take(7).map((data) => data.aqi).toList();
    double average = recentAQIs.reduce((a, b) => a + b) / recentAQIs.length;
    
    // Add some trend analysis (simplified)
    if (recentAQIs.length >= 3) {
      double trend = (recentAQIs[0] - recentAQIs[2]) / 2.0;
      average += trend * 0.3; // Apply 30% of trend
    }

    return average.round().clamp(0, 500);
  }

  // Get AQI color based on value
  static String getAQIColor(int aqi) {
    if (aqi <= 50) return '#00E400';
    if (aqi <= 100) return '#FFFF00';
    if (aqi <= 150) return '#FF7E00';
    if (aqi <= 200) return '#FF0000';
    if (aqi <= 300) return '#8F3F97';
    return '#7E0023';
  }

  // Get AQI description
  static String getAQIDescription(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
}
