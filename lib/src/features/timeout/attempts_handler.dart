import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_pin_code/src/exceptions/cant_return_timeout_exception.dart';
import 'package:flutter_pin_code/src/exceptions/cant_waste_attempt_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kAttemptsPoolKey = 'flutter_pin_code.attempts_pool';

class AttemptsHandler {
  AttemptsHandler({
    required SharedPreferences prefs,
    required this.timeoutsMap,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;

  /// Timeouts configuration from the general config.
  final Map<int, int> timeoutsMap;

  /// Current available attempts map in <seconds, amount> format.
  late final Map<int, int> currentAttempts;

  /// Method to initialize the attempts handler.
  /// This method must be called before any other method in this class.
  Future<void> initialize() async {
    // TODO(Sosnovyy): initialize currentAttempts from prefs
    final rawPool = _prefs.getString(_kAttemptsPoolKey);
    if (rawPool == null) {
      currentAttempts = Map.from(timeoutsMap);
    } else {
      currentAttempts = json.decode(rawPool) as Map<int, int>;
    }
  }

  /// Method to add an attempt back to the current attempts pool
  Future<void> returnAttempt(int duration) async {
    if (!currentAttempts.containsKey(duration)) {
      throw CantReturnTimeoutException(
        'Wrong timeout duration provided ($duration), '
        'only ${currentAttempts.keys} are available',
      );
    }
    currentAttempts[duration] = currentAttempts[duration]! + 1;
    await _prefs.setString(_kAttemptsPoolKey, json.encode(currentAttempts));
  }

  /// Method to restore all attempts by provided config.
  Future<void> restoreAllAttempts() async {
    currentAttempts = Map.from(timeoutsMap);
    await _prefs.setString(_kAttemptsPoolKey, json.encode(currentAttempts));
  }

  /// Method to waste an attempt from the current attempts pool.
  ///
  /// Returns true there are more available attempts to test before falling into timeout.
  /// Returns false if no more attempts are available before timeout.
  Future<bool> wasteAttempt() async {
    if (!isAvailable) {
      throw const CantWasteAttemptException('No attempts available right now');
    }
    final currentAvailableDuration = currentAttempts.keys
        .where((duration) => currentAttempts[duration]! > 0)
        .reduce(math.min);
    currentAttempts[currentAvailableDuration] =
        currentAttempts[currentAvailableDuration]! - 1;
    await _prefs.setString(_kAttemptsPoolKey, json.encode(currentAttempts));
    // TODO(Sosnovyy): check if there are more attempts available and return bool
    return true;
  }

  /// Method to check if any attempt is available right now
  bool get isAvailable => currentAttempts.values.any((amount) => amount > 0);
}
