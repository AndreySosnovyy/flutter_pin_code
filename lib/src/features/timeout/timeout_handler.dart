import 'dart:ui';

import 'package:flutter_pin_code/src/errors/wrong_timeout_duration_error.dart';
import 'package:flutter_pin_code/src/exceptions/timeout_is_already_running_exception.dart';
import 'package:flutter_pin_code/src/features/timeout/timeout_refresher.dart';
import 'package:flutter_pin_code/src/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Class to handle timeouts and its related information.
class TimeoutHandler {
  TimeoutHandler({
    required SharedPreferences prefs,
    required this.onTimeoutEnded,
    required this.onTimeoutStarted,
    this.iterateInterval,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;

  /// Callback to be called when timeout has started.
  final Function(int durationInSeconds)? onTimeoutStarted;

  /// Callback to be called when timeout is ended.
  final VoidCallback? onTimeoutEnded;

  /// Event loop to handle timeout refreshing.
  late final TimeoutRefresher _refresher;

  /// {@macro iterateInterval}
  final int? iterateInterval;

  /// Method to initialize the timeout handler.
  Future<void> initialize() async {
    _refresher = TimeoutRefresher(
      prefs: _prefs,
      onTimeoutEnded: onTimeoutEnded,
      iterateInterval: iterateInterval,
    );
    await _refresher.initialize();
  }

  /// Method to start timeout when all attempts are wasted.
  void startTimeout({required int durationInSeconds}) {
    if (durationInSeconds == 0) {
      throw const WrongTimeoutDurationError('Duration must be greater than 0');
    }
    if (_refresher.currentTimeoutToBeRefreshed != null) {
      throw const TimeoutIsAlreadyRunningException(
          'Another timeout is already running. '
          'You have to wait for it to finish before starting a new one.');
    }
    onTimeoutStarted?.call(durationInSeconds);
    _refresher.setCurrentTimeout(durationInSeconds: durationInSeconds);
    logger.d('Timeout for $durationInSeconds seconds has started.');
  }

  /// Returns true if timeout is running.
  bool get isTimeoutRunning => currentTimeoutRemainingDuration != null;

  /// Method to get current timeout duration left.
  Duration? get currentTimeoutRemainingDuration {
    if (_refresher.currentTimeoutToBeRefreshed == null) return null;
    return _refresher.currentTimeoutToBeRefreshed!.expirationTimestamp
        .difference(DateTime.now());
  }

  /// Method to clear timeout from prefs.
  Future<void> clearTimeout() async => _refresher.clearTimeout();

  /// Method to dispose the timeout handler.
  Future<void> dispose() async {
    await _refresher.dispose();
  }
}
