import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:attendance_app/core/theme/app_theme.dart';
import 'package:attendance_app/ui/attend/attend_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.medium);
      await _controller!.initialize();
      
      setState(() => _isInitializing = false);
    } catch (e) {
      _showErrorSnackBar('Failed to initialize camera: $e');
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

  Future<bool> _checkLocationPermission() async {
    // Untuk web, location permission handled differently
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

    return true;
  }

  Future<void> _captureImage() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isProcessing = true);

    try {
      final hasLocationPermission = await _checkLocationPermission();
      if (!hasLocationPermission) {
        setState(() => _isProcessing = false);
        return;
      }

      final XFile image = await _controller!.takePicture();
      
      // Untuk WEB: Skip face detection, langsung lanjut
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AttendScreen(image: image),
        ),
      );

    } catch (e) {
      _showErrorSnackBar('Failed to capture image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Capture Selfie',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  SizedBox(height: 16),
                  Text(
                    'Initializing Camera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // Face Detection Guide (tetap tampil untuk UX consistency)
          if (!_isInitializing)
            Center(
              child: Container(
                width: 250,
                height: 350,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Position your face within the frame',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 20),
                  _isProcessing
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : FloatingActionButton(
                          onPressed: _captureImage,
                          backgroundColor: AppTheme.primaryColor,
                          child: const Icon(Icons.camera_alt_rounded, size: 30),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}