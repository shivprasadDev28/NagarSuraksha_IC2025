import 'package:flutter/material.dart';
import '../../models/air_data_model.dart';
import '../../providers/air_data_provider.dart';
import 'package:provider/provider.dart';

class AirQualityCard extends StatelessWidget {
  final AirData? airData;
  final bool isLoading;

  const AirQualityCard({
    super.key,
    required this.airData,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (airData == null) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Unable to load air quality data',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Air Quality',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Consumer<AirDataProvider>(
                      builder: (context, airDataProvider, child) {
                        if (airDataProvider.currentLatitude != null && 
                            airDataProvider.currentLongitude != null) {
                          return Text(
                            'At your location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          );
                        }
                        return Text(
                          'Delhi, India',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getAQIColor(airData!.aqi).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    airData!.aqiDescription,
                    style: TextStyle(
                      color: _getAQIColor(airData!.aqi),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // AQI Value
            Row(
              children: [
                Text(
                  '${airData!.aqi}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getAQIColor(airData!.aqi),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AQI',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Additional Metrics
            Row(
              children: [
                if (airData!.pm25 != null) ...[
                  _buildMetric('PM2.5', '${airData!.pm25!.round()} μg/m³'),
                  const SizedBox(width: 20),
                ],
                if (airData!.temperature != null) ...[
                  _buildMetric('Temp', '${airData!.temperature!.round()}°C'),
                  const SizedBox(width: 20),
                ],
                if (airData!.co2 != null) ...[
                  _buildMetric('CO₂', '${airData!.co2!.round()} ppm'),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Last Updated
            Text(
              'Last updated: ${_formatTime(airData!.date)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Color _getAQIColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF00E400);
    if (aqi <= 100) return const Color(0xFFFF7E00);
    if (aqi <= 150) return const Color(0xFFFF7E00);
    if (aqi <= 200) return const Color(0xFFFF0000);
    if (aqi <= 300) return const Color(0xFF8F3F97);
    return const Color(0xFF7E0023);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}