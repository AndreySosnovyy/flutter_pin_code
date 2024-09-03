import 'package:example/main.dart';
import 'package:example/pin_code_view.dart';
import 'package:example/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:pin/pin.dart';

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
    if (DI.pinCodeController.requestAgainConfig == null) return;
    // You have also to set the callback on app start for Request again feature
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DI.pinCodeController.setRequestAgainConfig(DI
          .pinCodeController.requestAgainConfig!
          .copyWith(onRequestAgain: requestAgainCallback));
    });
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

extension BiometricsTypeExtension on BiometricsType {
  String get title {
    switch (this) {
      case BiometricsType.none:
        return 'None';
      case BiometricsType.face:
        return 'Face ID';
      case BiometricsType.fingerprint:
        return 'Fingerprint';
    }
  }
}