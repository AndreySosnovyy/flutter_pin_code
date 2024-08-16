import 'package:flutter/foundation.dart';

// TODO(Sosnovyy): add copyWith method (needed in case you want to change callbacks)
class PinCodeRequestAgainConfig {
  PinCodeRequestAgainConfig({
    required this.secondsBeforeRequestingAgain,
    this.onRequestAgain,
  });

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
  VoidCallback? onRequestAgain;

  @override
  String toString() {
    return 'PinCodeRequestAgainConfig('
        'secondsBeforeRequestingAgain: $secondsBeforeRequestingAgain, '
        'onRequestAgain: $onRequestAgain'
        ')';
  }
}
