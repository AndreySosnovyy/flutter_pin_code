import 'package:example/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pin_code/flutter_pin_code.dart';

class DI {
  // This configuration is used in example by default
  static final refreshableTimeoutConfig = PinCodeTimeoutConfig.refreshable(
    onTimeoutEnded: () {
      print('Timeout has ended, you can test pin code now!');
    },
    onTimeoutStarted: (timeoutDuration) {
      print('Timeout has started, you must waste $timeoutDuration '
          'before it ends!');
    },
    timeouts: {0: 3, 30: 2, 60: 1},
    timeoutRefreshRatio: 1,
  );

  // You can try to change default configuration above with this one to test it
  static final notRefreshableTimeoutConfig =
      PinCodeTimeoutConfig.notRefreshable(
    onTimeoutEnded: () {
      print('Timeout has ended, you can test pin code now!');
    },
    onTimeoutStarted: (timeoutDuration) {
      print('Timeout has started, you must waste $timeoutDuration '
          'before it ends!');
    },
    timeouts: {0: 3, 30: 2, 60: 1},
    onMaxTimeoutsReached: () {
      // TODO(Sosnovyy): emulate logic and navigation
      print('Signing the user out and performing navigation '
          'to the auth screen!');
    },
  );

  // Place the controller in your DI or anywhere you think is most appropriate.
  static final pinCodeController = PinCodeController(
    timeoutConfig: refreshableTimeoutConfig,
  );
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
