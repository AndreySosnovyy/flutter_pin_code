import 'package:example/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pin_code/flutter_pin_code.dart';

class DI {
  // This configuration is used in example by default
  static final refreshableTimeoutConfig = PinCodeTimeoutConfig.refreshable(
    onTimeoutEnded: () {
      showToast('Timeout has ended, you can test pin code now!');
    },
    onTimeoutStarted: (timeoutDuration) {
      showToast('Timeout has started, you must wait $timeoutDuration '
          'before it ends!');
    },
    timeouts: {0: 3, 10: 2, 20: 1},
  );

  // You can try to change default configuration above with this one to test it
  static final notRefreshableTimeoutConfig =
      PinCodeTimeoutConfig.notRefreshable(
    onTimeoutEnded: () {
      showToast('Timeout has ended, you can test pin code now!');
    },
    onTimeoutStarted: (timeoutDuration) {
      showToast('Timeout has started, you must wait $timeoutDuration '
          'before it ends!');
    },
    // timeouts: {0: 3, 10: 2, 20: 1},
    timeouts: {0: 1},
    onMaxTimeoutsReached: () {
      showToast('Signing the user out and performing navigation '
          'to the auth screen!');
    },
  );

  // Place the controller in your DI or anywhere you think is most appropriate.
  static final pinCodeController = PinCodeController(
    // timeoutConfig: refreshableTimeoutConfig,
    timeoutConfig: DI.notRefreshableTimeoutConfig,
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
