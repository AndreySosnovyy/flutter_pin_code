import 'dart:ui';

import 'package:pin/src/exceptions/timeout_is_already_running_exception.dart';
import 'package:pin/src/features/logging/logger.dart';
import 'package:pin/src/features/timeout/timeout_refresher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// {@template flutter_pin_code.timeout_handler}
/// Class to handle timeouts and its related information.
/// {@endtemplate}
class TimeoutHandler {
  /// {@macro flutter_pin_code.timeout_handler}
  TimeoutHandler({
    required SharedPreferences prefs,
    required this.onTimeoutEnded,
    required this.onTimeoutStarted,
    required String storageKey,
    this.iterateInterval,
  })  : _prefs = prefs,
        _storageKey = storageKey;

  ///
  final String _storageKey;

  ///
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
      storageKey: _storageKey,
      onTimeoutEnded: onTimeoutEnded,
      iterateInterval: iterateInterval,
    );
    await _refresher.initialize();
  }

  /// Method to start timeout when all attempts are wasted.
  void startTimeout({required int durationInSeconds}) {
    assert(durationInSeconds > 0, 'Duration must be greater than 0');
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
  void dispose() {
    _refresher.dispose();
  }
}
