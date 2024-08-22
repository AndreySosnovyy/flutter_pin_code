import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_pin_code/src/errors/no_on_max_timeouts_reached_callback_provided.dart';
import 'package:flutter_pin_code/src/errors/timeout_config_error.dart';

const int kPinCodeMaxTimeout = 21600;

typedef OnTimeoutStartedCallback = Function(Duration timeoutDuration);

class PinCodeTimeoutConfig {
  PinCodeTimeoutConfig._({
    required this.onTimeoutEnded,
    required this.onTimeoutStarted,
    VoidCallback? onMaxTimeoutsReached,
    required this.timeouts,
    required this.isRefreshable,
  }) : _onMaxTimeoutsReached = onMaxTimeoutsReached {
    if (timeouts.isEmpty) {
      throw const TimeoutConfigError('Variable "timeouts" cannot be empty');
    }
    if (timeouts.keys.reduce(math.min) < 0) {
      throw const TimeoutConfigError('Timeout cannot be negative');
    }
    if (timeouts.values.reduce(math.min) < 0) {
      throw const TimeoutConfigError('Number of tries cannot be negative');
    }
    if (timeouts.keys.contains(0)) {
      throw const TimeoutConfigError('First timeout must be 0');
    }
    if (timeouts.length < 2) {
      throw const TimeoutConfigError(
          'Number of entries in timeout configuration must be at least 2');
    }
    if (timeouts.length != timeouts.keys.toSet().length) {
      throw const TimeoutConfigError('Timeouts must be unique');
    }
    if (timeouts.keys.reduce(math.max) > kPinCodeMaxTimeout) {
      throw const TimeoutConfigError(
          'Max timeout is $kPinCodeMaxTimeout seconds');
    }
  }

  /// Creates PinCodeTimeoutConfig with refreshable timeouts
  factory PinCodeTimeoutConfig.refreshable({
    required Map<int, int> timeouts,
    VoidCallback? onTimeoutEnded,
    OnTimeoutStartedCallback? onTimeoutStarted,
  }) {
    return PinCodeTimeoutConfig._(
      isRefreshable: true,
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
      isRefreshable: false,
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
  /// The first timeout duration is always 0!
  ///
  /// The order is not important but it's easier to understand if you put
  /// timeouts in direct order. The important factor is timeout duration:
  /// shorter timeout can not be used after a longer one. It will always go
  /// one by one depending on current timeout duration starting from 0.
  ///
  /// Example:
  /// {
  ///   0: 3, // initially you have 3 tries before falling into 60 seconds timeout
  ///   60: 2, // another 2 tries after 60 seconds timeout
  ///   600: 1, // another final try after 600 seconds timeout
  /// }
  final Map<int, int> timeouts;

  /// Returns true if timeouts are configured to be refreshable.
  final bool isRefreshable;

  @override
  String toString() {
    return 'PinCodeTimeoutConfig('
        'onTimeoutEnd: $onTimeoutEnded, '
        'onMaxTimeoutsReached: $onMaxTimeoutsReached, '
        'timeouts: $timeouts, '
        'isRefreshable: $isRefreshable, '
        ')';
  }
}
