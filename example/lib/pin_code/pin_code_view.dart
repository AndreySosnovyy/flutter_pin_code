import 'package:example/extensions.dart';
import 'package:example/main.dart';
import 'package:example/settings/settings_view.dart';
import 'package:flutter/material.dart';

class PinCodeView extends StatefulWidget {
  const PinCodeView({super.key});

  @override
  State<PinCodeView> createState() => _PinCodeViewState();
}

class _PinCodeViewState extends State<PinCodeView> {
  final pinCodeTextEditingController = TextEditingController();
  final pinCodeController = DI.pinCodeController;

  void showToast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN CODE'),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: pinCodeTextEditingController),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (!await pinCodeController.canTestPinCode()) return;
                final isPinCodeCorrect = await pinCodeController
                    .testPinCode(pinCodeTextEditingController.text);
                if (isPinCodeCorrect) {
                  showToast('Correct PIN CODE');
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsView(),
                    ),
                  );
                } else {
                  showToast('Wrong PIN CODE');
                }
              },
              child: const Text('Enter PIN CODE'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {},
              child: Text(
                'Biometrics (${pinCodeController.currentBiometrics.title})',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsView(),
                  ),
                );
                await pinCodeController.clear();
              },
              child: const Text('Forgot PIN CODE'),
            ),
          ],
        ),
      ),
    );
  }
}
