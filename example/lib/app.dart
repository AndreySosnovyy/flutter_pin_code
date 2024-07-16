import 'package:example/main.dart';
import 'package:example/pin_code/pin_code_view.dart';
import 'package:flutter/material.dart';

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
