import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart'; // For formatting date

class ReviewHelper {
  static const _lastReviewDateKey = 'last_review_date';

  static Future<void> askForReviewOncePerDay() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(now);

    final lastShownDate = prefs.getString(_lastReviewDateKey);

    if (lastShownDate != todayString) {
      final review = InAppReview.instance;

      if (await review.isAvailable()) {
        await review.requestReview();
        await prefs.setString(_lastReviewDateKey, todayString);
      }
    }
  }
}