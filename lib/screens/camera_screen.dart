import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/camera_service.dart';
import 'input_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Request camera permission
      final hasPermission = await _cameraService.requestCameraPermission();
      if (!hasPermission) {
        setState(() {
          _error = 'Camera permission denied';
          _isLoading = false;
        });
        return;
      }

      // Initialize cameras
      await _cameraService.initializeCameras();
      await _cameraService.initializeController();

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (!_isInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Uint8List? imageBytes = await _cameraService.takePicture();
      if (imageBytes != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InputScreen(imageBytes: imageBytes),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (!_cameraService.hasMultipleCameras) return;

    setState(() {
      _isLoading = true;
      _isInitialized = false;
    });

    try {
      await _cameraService.switchCamera();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _error = 'Failed to switch camera: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => InputScreen(imageBytes: imageBytes),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading camera...'),
          ],
        ),
      );
    }

    if (_error != null) {
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
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _cameraService.controller == null) {
      return const Center(
        child: Text('Camera not available'),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraService.controller!.value.previewSize!.height,
              height: _cameraService.controller!.value.previewSize!.width,
              child: CameraPreview(_cameraService.controller!),
            ),
          ),
        ),
        // Camera switch button (top right)
        if (_cameraService.hasMultipleCameras)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _switchCamera,
                icon: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        // Bottom controls
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : _pickImageFromGallery,
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              // Capture button
              GestureDetector(
                onTap: _isLoading ? null : _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.grey : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              // Placeholder for symmetry
              const SizedBox(width: 48, height: 48),
            ],
          ),
        ),
      ],
    );
  }
}