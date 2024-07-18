import 'package:example/main.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final pinCodeTextEditingController = TextEditingController();
  final pinCodeController = DI.pinCodeController;

  void showToast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: pinCodeTextEditingController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (pinCodeTextEditingController.text.length != 4) {
                  showToast('PIN CODE must be 4 digits');
                } else {
                  print('111111111111111111111111111111111111111111111111');
                  await pinCodeController
                      .setPinCode(pinCodeTextEditingController.text);
                  showToast('PIN CODE set');
                }
              },
              child: const Text('Set PIN CODE'),
            ),
          ],
        ),
      ),
    );
  }
}
