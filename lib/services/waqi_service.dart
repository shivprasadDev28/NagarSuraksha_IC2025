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

  // Fetch air quality data for current location
  static Future<AirData?> fetchCurrentLocationAirQuality(double latitude, double longitude) async {
    return await fetchAirQualityData(latitude, longitude);
  }

  // Get major Indian cities with their coordinates
  static List<Map<String, dynamic>> getIndianCities() {
    return [
      {'name': 'Delhi', 'lat': 28.6139, 'lng': 77.2090},
      {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777},
      {'name': 'Bangalore', 'lat': 12.9716, 'lng': 77.5946},
      {'name': 'Chennai', 'lat': 13.0827, 'lng': 80.2707},
      {'name': 'Kolkata', 'lat': 22.5726, 'lng': 88.3639},
      {'name': 'Hyderabad', 'lat': 17.3850, 'lng': 78.4867},
      {'name': 'Pune', 'lat': 18.5204, 'lng': 73.8567},
      {'name': 'Ahmedabad', 'lat': 23.0225, 'lng': 72.5714},
      {'name': 'Jaipur', 'lat': 26.9124, 'lng': 75.7873},
      {'name': 'Lucknow', 'lat': 26.8467, 'lng': 80.9462},
      {'name': 'Kanpur', 'lat': 26.4499, 'lng': 80.3319},
      {'name': 'Nagpur', 'lat': 21.1458, 'lng': 79.0882},
      {'name': 'Indore', 'lat': 22.7196, 'lng': 75.8577},
      {'name': 'Thane', 'lat': 19.2183, 'lng': 72.9781},
      {'name': 'Bhopal', 'lat': 23.2599, 'lng': 77.4126},
      {'name': 'Visakhapatnam', 'lat': 17.6868, 'lng': 83.2185},
      {'name': 'Pimpri-Chinchwad', 'lat': 18.6298, 'lng': 73.7997},
      {'name': 'Patna', 'lat': 25.5941, 'lng': 85.1376},
      {'name': 'Vadodara', 'lat': 22.3072, 'lng': 73.1812},
      {'name': 'Ghaziabad', 'lat': 28.6692, 'lng': 77.4538},
    ];
  }

  // Fetch air quality data for multiple Indian cities
  static Future<List<AirData>> fetchIndianCitiesAirQuality() async {
    List<AirData> airQualityData = [];
    final cities = getIndianCities();
    
    for (var city in cities) {
      try {
        final airData = await fetchAirQualityData(city['lat'], city['lng']);
        if (airData != null) {
          airQualityData.add(airData);
        }
      } catch (e) {
        print('Failed to fetch air quality for ${city['name']}: $e');
        // Continue with other cities even if one fails
      }
    }
    
    return airQualityData;
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

