import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import '../models/generation_request.dart';
import 'camera_screen.dart';

class ResultScreen extends StatefulWidget {
  final GenerationResponse response;
  final Uint8List originalImageBytes;

  const ResultScreen({
    super.key,
    required this.response,
    required this.originalImageBytes,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;

  Future<void> _saveImages() async {
    if (widget.response.imageUrl == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Create timestamp for filenames
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Save original image
      await Gal.putImageBytes(
        widget.originalImageBytes,
        name: 'nano_banana_original_$timestamp',
      );

      // Save generated/edited image
      final Uint8List editedImageBytes = base64Decode(widget.response.imageUrl!);
      await Gal.putImageBytes(
        editedImageBytes,
        name: 'nano_banana_edited_$timestamp',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Both images saved to gallery!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!widget.response.success) {
      return _buildErrorState(context);
    }

    if (widget.response.imageUrl != null) {
      return _buildImageResult(context);
    }

    return _buildNoContentState(context);
  }

  Widget _buildImageResult(BuildContext context) {
    return Column(
      children: [
        // Generated image
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(),
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveImages,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const CameraScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('New Photo'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    try {
      final Uint8List imageBytes = base64Decode(widget.response.imageUrl!);
      return Image.memory(
        imageBytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey.shade100,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        height: 200,
        color: Colors.grey.shade100,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              SizedBox(height: 8),
              Text(
                'Invalid image data',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Generation Failed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.response.error ?? 'Unknown error occurred',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const CameraScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('New Photo'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoContentState(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline,
                size: 64,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Content Generated',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'The AI did not generate any visual content for your request.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const CameraScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('New Photo'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}