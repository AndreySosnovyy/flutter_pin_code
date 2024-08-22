import 'package:flutter_pin_code/src/errors/request_again_config_error.dart';

class PinCodeRequestAgainConfig {
  PinCodeRequestAgainConfig({
    required this.secondsBeforeRequestingAgain,
    this.onRequestAgain,
  }) {
    if (secondsBeforeRequestingAgain < 0) {
      throw const RequestAgainConfigError(
          'Variable "secondsBeforeRequestingAgain" must be positive or zero');
    }
  }

  /// Number of seconds needed to pass before requesting the pin code another time
  ///
  /// Null for disabling the feature of
  final int secondsBeforeRequestingAgain;

  /// Callback that will be called when you need to request the pin code again
  ///
  /// You are allowed to set this later after calling constructor.
  /// If this callback is not set, but there is a need to request pin again
  /// the exception will be thrown.
  ///
  /// To prevent unnecessary navigation from pin code screen to same pin code
  /// screen, you have to handle if pin code screen is shown or not on your own inside
  /// this callback or when you call onAppLifecycleStateChanged method!
  /// This is possible if user moved the app to background while still on pin
  /// code screen and then went back to foreground with "Request again" config set.
  final void Function()? onRequestAgain;

  /// Creates a copy of this object but with the given fields replaced with
  /// the new values.
  PinCodeRequestAgainConfig copyWith({
    int? secondsBeforeRequestingAgain,
    void Function()? onRequestAgain,
  }) {
    return PinCodeRequestAgainConfig(
      secondsBeforeRequestingAgain:
          secondsBeforeRequestingAgain ?? this.secondsBeforeRequestingAgain,
      onRequestAgain: onRequestAgain ?? this.onRequestAgain,
    );
  }

  @override
  String toString() {
    return 'PinCodeRequestAgainConfig('
        'secondsBeforeRequestingAgain: $secondsBeforeRequestingAgain, '
        'onRequestAgain: $onRequestAgain'
        ')';
  }
}
