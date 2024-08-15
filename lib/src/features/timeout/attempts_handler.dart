import 'dart:math' as math;

import 'package:flutter_pin_code/src/exceptions/cant_return_timeout_exception.dart';
import 'package:flutter_pin_code/src/exceptions/cant_waste_attempt_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO(Sosnovyy): add writing and reading from prefs
class AttemptsHandler {
  AttemptsHandler({
    required SharedPreferences prefs,
    required this.timeoutsConfig,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;

  /// Timeouts configuration from the general config.
  final Map<int, int> timeoutsConfig;

  /// Current available attempts map in <seconds, amount> format.
  late final Map<int, int> currentAttempts;

  /// Method to initialize the attempts handler.
  /// This method must be called before any other method in this class.
  Future<void> initialize() async {
    // TODO(Sosnovyy): initialize currentAttempts from prefs
  }

  /// Method to add an attempt back to the current attempts pool
  void returnAttempt(int duration) {
    if (currentAttempts.containsKey(duration)) {
      currentAttempts[duration] = currentAttempts[duration]! + 1;
    } else {
      throw CantReturnTimeoutException(
        'Wrong timeout duration provided ($duration), '
        'only ${currentAttempts.keys} are available',
      );
    }
  }

  /// Method to waste an attempt from the current attempts pool
  void wasteAttempt() {
    if (!isAvailable) {
      throw const CantWasteAttemptException('No attempts available right now');
    }
    final currentAvailableDuration = currentAttempts.keys
        .where((duration) => currentAttempts[duration]! > 0)
        .reduce(math.min);
    currentAttempts[currentAvailableDuration] =
        currentAttempts[currentAvailableDuration]! - 1;
  }

  /// Method to check if any attempt is available right now
  bool get isAvailable => currentAttempts.values.any((amount) => amount > 0);
}
