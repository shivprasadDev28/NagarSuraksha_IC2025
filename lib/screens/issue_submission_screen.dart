import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import '../../models/issue_model.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';
import 'enhanced_map_screen.dart';

class IssueSubmissionScreen extends StatefulWidget {
  final IssueType issueType;

  const IssueSubmissionScreen({
    super.key,
    required this.issueType,
  });

  @override
  State<IssueSubmissionScreen> createState() => _IssueSubmissionScreenState();
}

class _IssueSubmissionScreenState extends State<IssueSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
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
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: $e';
      });
    }
  }

  Future<void> _selectLocationOnMap() async {
    // For now, we'll use a simple dialog to get coordinates
    // In a full implementation, you'd navigate to a location picker screen
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Use current location or enter coordinates manually:'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  final position = await LocationService.getCurrentPosition();
                  if (position != null) {
                    final address = await LocationService.getAddressFromCoordinates(
                      position.latitude,
                      position.longitude,
                    );
                    Navigator.of(context).pop({
                      'latitude': position.latitude,
                      'longitude': position.longitude,
                      'address': address ?? 'Current location',
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to get location: $e')),
                  );
                }
              },
              child: const Text('Use Current Location'),
            ),
            const SizedBox(height: 8),
            const Text('Or'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'latitude': 28.6139,
                  'longitude': 77.2090,
                  'address': 'Delhi, India',
                });
              },
              child: const Text('Use Delhi Center'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLatitude = result['latitude'];
        _selectedLongitude = result['longitude'];
        _selectedAddress = result['address'];
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLatitude == null || _selectedLongitude == null) {
      setState(() {
        _errorMessage = 'Location is required. Please select a location.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final issueProvider = Provider.of<IssueProvider>(context, listen: false);
      
      if (authProvider.firebaseUser == null) {
        throw Exception('User not authenticated');
      }

      String? imageUrl;
      
      // Upload image to Supabase if selected
      if (_selectedImage != null) {
        try {
          final fileName = '${const Uuid().v4()}.jpg';
          print('IssueSubmission: Attempting to upload image: $fileName');
          imageUrl = await SupabaseService.uploadImage(_selectedImage!, fileName);
          print('IssueSubmission: Image uploaded successfully: $imageUrl');
        } catch (e) {
          print('IssueSubmission: Image upload failed: $e');
          // Continue without image rather than failing the entire submission
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image upload failed: $e. Issue will be submitted without image.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Create issue
      final issue = Issue(
        issueId: const Uuid().v4(),
        userId: authProvider.firebaseUser!.uid,
        type: widget.issueType,
        description: _descriptionController.text.trim(),
        imageURL: imageUrl,
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        timestamp: DateTime.now(),
      );

      // Save to Firestore
      await issueProvider.reportIssue(issue);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.issueType.typeDisplayName} reported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report ${widget.issueType.typeDisplayName}'),
        backgroundColor: widget.issueType == IssueType.water 
            ? const Color(0xFF2196F3) 
            : const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Issue Type Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.issueType == IssueType.water 
                      ? const Color(0xFF2196F3).withOpacity(0.1)
                      : const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.issueType == IssueType.water 
                        ? const Color(0xFF2196F3)
                        : const Color(0xFFFF9800),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.issueType == IssueType.water 
                          ? Icons.water_drop 
                          : Icons.construction,
                      size: 32,
                      color: widget.issueType == IssueType.water 
                          ? const Color(0xFF2196F3)
                          : const Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.issueType.typeDisplayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.issueType == IssueType.water 
                                  ? const Color(0xFF2196F3)
                                  : const Color(0xFFFF9800),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.issueType == IssueType.water
                                ? 'Report water supply issues, contamination, or low pressure'
                                : 'Report construction issues, potholes, or infrastructure problems',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Describe the issue',
                  hintText: widget.issueType == IssueType.water
                      ? 'e.g., No water supply since morning, water pressure is very low'
                      : 'e.g., Large pothole on main road, illegal construction in progress',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the issue';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide more details (at least 10 characters)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Image Section
              const Text(
                'Add Photo (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              
              if (_selectedImage == null) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(8),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Tap to take a photo',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Photos help authorities understand the issue better',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Location Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF3CB371)),
                        const SizedBox(width: 8),
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _selectLocationOnMap,
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text('Select on Map'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedAddress != null) ...[
                      Text(
                        _selectedAddress!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (_selectedLatitude != null && _selectedLongitude != null) ...[
                      Text(
                        'Latitude: ${_selectedLatitude!.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                      ),
                      Text(
                        'Longitude: ${_selectedLongitude!.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                      ),
                    ] else ...[
                      const Text(
                        'Location will be detected automatically or select on map',
                        style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitIssue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.issueType == IssueType.water 
                      ? const Color(0xFF2196F3)
                      : const Color(0xFFFF9800),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Submitting...'),
                        ],
                      )
                    : Text(
                        'Submit ${widget.issueType.typeDisplayName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
