import 'dart:async';
import 'dart:convert';

import 'package:flutter_pin_code/src/exceptions/configuration/timeout_config_exception.dart';
import 'package:flutter_pin_code/src/features/timeout/timeout_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _kDefaultIterateInterval = 30;
const int _kMaxIterateInterval = 120;

const String _kRefreshPoolKey = 'flutter_pin_code.refresh_pool';

class TimeoutEventLoop {
  TimeoutEventLoop({
    required SharedPreferences prefs,
    this.iterateInterval = _kDefaultIterateInterval,
  }) : _prefs = prefs {
    if (iterateInterval <= 0) {
      throw const TimeoutConfigException(
          'iterateInterval must be greater than 0');
    } else if (iterateInterval > _kMaxIterateInterval) {
      throw const TimeoutConfigException(
          'iterateInterval is too big, max is $_kMaxIterateInterval seconds');
    }
  }

  /// Method to fetch timeouts from prefs and start the loop.
  ///
  /// This method must be called before any other method in this class.
  Future<void> initialize() async {
    // TODO(Sosnovyy): fetch timeouts from prefs and fill the pool
    _timer = Timer.periodic(
      Duration(seconds: iterateInterval),
      (timer) async => _iterateLoop(),
    );
  }

  late final SharedPreferences _prefs;

  /// Interval between each iteration in seconds
  final int iterateInterval;

  /// Periodic timer for iterating the loop through timeouts pool
  late final Timer _timer;

  /// List of timeouts to be refreshed. Sorted by expiration time.
  final _refreshPool = <Timeout>[];

  /// Stream controller of refreshed timeout events
  final _refreshStreamController = StreamController<int>();

  /// Stream of refreshed timeout events
  Stream<int> get refreshStream => _refreshStreamController.stream;

  /// Method to add timeout to the pool
  Future<void> addTimeout({required int duration}) async {
    final expirationTimestamp = DateTime.now().add(Duration(seconds: duration));
    final timeout = Timeout(
      duration: duration,
      expirationTimestamp: expirationTimestamp,
    );
    _refreshPool.add(timeout);
    final rawPool = _prefs.getString(_kRefreshPoolKey);
    await _prefs.setString(
        _kRefreshPoolKey, '${rawPool ?? ''},${json.encode(timeout.toMap())}');
  }

  /// Main handler of the loop
  Future<void> _iterateLoop() async {
    if (_refreshPool.isEmpty) return;
  }

  /// Method to update timeouts in prefs
  Future<void> dispose() async {
    _timer.cancel();
    // TODO(Sosnovyy): save timeouts to prefs
  }
}
