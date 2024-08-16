import 'package:flutter_pin_code/src/features/timeout/timeout_refresher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Class to handle timeouts and its related information.
class TimeoutHandler {
  TimeoutHandler({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;

  /// Event loop to handle timeout refreshing.
  late final TimeoutRefresher _eventLoop;

  /// Method to initialize the timeout handler.
  Future<void> initialize() async {
    _eventLoop = TimeoutRefresher(prefs: _prefs);
    await _eventLoop.initialize();
  }

  /// Returns true if timeout is running.
  bool get isTimeoutRunning => currentTimeoutRemainingDuration != null;

  /// Method to get current timeout duration left.
  Duration? get currentTimeoutRemainingDuration {
    throw UnimplementedError();
  }
}
