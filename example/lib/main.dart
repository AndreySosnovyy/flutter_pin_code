import 'package:example/app.dart';
import 'package:flutter/material.dart';
import 'package:pin/pin.dart';

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
    timeouts: {0: 3, 10: 2, 20: 1},
    onMaxTimeoutsReached: () {
      showToast('Signing the user out and performing navigation '
          'to the auth screen!');
    },
  );

  // Place the controller in your DI or anywhere you think is most appropriate.
  static final pinCodeController = PinCodeController(
    timeoutConfig: refreshableTimeoutConfig,
    iterateInterval: 5,
    logsEnabled: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize pin code controller!
  await DI.pinCodeController.initialize();
  runApp(const PinCodeApp());
}
