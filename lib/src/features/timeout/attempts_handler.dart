import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_pin_code/src/exceptions/cant_return_timeout_exception.dart';
import 'package:flutter_pin_code/src/exceptions/cant_waste_attempt_exception.dart';
import 'package:flutter_pin_code/src/features/timeout/models/waste_attempt_response.dart';
import 'package:flutter_pin_code/src/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kAttemptsPoolKey = 'flutter_pin_code.attempts_pool';

// TODO(Sosnovyy): return one attempt after last timeout
class AttemptsHandler {
  AttemptsHandler({
    required SharedPreferences prefs,
    required this.timeoutsMap,
    required this.isRefreshable,
  }) : _prefs = prefs;

  ///
  final SharedPreferences _prefs;

  /// Type of timeout configuration.
  final bool isRefreshable;

  /// Timeouts configuration from the general config.
  final Map<int, int> timeoutsMap;

  /// Current available attempts map in <seconds, amount> format.
  late final Map<int, int> currentAttempts;

  Map<String, String> get currentAttemptsAsStringMap =>
      currentAttempts.map((k, v) => MapEntry(k.toString(), v.toString()));

  /// Method to initialize the attempts handler.
  /// This method must be called before any other method in this class.
  Future<void> initialize() async {
    final rawPool = _prefs.getString(_kAttemptsPoolKey);
    if (rawPool == null) {
      currentAttempts = Map.from(timeoutsMap);
    } else {
      currentAttempts = (json.decode(rawPool))
          .map<int, int>((k, v) => MapEntry(int.parse(k), int.parse(v)));
    }
  }

  /// Method to add an attempt back to the current attempts pool for provided duration.
  ///
  /// If duration not provided, the attempt for last duration will be returned.
  Future<void> restoreAttempt({int? duration}) async {
    if (duration == null) {
      final targetDuration = currentAttempts.keys.reduce(math.max);
      currentAttempts[targetDuration] = currentAttempts[targetDuration]! + 1;
    } else {
      if (!currentAttempts.containsKey(duration)) {
        throw CantReturnTimeoutException(
          'Wrong timeout duration provided ($duration), '
          'only ${currentAttempts.keys} are available',
        );
      }
      currentAttempts[duration] = currentAttempts[duration]! + 1;
      await _prefs.setString(
          _kAttemptsPoolKey, json.encode(currentAttemptsAsStringMap));
    }
    logger.d('One attempt was returned'
        '${duration != null ? ' for $duration timeout' : ''}');
  }

  /// Method to restore all attempts by provided config.
  Future<void> restoreAllAttempts() async {
    currentAttempts
      ..clear()
      ..addAll(Map.from(timeoutsMap));
    await _prefs.setString(
        _kAttemptsPoolKey, json.encode(currentAttemptsAsStringMap));
    logger.d('All attempts were restored');
  }

  /// Method to waste an attempt from the current atte§mpts pool.
  ///
  /// Returns true there are more available attempts to test before falling into timeout.
  /// Returns false if no more attempts are available before timeout.
  Future<WasteAttemptResponse> wasteAttempt() async {
    if (!isAvailable) {
      throw const CantWasteAttemptException('No attempts available right now');
    }
    final currentAvailableDuration = currentAttempts.keys
        .where((duration) => currentAttempts[duration]! > 0)
        .reduce(math.min);
    currentAttempts[currentAvailableDuration] =
        currentAttempts[currentAvailableDuration]! - 1;
    await _prefs.setString(
        _kAttemptsPoolKey, json.encode(currentAttemptsAsStringMap));
    final hasNextAttempts = currentAttempts.keys
        .any((duration) => duration > currentAvailableDuration);
    final amountOfAvailableAttemptsBeforeTimeout =
        currentAttempts[currentAvailableDuration]!;
    late final int? timeout;
    if (amountOfAvailableAttemptsBeforeTimeout > 0) {
      timeout = 0;
    } else {
      if (hasNextAttempts) {
        timeout = currentAttempts.keys
            .where((duration) => duration > currentAvailableDuration)
            .reduce(math.min);
      } else {
        if (isRefreshable) {
          timeout = currentAttempts.keys.last;
        } else {
          timeout = null;
        }
      }
    }
    final response = WasteAttemptResponse(
      amountOfAvailableAttemptsBeforeTimeout:
          amountOfAvailableAttemptsBeforeTimeout,
      timeoutDurationInSeconds: timeout,
      areAllAttemptsWasted: !hasNextAttempts,
    );
    logger.d(
        'An attempt was wasted. $amountOfAvailableAttemptsBeforeTimeout left '
        'before $_nextTimeoutDurationInSeconds seconds timeout.');
    return response;
  }

  /// Method to check if any attempt is available right now
  bool get isAvailable => currentAttempts.values.any((amount) => amount > 0);

  /// Returns the amount of available attempts before timeout
  ///
  /// Returns zero if no timeouts available now but they are refreshable.
  int get attemptsAmountBeforeTimeout {
    final targetDurations = currentAttempts.keys
        .where((duration) => currentAttempts[duration]! > 0);
    if (targetDurations.isEmpty) return 0;
    return currentAttempts[targetDurations.reduce(math.min)]!;
  }

  /// Returns the next timeout duration in seconds
  ///
  /// Returns null if there are no more timeouts after current attempts
  /// configured for non refreshable timeouts.
  int? get _nextTimeoutDurationInSeconds {
    final targetDurationsForCurrent = currentAttempts.keys
        .where((duration) => currentAttempts[duration]! > 0)..toList().sort();
    if (targetDurationsForCurrent.isEmpty) {
      return isRefreshable ? currentAttempts.keys.reduce(math.max) : null;
    }
    final currentAvailableDuration = targetDurationsForCurrent.first;
    if (targetDurationsForCurrent.length == 1) {
      return isRefreshable ? currentAttempts.keys.reduce(math.max) : null;
    }
    return targetDurationsForCurrent.skip(1).first;
  }

  /// Returns true if there are no more configured timeouts and the only way to
  /// test pin is to wait until same timeout ends and obtain one new attempt
  /// every time after.
  bool get isInLoop => _nextTimeoutDurationInSeconds == null;
}
