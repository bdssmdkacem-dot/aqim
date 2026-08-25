import 'dart:async';

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _lastRequestKey = 'review_last_request_ms';
  static const _eligibleWeekKey = 'review_eligible_week';
  static const _cooldown = Duration(days: 30);

  final InAppReview _review = InAppReview.instance;
  bool _running = false;

  /// Requests the official Google Play in-app review only after the user has
  /// reached week 2 and only once per 30 days at most. Google Play itself
  /// decides whether the official review dialog is actually shown.
  Future<void> maybeRequestReview({required int currentWeek}) async {
    if (_running || currentWeek < 2) return;
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_lastRequestKey);
      if (lastMs != null) {
        final elapsed = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastMs),
        );
        if (elapsed < _cooldown) return;
      }

      final eligibleWeek = prefs.getInt(_eligibleWeekKey);
      if (eligibleWeek == currentWeek && lastMs != null) return;

      // Give the user time to reach the home screen before requesting review.
      await Future<void>.delayed(const Duration(seconds: 4));
      if (!await _review.isAvailable()) return;

      // Record the request, not a successful rating. The API does not expose
      // whether the user submitted a review, and Google Play controls quota.
      await prefs.setInt(
        _lastRequestKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setInt(_eligibleWeekKey, currentWeek);
      await _review.requestReview();
    } catch (_) {
      // Review prompts are non-critical; never affect app startup or prayer
      // features if Play Store/Play Services are unavailable.
    } finally {
      _running = false;
    }
  }
}
