import 'package:flutter_pin_code/src/errors/invalid_skip_config_error.dart';

const String _kDurationInMillisecondsMapKey = 'durationInMilliseconds';
const String _kForcedForRequestAgainMapKey = 'forcedForRequestAgain';

// TODO(Sosnovyy): implement skips amount limit
/// Configuration file for Skip Pin feature.
/// This feature gives the ability to avoid entering pin code for some time
/// after user has entered it before.
///
/// The first pin code can not be skipped!
class SkipPinCodeConfig {
  SkipPinCodeConfig({
    required this.duration,
    this.forcedForRequestAgain = true,
  }) {
    SkipConfigUtils._validate(duration: duration);
  }

  /// Duration whilst pin code can be skipped.
  /// Pay attention that you can still force the user to enter pin code even if
  /// skip duration is configured and active.
  ///
  /// Max skip duration is 30 minutes!
  final Duration duration;

  /// Whether to always force user to enter pin code for Request Again.
  ///
  /// If false, user will be able to enter the app back without entering pin
  /// code for specified [duration].
  final bool forcedForRequestAgain;

  /// Creates a copy of the current [SkipPinCodeConfig] with the given duration
  SkipPinCodeConfig copyWith({
    Duration? duration,
  }) {
    if (duration != null) SkipConfigUtils._validate(duration: duration);
    return SkipPinCodeConfig(
      duration: duration ?? this.duration,
    );
  }

  @override
  String toString() => 'SkipPinConfig('
      'duration: $duration, '
      'forcedForRequestAgain: $forcedForRequestAgain'
      ')';
}

class SkipConfigUtils {
  static SkipPinCodeConfig fromMap(Map<String, dynamic> map) {
    final duration =
        Duration(milliseconds: map[_kDurationInMillisecondsMapKey]);
    final forcedForRequestAgain = map[_kForcedForRequestAgainMapKey];
    _validate(duration: duration);
    return SkipPinCodeConfig(
      duration: duration,
      forcedForRequestAgain: forcedForRequestAgain,
    );
  }

  /// Converts [SkipPinCodeConfig] to a map.
  static Map<String, dynamic> toMap(SkipPinCodeConfig config) => {
        _kDurationInMillisecondsMapKey: config.duration.inMilliseconds,
        _kForcedForRequestAgainMapKey: config.forcedForRequestAgain,
      };

  /// Validation method for [SkipPinCodeConfig] which throws errors.
  static void _validate({required Duration duration}) {
    if (duration.inMinutes > 30) {
      throw const InvalidSkipConfigError('Max skip duration is 30 minutes');
    }
    if (duration.isNegative) {
      throw const InvalidSkipConfigError('Duration must be positive');
    }
  }
}
