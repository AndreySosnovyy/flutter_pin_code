import 'package:example/main.dart';
import 'package:example/pin_code_view.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showToast(String message) => scaffoldMessengerKey.currentState!
    .showSnackBar(SnackBar(content: Text(message)));

class PinCodeApp extends StatefulWidget {
  const PinCodeApp({super.key});

  @override
  State<PinCodeApp> createState() => _PinCodeAppState();
}

class _PinCodeAppState extends State<PinCodeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (DI.pinCodeController.requestAgainConfig != null) {
      DI.pinCodeController.requestAgainConfig =
          DI.pinCodeController.requestAgainConfig!.copyWith(onRequestAgain: () {
        final navigator = navigatorKey.currentState!;
        if (!navigator.canPop()) return;
        navigator
          ..popUntil((route) => route.isFirst)
          ..pushReplacement(MaterialPageRoute(
            builder: (context) => const PinCodeView(),
          ));
        showToast('Requesting again called');
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DI.pinCodeController.onAppLifecycleStateChanged(state);
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const PinCodeView(),
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
