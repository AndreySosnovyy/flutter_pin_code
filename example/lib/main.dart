import 'package:example/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pin_code/flutter_pin_code.dart';

class DI {
  static final refreshableTimeoutConfig = PinCodeTimeoutConfig.refreshable(
    onTimeoutEnd: () {
      // Place your logic here
      print('Notify user about timeout ending if needed!');
    },
    timeouts: {0: 3, 60: 2, 360: 1},
    timeoutRefreshRatio: 10,
  );

  static final notRefreshableTimeoutConfig =
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
  static final pinCodeController = PinCodeController();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize pin code controller!
  await DI.pinCodeController.initialize(
    fingerprintReason: 'Touch the fingerprint sensor',
    faceIdReason: 'Look at the camera',
  );

  runApp(const PinCodeApp());
}
