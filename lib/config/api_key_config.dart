class ApiConfig {
  // Option 1: Use environment variables (recommended for production)
  // Run with: flutter run --dart-define=GOOGLE_TRANSLATE_API_KEY=your_key
  static const String googleTranslateApiKey = 
      String.fromEnvironment('AIzaSyDn1WqfWC2gG6zck-kAPs2kswqdugsC2yI', 
                            defaultValue: 'AIzaSyDn1WqfWC2gG6zck-kAPs2kswqdugsC2yI');
  
  // Option 2: Simple constant (for development only)
  // static const String googleTranslateApiKey = "your_actual_api_key_here";
}