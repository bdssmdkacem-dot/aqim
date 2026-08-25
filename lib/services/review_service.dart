import 'dart:async';

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _requestDateKey = 'review_request_date';
  static const _requestCountKey = 'review_request_count';
  static const _maxRequestsPerDay = 4;

  final InAppReview _review = InAppReview.instance;
  bool _running = false;

  /// Attempts the official Google Play in-app review flow when the app opens,
  /// with at most four request attempts per calendar day.
  ///
  /// Google Play controls its own review quota and decides whether the
  /// official dialog is actually shown. A request attempt is therefore not
  /// the same thing as a dialog being displayed.
  Future<void> maybeRequestReview({int? currentWeek}) async {
    if (_running) return;
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _dateKey(DateTime.now());
      final savedDate = prefs.getString(_requestDateKey);
      final requestCount = savedDate == today
          ? (prefs.getInt(_requestCountKey) ?? 0)
          : 0;

      if (requestCount >= _maxRequestsPerDay) return;
      if (!await _review.isAvailable()) return;

      // Let the home screen settle before asking Play to start the review flow.
      await Future<void>.delayed(const Duration(seconds: 4));

      final refreshedPrefs = await SharedPreferences.getInstance();
      final refreshedDate = _dateKey(DateTime.now());
      final refreshedCount = refreshedPrefs.getString(_requestDateKey) == refreshedDate
          ? (refreshedPrefs.getInt(_requestCountKey) ?? 0)
          : 0;
      if (refreshedCount >= _maxRequestsPerDay) return;

      // Record the request, not a successful rating. The API does not expose
      // whether the user submitted a review, or even whether the dialog shown.
      await refreshedPrefs.setString(_requestDateKey, refreshedDate);
      await refreshedPrefs.setInt(_requestCountKey, refreshedCount + 1);
      await _review.requestReview();
    } catch (_) {
      // Review prompts are non-critical; never affect app startup or prayer
      // features if Play Store/Play Services are unavailable.
    } finally {
      _running = false;
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
