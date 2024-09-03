import 'package:example/app.dart';
import 'package:example/main.dart';
import 'package:example/pin_code_view.dart';
import 'package:flutter/material.dart';
import 'package:pin/pin.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    required this.setPinViewState,
    super.key,
  });

  final VoidCallback setPinViewState;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

void requestAgainCallback() {
  final navigator = navigatorKey.currentState!;
  if (!navigator.canPop()) return;
  navigator
    ..popUntil((route) => route.isFirst)
    ..pushReplacement(MaterialPageRoute(
      builder: (context) => const PinCodeView(),
    ));
  showToast('Requesting again called');
}

class _SettingsViewState extends State<SettingsView> {
  final pinCodeTextEditingController = TextEditingController();
  final pinCodeController = DI.pinCodeController;

  late RequestAgainType requestAgainType;

  @override
  void initState() {
    super.initState();
    if (pinCodeController.requestAgainConfig == null) {
      requestAgainType = RequestAgainType.disabled;
    } else {
      requestAgainType = RequestAgainType.fromSeconds(
          pinCodeController.requestAgainConfig!.secondsBeforeRequestingAgain);
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO(Sosnovyy): fix overflow
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
            Text(pinCodeController.isPinCodeSet
                ? 'PIN CODE${pinCodeController.isBiometricsSet ? ' and biometrics are ' : ' is '}set'
                : 'PIN CODE is not set'),
            const SizedBox(height: 12),
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
                  await pinCodeController
                      .setPinCode(pinCodeTextEditingController.text);
                  showToast('PIN CODE set');
                  pinCodeTextEditingController.clear();
                  setState(() {});
                  if (!context.mounted) return;
                  FocusScope.of(context).unfocus();
                  widget.setPinViewState();
                }
              },
              child: Text(
                  'Set ${pinCodeController.isPinCodeSet ? 'new ' : ''}PIN CODE'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (!pinCodeController.isPinCodeSet) {
                  return showToast('PIN CODE must be set first');
                }
                if (pinCodeController.currentBiometrics ==
                    BiometricsType.none) {
                  if (await pinCodeController.canSetBiometrics()) {
                    final biometricsType =
                        await pinCodeController.enableBiometricsIfAvailable();
                    if (biometricsType == BiometricsType.none) {
                      showToast('No biometrics available on this device');
                    }
                  } else {
                    showToast('Biometrics is not available on this device');
                  }
                } else {
                  await pinCodeController.disableBiometrics();
                }
                setState(() {});
                widget.setPinViewState();
              },
              child: Text(pinCodeController.currentBiometrics ==
                      BiometricsType.none
                  ? 'Enable biometric'
                  : 'Disable biometric (${pinCodeController.currentBiometrics.title})'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (!pinCodeController.isPinCodeSet) {
                  return showToast('PIN CODE must be set first');
                }
                showAdaptiveDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                          'Select the duration before requesting pin code again after app being in background'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final type in RequestAgainType.values)
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                requestAgainType = type;
                                setState(() {});
                                widget.setPinViewState();
                                await pinCodeController.setRequestAgainConfig(
                                    type == RequestAgainType.disabled
                                        ? null
                                        : PinCodeRequestAgainConfig(
                                      secondsBeforeRequestingAgain: type.seconds!,
                                      onRequestAgain: requestAgainCallback,
                                    ));
                                showToast(
                                    'Selected ${type.title} option for Request Again');
                              },
                              child: Text(type.title),
                            ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: Navigator.of(context).pop,
                          child: const Text('Cancel'),
                        ),
                      ],
                    );
                  },
                );
              },
              child:
                  Text('Select Request Again time (${requestAgainType.title})'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (!pinCodeController.isPinCodeSet) {
                  return showToast('PIN CODE is not set yet');
                }
                await pinCodeController.clear();
                setState(() {});
                widget.setPinViewState();
                showToast(
                    'PIN CODE ${pinCodeController.isBiometricsSet ? 'and biometrics are ' : 'is '}disabled');
              },
              child: Text(
                  'Disable PIN CODE${pinCodeController.isBiometricsSet ? ' and biometrics' : ''}'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (!pinCodeController.isPinCodeSet) {
                  return showToast('PIN CODE must be set first');
                }
                if (pinCodeController.skipPinCodeConfig == null) {
                  await pinCodeController
                      .setSkipPinCodeConfig(SkipPinCodeConfig(
                    duration: const Duration(minutes: 1),
                    forcedForRequestAgain: false,
                  ));
                  showToast('1 minute skip time enabled');
                } else {
                  await pinCodeController.setSkipPinCodeConfig(null);
                  showToast('1 minute skip time disabled');
                }
                setState(() {});
                widget.setPinViewState();
              },
              child: Text(
                  '${pinCodeController.skipPinCodeConfig == null ? 'Enable' : 'Disable'} 1 min skip time'),
            ),
          ],
        ),
      ),
    );
  }
}

enum RequestAgainType {
  disabled(null),
  everyTime(0),
  sec30(30),
  min1(60),
  min3(180),
  min5(300),
  min10(600);

  final int? seconds;

  const RequestAgainType(this.seconds);

  static RequestAgainType fromSeconds(int seconds) {
    return RequestAgainType.values
        .firstWhere((element) => element.seconds == seconds);
  }
}

extension RequestAgainTypeExtension on RequestAgainType {
  String get title => switch (this) {
        RequestAgainType.disabled => 'Disabled',
        RequestAgainType.everyTime => 'Every time',
        RequestAgainType.sec30 => '30 seconds',
        RequestAgainType.min1 => '1 minute',
        RequestAgainType.min3 => '3 minutes',
        RequestAgainType.min5 => '5 minutes',
        RequestAgainType.min10 => '10 minutes',
      };

  int? get toSeconds => switch (this) {
        RequestAgainType.disabled => null,
        RequestAgainType.everyTime => 0,
        RequestAgainType.sec30 => 30,
        RequestAgainType.min1 => 60,
        RequestAgainType.min3 => 180,
        RequestAgainType.min5 => 300,
        RequestAgainType.min10 => 600,
      };
}
