import 'package:flutter_pin_code/flutter_pin_code.dart';

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