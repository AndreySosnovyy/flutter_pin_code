import 'package:example/app.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pin_code/flutter_pin_code.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
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
                  await pinCodeController
                      .setPinCode(pinCodeTextEditingController.text);
                  showToast('PIN CODE set');
                }
              },
              child: const Text('Set PIN CODE'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
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
                              onPressed: () {
                                Navigator.of(context).pop();
                                requestAgainType = type;
                                setState(() {});
                                showToast(
                                    'Selected ${type.title} option for Request Again');
                                if (type == RequestAgainType.disabled) {
                                  pinCodeController.requestAgainConfig = null;
                                } else {
                                  final newConfig = PinCodeRequestAgainConfig(
                                    secondsBeforeRequestingAgain: type.seconds!,
                                    onRequestAgain: pinCodeController
                                        .requestAgainConfig?.onRequestAgain,
                                  );
                                  pinCodeController.requestAgainConfig =
                                      newConfig;
                                }
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
