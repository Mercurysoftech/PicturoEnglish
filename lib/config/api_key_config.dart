class ApiConfig {
  // Option 1: Use environment variables (recommended for production)
  // Run with: flutter run --dart-define=GOOGLE_TRANSLATE_API_KEY=your_key
  static const String googleTranslateApiKey = 
      String.fromEnvironment('AIzaSyDhACYhZTQesXx4bkerzQ-QrGSRfYVEXk0', 
                            defaultValue: 'AIzaSyDhACYhZTQesXx4bkerzQ-QrGSRfYVEXk0');
  
  // Option 2: Simple constant (for development only)
  // static const String googleTranslateApiKey = "your_actual_api_key_here";
}