import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/issue_model.dart';
import '../models/air_data_model.dart';
import '../providers/issue_provider.dart';
import '../providers/air_data_provider.dart';
import '../providers/notification_provider.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

enum MapMode { issues, airQuality }

class EnhancedMapScreen extends StatefulWidget {
  const EnhancedMapScreen({super.key});

  @override
  State<EnhancedMapScreen> createState() => _EnhancedMapScreenState();
}

class _EnhancedMapScreenState extends State<EnhancedMapScreen> {
  final MapController _mapController = MapController();
  MapMode _currentMode = MapMode.issues;
  bool _showWaterIssues = true;
  bool _showUrbanIssues = true;
  bool _showAirQuality = true;
  LatLng _currentLocation = const LatLng(28.6139, 77.2090); // Delhi default
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadData();
  }

  Future<void> _initializeLocation() async {
    try {
      Position? position = await LocationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Use default Delhi location
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    final issueProvider = Provider.of<IssueProvider>(context, listen: false);
    final airDataProvider = Provider.of<AirDataProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    // Load issues
    issueProvider.refreshIssues();
    
    // Load Indian cities air quality data
    await airDataProvider.fetchIndianCitiesAirData();
    
    // Update notification service with new pollution zones
    if (notificationProvider.isMonitoring) {
      NotificationService.updatePollutionZones(airDataProvider.indianCitiesData);
      notificationProvider.updatePollutionZones();
    }
  }

  Color _getAirQualityColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.red[900]!;
  }

  String _getAirQualityLabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  double _getAirQualityRadius(int aqi) {
    // Scale radius based on AQI (50-200 range maps to 20-80 pixels)
    return 20 + (aqi / 200.0) * 60;
  }

  Widget _buildIssueMarker(Issue issue) {
    Color markerColor = issue.type == IssueType.water ? Colors.blue : Colors.orange;
    IconData icon = issue.type == IssueType.water ? Icons.water_drop : Icons.construction;
    
    return GestureDetector(
      onTap: () => _showIssueDetails(issue),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildAirQualityCircle(AirData airData) {
    final aqi = airData.aqi;
    final color = _getAirQualityColor(aqi);
    final radius = _getAirQualityRadius(aqi);
    
    return GestureDetector(
      onTap: () => _showAirQualityDetails(airData),
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          color: color.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            aqi.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showIssueDetails(Issue issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              issue.type == IssueType.water ? Icons.water_drop : Icons.construction,
              color: issue.type == IssueType.water ? Colors.blue : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(issue.typeDisplayName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              issue.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: issue.status == 'resolved' 
                        ? Colors.green
                        : issue.status == 'verified'
                            ? Colors.blue
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    issue.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${issue.timestamp.day}/${issue.timestamp.month}/${issue.timestamp.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (issue.imageURL != null) ...[
              const SizedBox(height: 8),
              const Text('Image attached', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAirQualityDetails(AirData airData) {
    final color = _getAirQualityColor(airData.aqi);
    final label = _getAirQualityLabel(airData.aqi);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Air Quality'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AQI: ${airData.aqi}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildAirQualityDetailRow('PM2.5', '${airData.pm25 ?? 0} μg/m³'),
            _buildAirQualityDetailRow('CO2', '${airData.co2 ?? 0} ppm'),
            _buildAirQualityDetailRow('Temperature', '${airData.temperature ?? 0}°C'),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${airData.date.day}/${airData.date.month}/${airData.date.year}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAirQualityDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    if (_currentMode == MapMode.issues) {
      return _buildIssuesLegend();
    } else {
      return _buildAirQualityLegend();
    }
  }

  Widget _buildIssuesLegend() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Issues Legend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 8),
                const Text('Water Issues'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.construction, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 8),
                const Text('Urban Issues'),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Status:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Reported', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Verified', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Resolved', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirQualityLegend() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Air Quality Legend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildAirQualityLegendItem(Colors.green, 'Good', '0-50'),
            _buildAirQualityLegendItem(Colors.yellow, 'Moderate', '51-100'),
            _buildAirQualityLegendItem(Colors.orange, 'Unhealthy for Sensitive', '101-150'),
            _buildAirQualityLegendItem(Colors.red, 'Unhealthy', '151-200'),
            _buildAirQualityLegendItem(Colors.purple, 'Very Unhealthy', '201-300'),
            _buildAirQualityLegendItem(Colors.red[900]!, 'Hazardous', '300+'),
            const SizedBox(height: 8),
            const Text(
              'Circle size indicates pollution level',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirQualityLegendItem(Color color, String label, String range) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9)),
          const SizedBox(width: 2),
          Text(range, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delhi Map'),
        backgroundColor: const Color(0xFF3CB371),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(_currentLocation, 13.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.duhm.app',
              ),
              
              // Issue markers
              if (_currentMode == MapMode.issues)
                Consumer<IssueProvider>(
                  builder: (context, issueProvider, child) {
                    return MarkerLayer(
                      markers: [
                        // Current location marker
                        Marker(
                          point: _currentLocation,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                        // Issue markers
                        ...issueProvider.allIssues
                            .where((issue) {
                              if (issue.type == IssueType.water && !_showWaterIssues) return false;
                              if (issue.type == IssueType.urban && !_showUrbanIssues) return false;
                              return true;
                            })
                            .map((issue) => Marker(
                              point: LatLng(issue.latitude, issue.longitude),
                              child: _buildIssueMarker(issue),
                            ))
                            .toList(),
                      ],
                    );
                  },
                ),
              
              // Air quality circles
              if (_currentMode == MapMode.airQuality && _showAirQuality)
                Consumer<AirDataProvider>(
                  builder: (context, airDataProvider, child) {
                    if (airDataProvider.indianCitiesData.isEmpty) {
                      return MarkerLayer(markers: [
                        // Current location marker
                        Marker(
                          point: _currentLocation,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ]);
                    }
                    
                    return MarkerLayer(
                      markers: [
                        // Current location marker
                        Marker(
                          point: _currentLocation,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                        // Air quality markers for Indian cities
                        ...airDataProvider.indianCitiesData.map((airData) {
                          return Marker(
                            point: LatLng(airData.latitude, airData.longitude),
                            child: _buildAirQualityCircle(airData),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
            ],
          ),
          
          // Mode selector - smaller in top right corner
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SegmentedButton<MapMode>(
                  segments: const [
                    ButtonSegment(
                      value: MapMode.issues,
                      label: Text('Issues', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.report_problem, size: 14),
                    ),
                    ButtonSegment(
                      value: MapMode.airQuality,
                      label: Text('Air', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.air, size: 14),
                    ),
                  ],
                  selected: {_currentMode},
                  onSelectionChanged: (Set<MapMode> selection) {
                    setState(() {
                      _currentMode = selection.first;
                    });
                  },
                ),
              ),
            ),
          ),
          
          // Filter controls - smaller in top left corner
          Positioned(
            top: 16,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_currentMode == MapMode.issues) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilterChip(
                            label: const Text('Water', style: TextStyle(fontSize: 10)),
                            selected: _showWaterIssues,
                            onSelected: (value) => setState(() => _showWaterIssues = value),
                            avatar: const Icon(Icons.water_drop, size: 12),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 4),
                          FilterChip(
                            label: const Text('Urban', style: TextStyle(fontSize: 10)),
                            selected: _showUrbanIssues,
                            onSelected: (value) => setState(() => _showUrbanIssues = value),
                            avatar: const Icon(Icons.construction, size: 12),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ] else ...[
                      FilterChip(
                        label: const Text('Air Quality', style: TextStyle(fontSize: 10)),
                        selected: _showAirQuality,
                        onSelected: (value) => setState(() => _showAirQuality = value),
                        avatar: const Icon(Icons.air, size: 12),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Legend - smaller in bottom right corner
          Positioned(
            bottom: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentMode == MapMode.issues ? 'Issues' : 'Air Quality',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (_currentMode == MapMode.issues) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.water_drop, color: Colors.white, size: 8),
                          ),
                          const SizedBox(width: 4),
                          const Text('Water', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.construction, color: Colors.white, size: 8),
                          ),
                          const SizedBox(width: 4),
                          const Text('Urban', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ] else ...[
                      _buildAirQualityLegendItem(Colors.green, 'Good', '0-50'),
                      _buildAirQualityLegendItem(Colors.yellow, 'Moderate', '51-100'),
                      _buildAirQualityLegendItem(Colors.orange, 'Unhealthy', '101-200'),
                      _buildAirQualityLegendItem(Colors.red, 'Very Unhealthy', '200+'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
