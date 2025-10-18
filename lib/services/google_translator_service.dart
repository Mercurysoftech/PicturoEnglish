import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleTranslatorService {
  final String apiKey;

  GoogleTranslatorService(this.apiKey);

  Future<String> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'en',
  }) async {
    try {
      // Validate inputs
      if (apiKey.isEmpty) {
        throw Exception('Google Translate API key is missing');
      }
      
      if (text.isEmpty) {
        return text; // No need to translate empty text
      }
      
      if (targetLanguage.isEmpty) {
        throw Exception('Target language is required');
      }

      final url = Uri.parse(
        'https://translation.googleapis.com/language/translate/v2?key=$apiKey',
      );

      print('Sending translation request...');
      print('Text length: ${text.length}');
      print('Target language: $targetLanguage');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'target': targetLanguage,
          'source': sourceLanguage,
          'format': 'text'
        }),
      ).timeout(Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['error'] != null) {
          final error = data['error'];
          throw Exception('Google API Error: ${error['message']} (Code: ${error['code']})');
        }
        
        final translations = data['data']['translations'];
        if (translations != null && translations.isNotEmpty) {
          final translatedText = translations[0]['translatedText'];
          return translatedText ?? text; // Return original if null
        } else {
          throw Exception('No translations found in response');
        }
      } else if (response.statusCode == 403) {
        throw Exception('API key is invalid or has insufficient permissions');
      } else if (response.statusCode == 400) {
        throw Exception('Bad request - check language codes and text format');
      } else if (response.statusCode == 429) {
        throw Exception('API quota exceeded - try again later');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on TimeoutException catch (e) {
      throw Exception('Translation request timed out: $e');
    } on FormatException catch (e) {
      throw Exception('Invalid response format: $e');
    } catch (e) {
      throw Exception('Translation failed: $e');
    }
  }
}