import 'package:example/main.dart';
import 'package:example/pin_code_view.dart';
import 'package:flutter/material.dart';

class PinCodeApp extends StatefulWidget {
  const PinCodeApp({super.key});

  @override
  State<PinCodeApp> createState() => _PinCodeAppState();
}

class _PinCodeAppState extends State<PinCodeApp> with WidgetsBindingObserver {
  void showToast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (DI.pinCodeController.requestAgainConfig != null) {
      DI.pinCodeController.requestAgainConfig!.onRequestAgain = () {
        final navigator = Navigator.of(context);
        if (!navigator.canPop()) return;
        navigator
          ..popUntil((route) => route.isFirst)
          ..pushReplacement(MaterialPageRoute(
            builder: (context) => const PinCodeView(),
          ));
        showToast('Requesting again called');
      };
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DI.pinCodeController.onAppLifecycleStateChanged(state);
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PinCodeView(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
