import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_pin_code/src/errors/timeout_config_error.dart';
import 'package:flutter_pin_code/src/features/logging/logger.dart';
import 'package:flutter_pin_code/src/features/timeout/models/timeout_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _kDefaultIterateInterval = 30;
const int _kMaxIterateInterval = 120;

const String _kRefreshTimeoutKey = 'flutter_pin_code.timeout_to_be_refreshed';

// TODO(Sosnovyy): refactor from periodic timer to a normal one
/// Class is responsible for storing, refreshing timeouts and notifying
/// TimeoutHandler about timeout events.
class TimeoutRefresher {
  TimeoutRefresher({
    required SharedPreferences prefs,
    required this.onTimeoutEnded,
    int? iterateInterval,
  }) : _prefs = prefs {
    _iterateInterval = iterateInterval ?? _kDefaultIterateInterval;
    if (_iterateInterval <= 0) {
      throw const TimeoutConfigError('iterateInterval must be greater than 0');
    } else if (_iterateInterval > _kMaxIterateInterval) {
      throw const TimeoutConfigError(
          'iterateInterval is too big, max is $_kMaxIterateInterval seconds');
    }
  }

  /// Method to fetch timeouts from prefs and start the iterating timer.
  ///
  /// This method must be called before any other method in this class.
  Future<void> initialize() async {
    currentTimeoutToBeRefreshed = await _fetchRefreshTimeoutFromDisk();
    if (currentTimeoutToBeRefreshed != null) _startIterating();
  }

  late final SharedPreferences _prefs;

  /// {@macro flutter_pin_code.timeout_refresher.iterate_interval}
  late final int _iterateInterval;

  /// Callback to be called when the timeout is over and refreshed.
  final VoidCallback? onTimeoutEnded;

  /// Periodic timer for iterating to make updates.
  Timer? _timer;

  /// Method to start the timer iterating to make updates.
  void _startIterating() {
    _timer = Timer.periodic(
      Duration(seconds: _iterateInterval),
      (_) async => _iterate(),
    );
  }

  /// Main method to iterate and check if the timeout should be refreshed.
  Future<void> _iterate() async {
    if (currentTimeoutToBeRefreshed == null) return _stopIterating();
    final timeout = currentTimeoutToBeRefreshed!;
    if (DateTime.now().isAfter(timeout.expirationTimestamp)) {
      currentTimeoutToBeRefreshed = null;
      onTimeoutEnded?.call();
      await _writeCurrentTimeoutToDisk();
      _stopIterating();
      logger.d('Timeout is over.');
    }
  }

  /// Method to stop the timer iterating to make updates.
  void _stopIterating() {
    _timer?.cancel();
    _timer = null;
  }

  /// Method to check if the timer iterating to make updates is running.
  bool get isIterating => _timer != null;

  /// Current timeout if exists. Null is there is no timeout running right now.
  Timeout? currentTimeoutToBeRefreshed;

  /// Update the current timeout.
  Future<void> setCurrentTimeout({required int durationInSeconds}) async {
    final expirationTimestamp =
        DateTime.now().add(Duration(seconds: durationInSeconds));
    final timeout = Timeout(
      durationInSeconds: durationInSeconds,
      expirationTimestamp: expirationTimestamp,
    );
    currentTimeoutToBeRefreshed = timeout;
    if (!isIterating) _startIterating();
    await _writeCurrentTimeoutToDisk();
  }

  /// Method to write current timeout to prefs.
  Future<void> _writeCurrentTimeoutToDisk() async {
    if (currentTimeoutToBeRefreshed == null) {
      await _prefs.remove(_kRefreshTimeoutKey);
    } else {
      await _prefs.setString(_kRefreshTimeoutKey,
          json.encode(currentTimeoutToBeRefreshed!.toMap()));
    }
  }

  /// Method to fetch current timeout from prefs.
  Future<Timeout?> _fetchRefreshTimeoutFromDisk() async {
    final rawTimeout = _prefs.getString(_kRefreshTimeoutKey);
    if (rawTimeout == null) return null;
    return Timeout.fromMap(json.decode(rawTimeout));
  }

  /// Method to clear timeout.
  Future<void> clearTimeout() async {
    currentTimeoutToBeRefreshed = null;
    _stopIterating();
    await _prefs.remove(_kRefreshTimeoutKey);
    logger.d('Timeout was cleared.');
  }

  /// Method to dispose the timer.
  void dispose() {
    _stopIterating();
  }
}
