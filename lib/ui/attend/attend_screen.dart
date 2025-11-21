import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/core/theme/app_theme.dart';
import 'package:attendance_app/ui/attend/camera_screen.dart';
import 'package:attendance_app/ui/home_screen.dart';

class AttendScreen extends StatefulWidget {
  final XFile? image;

  const AttendScreen({super.key, this.image});

  @override
  State<AttendScreen> createState() => _AttendScreenState();
}

class _AttendScreenState extends State<AttendScreen> {
  XFile? _image;
  String _address = "";
  String _dateTime = "";
  String _status = "Attend";
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _dataCollection = FirebaseFirestore.instance.collection('attendance');

  @override
  void initState() {
    super.initState();
    _image = widget.image;
    _initializeData();
  }

  void _initializeData() async {
    _setDateTime();
    _setAttendanceStatus();
    
    if (_image != null) {
      setState(() => _isLoading = true);
      await _getCurrentLocation();
    }
  }

  void _setDateTime() {
    final now = DateTime.now();
    setState(() {
      _dateTime = DateFormat('dd MMMM yyyy | HH:mm:ss').format(now);
    });
  }

  void _setAttendanceStatus() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    setState(() {
      if (hour < 8 || (hour == 8 && minute <= 30)) {
        _status = "Attend";
      } else if (hour < 18) {
        _status = "Late";
      } else {
        _status = "Leave";
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      await _getAddressFromCoordinates(position);
    } catch (e) {
      _showErrorSnackBar('Failed to get location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showErrorSnackBar('Please enable location services');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar('Location permission permanently denied');
      return false;
    }

    return true;
  }

  Future<void> _getAddressFromCoordinates(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get address: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Attendance recorded successfully!'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
            const SizedBox(width: 16),
            const Text("Submitting attendance..."),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (_image == null || _nameController.text.isEmpty) {
      _showErrorSnackBar('Please capture photo and enter your name');
      return;
    }

    _showLoadingDialog();

    try {
      await _dataCollection.add({
        'address': _address,
        'name': _nameController.text,
        'description': _status,
        'datetime': _dateTime,
        'created_at': FieldValue.serverTimestamp(),
        'type': 'attendance',
      });

      Navigator.of(context).pop(); // Close loading dialog
      _showSuccessSnackBar();
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar('Failed to submit attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Attendance Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Photo Capture Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Capture Photo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CameraScreen()),
                      ),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(_image!.path), fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 40, color: AppTheme.primaryColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to capture photo',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Name Input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 16),

            // Location Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Your Location',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Text(
                            _address.isEmpty ? 'Location will appear here after photo capture' : _address,
                            style: TextStyle(
                              color: _address.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary,
                            ),
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status & Time Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem('Status', _status, Icons.schedule_rounded),
                    _buildInfoItem('Time', DateFormat('HH:mm').format(DateTime.now()), Icons.access_time_rounded),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Text(
                  'SUBMIT ATTENDANCE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}