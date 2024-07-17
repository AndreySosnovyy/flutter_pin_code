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
    // TODO(Sosnovyy): return one attempt with specified duration
  }

  /// Method to waste an attempt from the current attempts pool
  void wasteAttempt() {
    // TODO(Sosnovyy): waste one attempt
  }

  /// Method to check if any attempt is available right now
  // TODO(Sosnovyy): implement method
  bool get isAvailable => throw UnimplementedError();
}
