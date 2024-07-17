import 'package:example/app.dart';
import 'package:example/pin_code/pin_code_view_controller.dart';
import 'package:example/settings/settings_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pin_code/flutter_pin_code.dart';

class DI {
  static final _requestAgainConfig = PinCodeRequestAgainConfig(
    secondsBeforeRequestingAgain: 30,
  );
  static final _refreshableTimeoutConfig = PinCodeTimeoutConfig.refreshable(
    onTimeoutEnd: () {
      // Place your logic here
      print('Notify user about timeout ending!');
    },
    timeouts: {0: 3, 60: 2, 360: 1},
    timeoutRefreshRatio: 10,
  );
  static final _notRefreshableTimeoutConfig =
      PinCodeTimeoutConfig.notRefreshable(
    onTimeoutEnd: () {
      // Place your logic here
      print('Notify user about timeout ending!');
    },
    timeouts: {0: 3, 60: 2, 360: 1},
    onMaxTimeoutsReached: () {
      // Place your logic here
      print('Sign the user out and navigate him to auth screen!');
    },
  );
  // Place the controller in your DI or anywhere you think is most appropriate.
  static final pinCodeController = PinCodeController(
    requestAgainConfig: _requestAgainConfig,
    // timeoutConfig: _refreshableTimeoutConfig,
  );

  // Use any state management you prefer in your project. This is just a simple example.
  static final pinCodeViewController = PinCodeViewController();
  static final settingsViewController = SettingsViewController();
}

void main() async {
  // Initialize pin code controller!
  await DI.pinCodeController.initialize(
    doInitialBiometricTestIfSet: true,
    fingerprintReason: 'Touch the fingerprint sensor',
    faceIdReason: 'Look at the camera',
  );

  // Other initialization
  await DI.pinCodeViewController.initialize();
  await DI.settingsViewController.initialize();

  runApp(const PinCodeApp());
}
