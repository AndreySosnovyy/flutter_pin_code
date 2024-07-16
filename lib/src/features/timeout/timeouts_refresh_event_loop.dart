import 'dart:async';
import 'dart:convert';

import 'package:flutter_pin_code/src/errors/timeout_config_error.dart';
import 'package:flutter_pin_code/src/features/timeout/timeout_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _kDefaultIterateInterval = 30;
const int _kMaxIterateInterval = 120;

const String _kRefreshPoolKey = 'flutter_pin_code.refresh_pool';

// TODO(Sosnovyy): test write to prefs and fetch from prefs methods before main tests
class TimeoutsRefreshEventLoop {
  TimeoutsRefreshEventLoop({
    required SharedPreferences prefs,
    this.iterateInterval = _kDefaultIterateInterval,
  }) : _prefs = prefs {
    if (iterateInterval <= 0) {
      throw const TimeoutConfigError(
          'iterateInterval must be greater than 0');
    } else if (iterateInterval > _kMaxIterateInterval) {
      throw const TimeoutConfigError(
          'iterateInterval is too big, max is $_kMaxIterateInterval seconds');
    }
  }

  /// Method to fetch timeouts from prefs and start the loop.
  ///
  /// This method must be called before any other method in this class.
  Future<void> initialize() async {
    _refreshPool.addAll(await _fetchRefreshPool());
    if (_refreshPool.isNotEmpty) _startLoop();
  }

  late final SharedPreferences _prefs;

  /// Interval between each iteration in seconds
  final int iterateInterval;

  /// Periodic timer for iterating the loop through timeouts pool
  Timer? _timer;

  /// Method to start the timer iterating the loop
  void _startLoop() {
    _timer = Timer.periodic(
      Duration(seconds: iterateInterval),
      (_) async => _iterateLoop(),
    );
  }

  /// Method to stop the timer iterating the loop
  void _stopLoop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Method to check if the timer iterating the loop is running
  bool get isLoopRunning => _timer != null;

  // TODO(Sosnovyy): optimize by using a queue or sorted list
  /// List of timeouts to be refreshed.
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
    if (!isLoopRunning) _startLoop();
    final rawPool = _prefs.getString(_kRefreshPoolKey);
    await _prefs.setString(_kRefreshPoolKey,
        '${rawPool == null ? '' : '$rawPool,'}${json.encode(timeout.toMap())}');
  }

  /// Main handler of the loop
  Future<void> _iterateLoop() async {
    if (_refreshPool.isEmpty) return;
    for (final timeout in _refreshPool) {
      if (DateTime.now().isAfter(timeout.expirationTimestamp)) {
        _refreshPool.remove(timeout);
        _refreshStreamController.add(timeout.duration);
        await _writeCurrentPoolToPrefs();
      }
    }
    if (_refreshPool.isEmpty) _stopLoop();
  }

  /// Method to write current pool to prefs
  Future<void> _writeCurrentPoolToPrefs() async {
    await _prefs.setString(_kRefreshPoolKey, _refreshPool.toString());
  }

  /// Method to fetch timeouts from prefs
  Future<List<Timeout>> _fetchRefreshPool() async {
    final rawPool = _prefs.getString(_kRefreshPoolKey);
    if (rawPool == null) return [];
    return (json.decode(rawPool) as List)
        .map((e) => Timeout.fromMap(e))
        .toList();
  }

  /// Method to update timeouts in prefs. It is not necessary to call, but recommended.
  Future<void> dispose() async {
    _stopLoop();
    await _writeCurrentPoolToPrefs();
  }
}
