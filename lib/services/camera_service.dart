import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static CameraService? _instance;
  static CameraService get instance => _instance ??= CameraService._();
  CameraService._();

  List<CameraDescription>? _cameras;
  CameraController? _controller;
  int _currentCameraIndex = 0;

  List<CameraDescription>? get cameras => _cameras;
  CameraController? get controller => _controller;
  bool get hasMultipleCameras => _cameras != null && _cameras!.length > 1;
  bool get isUsingFrontCamera =>
      _cameras != null &&
      _currentCameraIndex < _cameras!.length &&
      _cameras![_currentCameraIndex].lensDirection == CameraLensDirection.front;

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      throw Exception('Failed to initialize cameras: $e');
    }
  }

  Future<void> initializeController([int? cameraIndex]) async {
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('No cameras available');
    }

    if (cameraIndex != null && cameraIndex < _cameras!.length) {
      _currentCameraIndex = cameraIndex;
    }

    // Properly dispose of the old controller before creating a new one
    final oldController = _controller;
    _controller = null;

    if (oldController != null) {
      await oldController.dispose();
    }

    _controller = CameraController(
      _cameras![_currentCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
    } catch (e) {
      debugPrint('Error initializing camera controller: $e');
      _controller?.dispose();
      _controller = null;
      throw Exception('Failed to initialize camera controller: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) {
      throw Exception('Cannot switch camera: not enough cameras available');
    }

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    await initializeController(_currentCameraIndex);
  }

  Future<Uint8List?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      // TODO: Temporarily disabled front camera flipping to test API
      // If using front camera, flip the image horizontally for a natural selfie
      // if (isUsingFrontCamera) {
      //   debugPrint('Processing front camera image - original size: ${imageBytes.length}');
      //   final img.Image? originalImage = img.decodeImage(imageBytes);
      //   if (originalImage != null) {
      //     final img.Image flippedImage = img.flipHorizontal(originalImage);
      //     final Uint8List processedBytes = Uint8List.fromList(img.encodeJpg(flippedImage, quality: 95));
      //     debugPrint('Processed front camera image - new size: ${processedBytes.length}');
      //     return processedBytes;
      //   }
      // }

      return imageBytes;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      throw Exception('Failed to take picture: $e');
    }
  }

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }
}