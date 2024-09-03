class PinCodeRequestAgainConfig {
  PinCodeRequestAgainConfig({
    /// {@macro flutter_pin_code.request_again_config.seconds_before_requesting_again}
    required this.secondsBeforeRequestingAgain,

    /// {@macro flutter_pin_code.request_again_config.on_request_again}
    this.onRequestAgain,
  }) {
    assert(
      secondsBeforeRequestingAgain >= 0,
      'Variable "secondsBeforeRequestingAgain" must be positive or zero',
    );
  }

  /// {@template flutter_pin_code.request_again_config.seconds_before_requesting_again}
  /// Number of seconds needed to pass before requesting the pin code another time
  /// {@endtemplate}
  final int secondsBeforeRequestingAgain;

  /// {@template flutter_pin_code.request_again_config.on_request_again}
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
  /// {@endtemplate}
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
