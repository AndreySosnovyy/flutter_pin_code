import 'package:example/app.dart';
import 'package:example/main.dart';
import 'package:example/settings_view.dart';
import 'package:flutter/material.dart';

class PinCodeView extends StatefulWidget {
  const PinCodeView({super.key});

  @override
  State<PinCodeView> createState() => _PinCodeViewState();
}

// TODO(Sosnovyy): display timeout timer duration
class _PinCodeViewState extends State<PinCodeView> {
  final pinCodeTextEditingController = TextEditingController();
  final pinCodeController = DI.pinCodeController;

  void navigateToSettings() {
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsView(
          setPinViewState: updateView,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pinCodeController.isPinCodeSet) return;
      if (!context.mounted) return;
      navigateToSettings();

      // You can update onMaxTimeoutsReached callback from anywhere!
      DI.pinCodeController.timeoutConfig?.onMaxTimeoutsReached = () {
        showToast('Signing the user out and performing navigation '
            'to the auth screen!');
        updateView();
        navigateToSettings();
      };
    });
  }

  void updateView() {
    if (!context.mounted) return;
    pinCodeTextEditingController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN CODE'),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: pinCodeController.isPinCodeSet
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: pinCodeTextEditingController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      if (pinCodeController.isTimeoutRunning) {
                        return showToast('You must wait for timeout to end');
                      }
                      if (!await pinCodeController.canTestPinCode()) {
                        return showToast('You can\'t test PIN CODE now');
                      }
                      final isPinCodeCorrect = await pinCodeController
                          .testPinCode(pinCodeTextEditingController.text);
                      if (isPinCodeCorrect) {
                        showToast('Correct PIN CODE');
                        if (!context.mounted) return;
                        navigateToSettings();
                      } else {
                        showToast('Wrong PIN CODE');
                      }
                    },
                    child: const Text('Enter PIN CODE'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (!pinCodeController.isBiometricsSet) {
                        showToast('Biometrics is not set');
                      } else {
                        final result = await pinCodeController.testBiometrics(
                          fingerprintReason: 'Touch fingerprint scanner',
                          faceIdReason: 'Look in the camera',
                        );
                        if (result) {
                          showToast(
                              'Successfully authenticated with biometrics');
                          navigateToSettings();
                        } else {
                          showToast('Failed to authenticate with biometrics');
                        }
                      }
                    },
                    child: Text(
                      'Biometrics (${pinCodeController.currentBiometrics.title})',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      navigateToSettings();
                      await pinCodeController.clear();
                    },
                    child: const Text('I forgot PIN CODE'),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pin code is not set!'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => navigateToSettings(),
                      child: const Text('Go to Settings'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }


}
