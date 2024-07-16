import 'package:flutter/services.dart';

const int kPinCodeMaxTimeout = 21600;
const int kPinCodeMaxRefreshRatio = 100;

class PinCodeTimeoutConfig {
  PinCodeTimeoutConfig._({
    required this.onTimeoutEnd,
    required this.onMaxTimeoutsReached,
    required this.timeouts,
    required this.timeoutRefreshRatio,
  });

  /// Creates PinCodeTimeoutConfig with refreshable timeouts
  factory PinCodeTimeoutConfig.refreshable({
    required Map<int, int> timeouts,
    required VoidCallback onTimeoutEnd,
    required int timeoutRefreshRatio,
  }) {
    return PinCodeTimeoutConfig._(
      onTimeoutEnd: onTimeoutEnd,
      onMaxTimeoutsReached: null,
      timeouts: timeouts,
      timeoutRefreshRatio: timeoutRefreshRatio,
    );
  }

  /// Creates PinCodeTimeoutConfig with not refreshable timeouts
  factory PinCodeTimeoutConfig.notRefreshable({
    required Map<int, int> timeouts,
    required VoidCallback onTimeoutEnd,
    required VoidCallback onMaxTimeoutsReached,
  }) {
    return PinCodeTimeoutConfig._(
      onTimeoutEnd: onTimeoutEnd,
      onMaxTimeoutsReached: onMaxTimeoutsReached,
      timeouts: timeouts,
      timeoutRefreshRatio: null,
    );
  }

  /// Callback which shoots after current timeout is over.
  ///
  /// Can be used to update UI or notify user
  final VoidCallback onTimeoutEnd;

  /// Callback which shoots after all timeouts are over and they are not refreshable.
  ///
  /// Can be used to notify the user that he used all attempts,
  /// sign him out and send back to authorization screen.
  ///
  /// This method will never be called if timeouts are refreshable.
  final VoidCallback? onMaxTimeoutsReached;

  /// Map containing number of tries before every timeout
  /// where key is number of seconds and value is number of tries.
  /// If all timeouts are over and they are not refreshable,
  /// then onMaxTimeoutsReached will be called.
  ///
  /// Max value is 21600 ([kPinCodeMaxTimeout]) seconds.
  ///
  /// Example:
  /// {
  ///   0: 3, // initially you have 3 tries before falling into 60 seconds timeout
  ///   60: 2, // another 2 tries after 60 seconds timeout
  ///   600: 1, // another final try after 600 seconds timeout
  /// }
  final Map<int, int> timeouts;

  /// Ratio applied to number of seconds for each timeout to refresh it.
  /// Max value is 100 ([kPinCodeMaxRefreshRatio]).
  ///
  /// Initial tries will be updated together after closest timeout to them.
  ///
  /// If null or 0 - timeouts are not refreshable and
  /// onMaxTimeoutsReached will be called when they are over.
  ///
  /// Example:
  /// If timeoutRefreshRatio is 10 and timeouts map is {0: 3, 60: 2} than
  /// after wasting initial tries and both tries after 60 seconds the next
  /// available try will refresh after 600 seconds.
  final int? timeoutRefreshRatio;

  /// Returns true if timeouts are configured to be refreshable.
  bool get isRefreshable => timeoutRefreshRatio != null;

  @override
  String toString() {
    return 'PinCodeTimeoutConfig('
        'onTimeoutEnd: $onTimeoutEnd, '
        'onMaxTimeoutsReached: $onMaxTimeoutsReached, '
        'timeouts: $timeouts, '
        'timeoutRefreshRatio: $timeoutRefreshRatio'
        ')';
  }
}
