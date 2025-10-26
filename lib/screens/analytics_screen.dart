import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';
import '../providers/air_data_provider.dart';
import '../models/air_quality_prediction_model.dart';
import '../services/air_quality_prediction_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalyticsData();
    });
  }

  Future<void> _loadAnalyticsData() async {
    final airDataProvider = Provider.of<AirDataProvider>(context, listen: false);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    
    if (airDataProvider.currentLatitude != null && airDataProvider.currentLongitude != null) {
      await analyticsProvider.loadAnalyticsDataForLocation(
        airDataProvider.currentLatitude!,
        airDataProvider.currentLongitude!,
      );
    } else {
      await analyticsProvider.loadAnalyticsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Air Quality Analytics'),
        backgroundColor: const Color(0xFF3CB371),
        foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadAnalyticsData,
                  ),
                ],
      ),
      body: Consumer2<AnalyticsProvider, AirDataProvider>(
        builder: (context, analyticsProvider, airDataProvider, child) {
          if (analyticsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (analyticsProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    analyticsProvider.errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAnalyticsData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location indicator
                if (airDataProvider.currentLatitude != null && airDataProvider.currentLongitude != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF3CB371), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Analytics for your current location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Prediction Card
                _buildPredictionCard(analyticsProvider),
                
                const SizedBox(height: 16),
                
                // Air Quality Trend Chart
                _buildTrendChart(analyticsProvider),
                
                const SizedBox(height: 16),
                
                // Statistics Cards
                _buildStatisticsCards(analyticsProvider),
                
                const SizedBox(height: 16),
                
                // Health Recommendations
                _buildHealthRecommendations(analyticsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPredictionCard(AnalyticsProvider provider) {
    final prediction = provider.prediction;
    if (prediction == null) return const SizedBox.shrink();

    final aqiColor = _getAqiColor(prediction.predictedAqi);
    final confidenceColor = _getConfidenceColor(prediction.confidence);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Color(0xFF3CB371)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tomorrow\'s Prediction',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: confidenceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(prediction.confidence * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: aqiColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      prediction.predictedAqi.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.aqiCategory,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: aqiColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Predicted AQI: ${prediction.predictedAqi}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Method: ${prediction.predictionMethod.replaceAll('_', ' ').toUpperCase()}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Predicted Pollutant Levels:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: prediction.predictedPollutants.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.key.toUpperCase()}: ${entry.value.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(AnalyticsProvider provider) {
    final chartData = provider.getChartData();
    if (chartData.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Air Quality Trend (Last 7 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            final date = chartData[value.toInt()].timestamp;
                            return Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.aqi.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF3CB371),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF3CB371).withOpacity(0.1),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: (chartData.length - 1).toDouble(),
                  minY: 0,
                  maxY: chartData.map((d) => d.aqi).reduce((a, b) => a > b ? a : b).toDouble() + 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(AnalyticsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Average AQI',
            provider.getAverageAqi().toInt().toString(),
            Icons.analytics,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Peak AQI',
            provider.getPeakAqi().toString(),
            Icons.trending_up,
            Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Trend',
            '${provider.getImprovementPercentage().toStringAsFixed(1)}%',
            Icons.trending_down,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecommendations(AnalyticsProvider provider) {
    final recommendations = provider.getHealthRecommendations();
    final trend = provider.getAqiTrend();
    final dominantPollutant = provider.getDominantPollutant();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Trend indicator
            Row(
              children: [
                Icon(
                  trend == 'increasing' ? Icons.trending_up : 
                  trend == 'decreasing' ? Icons.trending_down : Icons.trending_flat,
                  color: trend == 'increasing' ? Colors.red : 
                         trend == 'decreasing' ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trend: ${trend.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: trend == 'increasing' ? Colors.red : 
                             trend == 'decreasing' ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              'Dominant Pollutant: $dominantPollutant',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...recommendations.map((recommendation) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.red[900]!;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}