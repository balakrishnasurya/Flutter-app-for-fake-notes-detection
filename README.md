# Currency Detection and Authentication App

A Flutter application that detects Indian currency denominations and verifies their authenticity using machine learning models. The app supports both web and mobile platforms.

## Features

- Currency denomination detection (₹10, ₹20, ₹50, ₹100, ₹200, ₹500, ₹2000)
- Authenticity verification (Real/Fake detection)
- Support for both camera capture and gallery image selection
- Cross-platform support (Web, Android, iOS)
- Real-time processing with confidence scores

## API Documentation

The backend API is deployed at: `https://goldfish-app-ils97.ondigitalocean.app`

### Endpoints:

1. **Health Check**
   ```
   GET /api/health
   ```
   Response:
   ```json
   {
       "status": "healthy",
       "message": "API is running normally"
   }
   ```

2. **Prediction Endpoint**
   ```
   POST /api/predict
   ```
   - Content-Type: multipart/form-data
   - Body: image file (key: "image")

   Sample Response:
   ```json
   {
       "success": true,
       "authenticity": {
           "prediction": "Real Currency",
           "confidence": 0.95
       },
       "denomination": {
           "prediction": "500_rupee",
           "confidence": 0.98
       },
       "message": "Currency appears to be real 500_rupee with 95% authenticity confidence"
   }
   ```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio or VS Code
- Android SDK for Android development
- Physical device or emulator for testing

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/currency-detection-app.git
   cd currency-detection-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Android SDK** (for Android development)
   - Set ANDROID_HOME environment variable
   - Add platform-tools to PATH
   ```bash
   export ANDROID_HOME=/path/to/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   ```

4. **Run the app**
   
   For web:
   ```bash
   flutter run -d chrome
   ```

   For Android:
   ```bash
   flutter run -d <device-id>
   ```

### Running on Physical Android Device

1. Enable Developer Options on your Android device
   - Go to Settings > About phone
   - Tap Build number 7 times
   - Enable USB debugging in Developer options

2. Connect your device and verify:
   ```bash
   flutter devices
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

The project follows a standard Flutter application structure with additional API integration:
currency_detection_app/
├── lib/
│ ├── main.dart # Main application entry
├── android/ # Android-specific files
├── ios/ # iOS-specific files
├── web/ # Web platform files
└── pubspec.yaml # Project dependencies

## Technical Details

### Frontend (Flutter)
- Uses image_picker for camera and gallery access
- HTTP requests for API communication
- Cross-platform UI components
- Responsive design for various screen sizes

### Backend (Flask)
- Machine learning models for denomination detection
- Image processing using OpenCV
- Feature extraction for authenticity verification
- RESTful API endpoints

## Dependencies

Key dependencies used in the project:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.6
  image_picker: ^1.0.4
  path_provider: ^2.0.15
  http_parser: ^4.0.2
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
