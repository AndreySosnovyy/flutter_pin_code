import 'package:flutter/material.dart';

class PinCodeRequestAgainConfig {
  const PinCodeRequestAgainConfig({
    required this.secondsBeforeRequestingAgain,
    required this.onAppLifecycleStateChanged,
  });

  /// Number of seconds needed to pass before requesting the pin code another time
  ///
  /// Null for disabling the feature of
  final int secondsBeforeRequestingAgain;

  /// App lifecycle state changes handler
  /// TODO(Sosnovyy): add example on how to provide updates
  final Function(AppLifecycleState state) onAppLifecycleStateChanged;
}
