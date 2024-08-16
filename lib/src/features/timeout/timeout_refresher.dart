import 'dart:async';
import 'dart:convert';

import 'package:flutter_pin_code/src/errors/timeout_config_error.dart';
import 'package:flutter_pin_code/src/features/timeout/models/timeout_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _kDefaultIterateInterval = 30;
const int _kMaxIterateInterval = 120;

const String _kRefreshTimeoutKey = 'flutter_pin_code.timeout_to_be_refreshed';

class TimeoutRefresher {
  TimeoutRefresher({
    required SharedPreferences prefs,
    this.iterateInterval = _kDefaultIterateInterval,
  }) : _prefs = prefs {
    if (iterateInterval <= 0) {
      throw const TimeoutConfigError('iterateInterval must be greater than 0');
    } else if (iterateInterval > _kMaxIterateInterval) {
      throw const TimeoutConfigError(
          'iterateInterval is too big, max is $_kMaxIterateInterval seconds');
    }
  }

  /// Method to fetch timeouts from prefs and start the iterating timer
  ///
  /// This method must be called before any other method in this class.
  Future<void> initialize() async {
    _currentTimeoutToBeRefreshed = await _fetchRefreshTimeoutFromDisk();
    if (_currentTimeoutToBeRefreshed != null) _startIterating();
  }

  late final SharedPreferences _prefs;

  /// Interval between each iteration in seconds
  final int iterateInterval;

  /// Periodic timer for iterating to make updates
  Timer? _timer;

  /// Method to start the timer iterating to make updates
  void _startIterating() {
    _timer = Timer.periodic(
      Duration(seconds: iterateInterval),
      (_) async => _iterate(),
    );
  }

  ///
  Future<void> _iterate() async {
    // if (_refreshPool.isEmpty) return;
    // for (final timeout in _refreshPool) {
    //   if (DateTime.now().isAfter(timeout.expirationTimestamp)) {
    //     _refreshPool.remove(timeout);
    //     _refreshStreamController.add(timeout.duration);
    //     await _writeCurrentPoolToPrefs();
    //   }
    // }
    // if (_refreshPool.isEmpty) _stopLoop();
  }

  /// Method to stop the timer iterating to make updates
  void _stopIterating() {
    _timer?.cancel();
    _timer = null;
  }

  /// Method to check if the timer iterating to make updates is running
  bool get isIterating => _timer != null;

  /// Current timeout if exists. Null is there is no timeout running right now.
  Timeout? _currentTimeoutToBeRefreshed;

  /// Update the current timeout.
  Future<void> setCurrentTimeout({required int durationInSeconds}) async {
    final expirationTimestamp =
        DateTime.now().add(Duration(seconds: durationInSeconds));
    final timeout = Timeout(
      durationInSeconds: durationInSeconds,
      expirationTimestamp: expirationTimestamp,
    );
    _currentTimeoutToBeRefreshed = timeout;
    if (!isIterating) _startIterating();
    await _prefs.setString(_kRefreshTimeoutKey, json.encode(timeout.toMap()));
  }

  /// Method to write current timeout to prefs
  Future<void> _writeCurrentTimeoutToDisk() async {
    if (_currentTimeoutToBeRefreshed == null) return;
    await _prefs.setString(
        _kRefreshTimeoutKey, json.encode(_currentTimeoutToBeRefreshed!.toMap()));
  }

  /// Method to fetch current timeout from prefs
  Future<Timeout?> _fetchRefreshTimeoutFromDisk() async {
    final rawTimeout = _prefs.getString(_kRefreshTimeoutKey);
    if (rawTimeout == null) return null;
    return Timeout.fromMap(json.decode(rawTimeout));
  }

  /// Method to update timeouts in prefs. It is not necessary to call, but recommended.
  Future<void> dispose() async {
    _stopIterating();
    await _writeCurrentTimeoutToDisk();
  }
}
