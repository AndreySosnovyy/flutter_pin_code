import 'package:flutter/services.dart';
import 'package:flutter_pin_code/src/errors/no_on_max_timeouts_reached_callback_provided.dart';

const int kPinCodeMaxTimeout = 21600;

typedef OnTimeoutStartedCallback = Function(Duration timeoutDuration);

class PinCodeTimeoutConfig {
  PinCodeTimeoutConfig._({
    required this.onTimeoutEnded,
    required this.onTimeoutStarted,
    VoidCallback? onMaxTimeoutsReached,
    required this.timeouts,
  }) : _onMaxTimeoutsReached = onMaxTimeoutsReached;

  /// Creates PinCodeTimeoutConfig with refreshable timeouts
  factory PinCodeTimeoutConfig.refreshable({
    required Map<int, int> timeouts,
    VoidCallback? onTimeoutEnded,
    OnTimeoutStartedCallback? onTimeoutStarted,
  }) {
    return PinCodeTimeoutConfig._(
      onTimeoutEnded: onTimeoutEnded,
      onTimeoutStarted: onTimeoutStarted,
      onMaxTimeoutsReached: null,
      timeouts: timeouts,
    );
  }

  /// Creates PinCodeTimeoutConfig with not refreshable timeouts
  factory PinCodeTimeoutConfig.notRefreshable({
    required Map<int, int> timeouts,
    required VoidCallback onMaxTimeoutsReached,
    VoidCallback? onTimeoutEnded,
    OnTimeoutStartedCallback? onTimeoutStarted,
  }) {
    return PinCodeTimeoutConfig._(
      onTimeoutEnded: onTimeoutEnded,
      onTimeoutStarted: onTimeoutStarted,
      onMaxTimeoutsReached: onMaxTimeoutsReached,
      timeouts: timeouts,
    );
  }

  /// Callback which shoots after current timeout is over.
  ///
  /// Can be used to update UI or notify user.
  VoidCallback? onTimeoutEnded;

  /// Callback which shoots after a timeout has started.
  ///
  /// Can be used to update UI or notify user.
  OnTimeoutStartedCallback? onTimeoutStarted;

  /// {@template onMaxTimeoutsReached}
  /// Callback which shoots after all timeouts are over and they are not refreshable.
  ///
  /// Can be used to notify the user that he used all attempts,
  /// sign him out and send back to authorization screen.
  ///
  /// This method will never be called if timeouts are refreshable.
  /// {@endtemplate}
  VoidCallback? _onMaxTimeoutsReached;

  /// {@macro onMaxTimeoutsReached}
  VoidCallback? get onMaxTimeoutsReached => _onMaxTimeoutsReached;

  /// {@macro onMaxTimeoutsReached}
  set onMaxTimeoutsReached(VoidCallback? value) {
    if (!isRefreshable && value == null) {
      throw const NoOnMaxTimeoutsReachedCallbackProvided(
          'No onMaxTimeoutsReached callback provided '
          'but the configuration is refreshable and must have it');
    }
    _onMaxTimeoutsReached = value;
  }

  /// Map containing number of tries before every timeout
  /// where key is number of seconds and value is number of tries.
  ///
  /// If all timeouts are over and they are not refreshable,
  /// then onMaxTimeoutsReached will be called.
  ///
  /// If timeouts are refreshable and the last configured timeout is over, user
  /// will get one attempt at a time. This logic will repeat infinitely!
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

  /// Returns true if timeouts are configured to be refreshable.
  bool get isRefreshable => onMaxTimeoutsReached != null;

  @override
  String toString() {
    return 'PinCodeTimeoutConfig('
        'onTimeoutEnd: $onTimeoutEnded, '
        'onMaxTimeoutsReached: $onMaxTimeoutsReached, '
        'timeouts: $timeouts, '
        ')';
  }
}
