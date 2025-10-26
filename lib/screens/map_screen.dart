import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/issue_model.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  final Function(double latitude, double longitude, String address)? onLocationSelected;
  final double? initialLatitude;
  final double? initialLongitude;
  final List<Issue>? issues;

  const MapScreen({
    super.key,
    this.onLocationSelected,
    this.initialLatitude,
    this.initialLongitude,
    this.issues,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = true;
  LatLng _currentLocation = const LatLng(28.6139, 77.2090); // Delhi default

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Try to get current location
      Position? position = await LocationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
        });
        
        // Get address for current location
        String? address = await LocationService.getAddressFromCoordinates(
          position.latitude, 
          position.longitude
        );
        if (address != null) {
          setState(() {
            _selectedAddress = address;
          });
        }
      } else if (widget.initialLatitude != null && widget.initialLongitude != null) {
        // Use provided initial location
        setState(() {
          _currentLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
          _selectedLocation = _currentLocation;
        });
      }
    } catch (e) {
      // Use default Delhi location
      setState(() {
        _currentLocation = const LatLng(28.6139, 77.2090);
        _selectedLocation = _currentLocation;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _selectedLocation = point;
    });

    // Get address for selected location
    try {
      String? address = await LocationService.getAddressFromCoordinates(
        point.latitude, 
        point.longitude
      );
      setState(() {
        _selectedAddress = address ?? 'Unknown location';
      });
    } catch (e) {
      setState(() {
        _selectedAddress = 'Unknown location';
      });
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null && widget.onLocationSelected != null) {
      widget.onLocationSelected!(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        _selectedAddress ?? 'Selected location',
      );
      Navigator.of(context).pop();
    } else if (_selectedLocation != null) {
      Navigator.of(context).pop({
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _selectedAddress ?? 'Selected location',
      });
    }
  }

  Widget _buildIssueMarker(Issue issue) {
    Color markerColor = issue.type == IssueType.water ? Colors.blue : Colors.orange;
    
    return GestureDetector(
      onTap: () {
        _showIssueDetails(issue);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          issue.type == IssueType.water ? Icons.water_drop : Icons.construction,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  void _showIssueDetails(Issue issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(issue.typeDisplayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(issue.description),
            const SizedBox(height: 8),
            Text(
              'Status: ${issue.status}',
              style: TextStyle(
                color: issue.status == 'resolved' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reported: ${issue.timestamp.day}/${issue.timestamp.month}/${issue.timestamp.year}',
              style: const TextStyle(fontSize: 12),
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
        title: const Text('Select Location'),
        actions: [
          IconButton(
            onPressed: _confirmLocation,
            icon: const Icon(Icons.check),
            tooltip: 'Confirm Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.duhm.app',
              ),
              // Show existing issues
              if (widget.issues != null)
                MarkerLayer(
                  markers: widget.issues!.map((issue) {
                    return Marker(
                      point: LatLng(issue.latitude, issue.longitude),
                      child: _buildIssueMarker(issue),
                    );
                  }).toList(),
                ),
              // Show selected location marker
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
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
                  ],
                ),
            ],
          ),
          // Location info card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Location:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress ?? 'Tap on map to select location',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedLocation != null ? _confirmLocation : null,
                        child: const Text('Confirm Location'),
                      ),
                    ),
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