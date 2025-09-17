import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/generation_request.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  final Dio _dio = Dio();

  Future<GenerationResponse> generateContent({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    // Check if API key is configured
    if (_apiKey.isEmpty) {
      return GenerationResponse.error('Gemini API key not configured. Please add GEMINI_API_KEY to your .env file.');
    }

    // Retry logic for temporary server errors
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        debugPrint('=== ATTEMPT $attempt ===');
      // Convert image to base64
      final String imageBase64 = base64Encode(imageBytes);

      // Create request with proper MIME type
      final request = GenerationRequest(
        imageBase64: imageBase64,
        prompt: prompt,
      );

      final requestData = request.toJson();
      debugPrint('=== SENDING REQUEST ===');
      debugPrint('URL: $_baseUrl');
      debugPrint('Headers: Content-Type: application/json, x-goog-api-key: ${_apiKey.substring(0, 20)}...');
      debugPrint('Prompt: $prompt');
      debugPrint('Image size: ${imageBytes.length} bytes');
      debugPrint('=== FULL REQUEST JSON ===');
      debugPrint(jsonEncode(requestData));
      debugPrint('=====================');

      // Make API call
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
        ),
        data: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        debugPrint('=== FULL API RESPONSE ===');
        debugPrint(jsonEncode(responseData));
        debugPrint('========================');

        // Parse response to extract generated image data
        // Based on curl example: grep -o '"data": "[^"]*"' | cut -d'"' -f4

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {

          debugPrint('Found ${responseData['candidates'].length} candidates');

          final candidate = responseData['candidates'][0];
          debugPrint('Candidate structure: ${jsonEncode(candidate)}');

          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {

            final parts = candidate['content']['parts'];
            debugPrint('Found ${parts.length} parts in response');

            // Look for image data in parts - check different possible structures
            for (int i = 0; i < parts.length; i++) {
              final part = parts[i];
              debugPrint('Part $i structure: ${jsonEncode(part)}');

              // Check for inlineData structure (camelCase - actual API response)
              if (part['inlineData'] != null && part['inlineData']['data'] != null) {
                final imageData = part['inlineData']['data'];
                debugPrint('Found image data in inlineData, length: ${imageData.length}');
                return GenerationResponse.success(imageData);
              }

              // Check for inline_data structure (snake_case - just in case)
              if (part['inline_data'] != null && part['inline_data']['data'] != null) {
                final imageData = part['inline_data']['data'];
                debugPrint('Found image data in inline_data, length: ${imageData.length}');
                return GenerationResponse.success(imageData);
              }

              // Check for direct data field (based on curl example)
              if (part['data'] != null) {
                final imageData = part['data'];
                debugPrint('Found image data in direct data field, length: ${imageData.length}');
                return GenerationResponse.success(imageData);
              }
            }

            // If no image data found, check for text response
            for (final part in parts) {
              if (part['text'] != null) {
                final textContent = part['text'];
                debugPrint('Text response received: $textContent');
                return GenerationResponse.error('Model provided analysis instead of image generation: $textContent');
              }
            }
          } else {
            debugPrint('Candidate content structure: ${candidate['content']}');
          }
        } else {
          debugPrint('No candidates found in response');
        }

        return GenerationResponse.error('No valid content found in API response');
      } else {
        return GenerationResponse.error('API request failed: ${response.statusCode} - ${response.data}');
      }
      } on DioException catch (e) {
        String errorMessage = 'Network error occurred';

        if (e.response != null) {
          errorMessage = 'API Error: ${e.response?.statusCode} - ${e.response?.data}';

          // Retry on 500 errors (server issues)
          if (e.response?.statusCode == 500 && attempt < 2) {
            debugPrint('Server error (500), retrying in 2 seconds... Attempt $attempt');
            await Future.delayed(const Duration(seconds: 2));
            continue; // Retry
          }
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Receive timeout';
        }

        debugPrint('Gemini API Error: $errorMessage');
        return GenerationResponse.error(errorMessage);
      } catch (e) {
        debugPrint('Unexpected error: $e');
        return GenerationResponse.error('Unexpected error: $e');
      }
    }

    // If we get here, all attempts failed
    return GenerationResponse.error('All attempts failed');
  }
}