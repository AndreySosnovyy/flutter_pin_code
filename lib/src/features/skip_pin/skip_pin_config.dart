const String _kDurationInMillisecondsMapKey = 'durationInMilliseconds';
const String _kForcedForRequestAgainMapKey = 'forcedForRequestAgain';

/// {@template flutter_pin_code.skip_pin_config}
/// Configuration file for Skip Pin feature.
/// This feature gives the ability to avoid entering pin code for some time
/// after user has entered it before.
///
/// The first pin code can not be skipped!
/// {@endtemplate}
class SkipPinCodeConfig {
  /// {@macro flutter_pin_code.skip_pin_config}
  SkipPinCodeConfig({
    /// {@macro flutter_pin_code.skip_pin_config.duration}
    required this.duration,

    /// {@macro flutter_pin_code.skip_pin_config.forced_for_request_again}
    this.forcedForRequestAgain = true,
  }) {
    SkipConfigUtils._validate(duration: duration);
  }

  /// {@template flutter_pin_code.skip_pin_config.duration}
  /// Duration whilst pin code can be skipped.
  /// Pay attention that you can still force the user to enter pin code even if
  /// skip duration is configured and active.
  ///
  /// Max skip duration is 30 minutes!
  /// {@endtemplate}
  final Duration duration;

  /// {@template flutter_pin_code.skip_pin_config.forced_for_request_again}
  /// Whether to always force user to enter pin code for Request Again.
  ///
  /// If false, user will be able to enter the app back without entering pin
  /// code for specified [duration].
  /// {@endtemplate}
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

///
class SkipConfigUtils {
  ///
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
    assert(duration.inMinutes <= 30, 'Max skip duration is 30 minutes');
    assert(!duration.isNegative, 'Duration must be positive and non-zero');
  }
}
