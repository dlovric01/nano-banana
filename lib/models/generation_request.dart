class GenerationRequest {
  final String imageBase64;
  final String prompt;

  GenerationRequest({
    required this.imageBase64,
    required this.prompt,
  });

  Map<String, dynamic> toJson() {
    return {
      "contents": [
        {
          "parts": [
            {
              "text": prompt,
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": imageBase64,
              }
            }
          ]
        }
      ]
    };
  }
}

class GenerationResponse {
  final String? imageUrl;
  final String? error;
  final bool success;

  GenerationResponse({
    this.imageUrl,
    this.error,
    required this.success,
  });

  factory GenerationResponse.success(String imageUrl) {
    return GenerationResponse(
      imageUrl: imageUrl,
      success: true,
    );
  }

  factory GenerationResponse.error(String error) {
    return GenerationResponse(
      error: error,
      success: false,
    );
  }
}