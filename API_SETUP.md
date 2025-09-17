# Nano Banana - Gemini AI Camera App

## Setup Instructions

### 1. Get Gemini API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key or use an existing one
3. Copy the API key

### 2. Configure API Key
1. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Open the `.env` file and replace `your_gemini_api_key_here` with your actual API key:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```

⚠️ **Security Note**: The `.env` file is already included in `.gitignore` to prevent accidentally committing your API key to version control.

### 3. Run the App
```bash
# Install dependencies
fvm flutter pub get

# Run the app
fvm flutter run
```

## App Features

1. **Camera Screen**: Take photos using your device camera
2. **Input Screen**: Add text description for AI processing
3. **Result Screen**: View AI-generated images based on your photo and description

## How to Use

1. Launch the app
2. Grant camera permissions when prompted
3. Take a photo using the camera
4. Enter a description of what you want the AI to generate
5. Tap "Generate with AI"
6. View the result in the next screen

## API Endpoint

The app uses the Gemini 2.5 Flash Image Preview API endpoint:
```
https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent
```

## Troubleshooting

- Ensure camera permissions are granted
- Verify your API key is valid and has quota
- Check internet connectivity for API calls