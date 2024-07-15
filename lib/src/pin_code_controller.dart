import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_pin_code/src/exceptions/configuration/controller_not_initialized_exception.dart';
import 'package:flutter_pin_code/src/exceptions/configuration/initialization_already_completed_exception.dart';
import 'package:flutter_pin_code/src/exceptions/configuration/request_again_config_exception.dart';
import 'package:flutter_pin_code/src/exceptions/configuration/timeout_config_exception.dart';
import 'package:flutter_pin_code/src/exceptions/runtime/pin_code_not_set.dart';
import 'package:flutter_pin_code/src/exceptions/runtime/wrong_pin_code_format_exception.dart';
import 'package:flutter_pin_code/src/features/request_again.dart';
import 'package:flutter_pin_code/src/features/timeout.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kDefaultPinCodeKey = 'flutter_pin_code.default_key';
const String kIsPinCodeSetKey = 'flutter_pin_code.is_pin_code_set';

const int kPinCodeMaxLength = 64;

class PinCodeController {
  PinCodeController({
    String? key,
    this.millisecondsBetweenTests = 0,
    this.requestAgainConfig,
    this.timeoutConfig,
  }) : key = key ?? kDefaultPinCodeKey {
    if (requestAgainConfig != null) {
      if (requestAgainConfig!.secondsBeforeRequestingAgain < 0) {
        throw const RequestAgainConfigException(
            'Variable "secondsBeforeRequestingAgain" must be positive or zero');
      }
    }
    if (timeoutConfig != null) {
      if (timeoutConfig!.timeouts.isEmpty) {
        throw const TimeoutConfigException(
            'Variable "timeouts" cannot be empty');
      }
      if (timeoutConfig!.timeouts.keys.reduce(math.min) < 0) {
        throw const TimeoutConfigException('Timeout cannot be negative');
      }
      if (timeoutConfig!.timeouts.values.reduce(math.min) < 0) {
        throw const TimeoutConfigException(
            'Number of tries cannot be negative');
      }
      if (timeoutConfig!.timeouts.keys.reduce(math.max) > kPinCodeMaxTimeout) {
        throw const TimeoutConfigException(
            'Max timeout is $kPinCodeMaxTimeout seconds');
      }
      if (timeoutConfig!.timeoutRefreshRatio != null) {
        if (timeoutConfig!.timeoutRefreshRatio! < 0 ||
            timeoutConfig!.timeoutRefreshRatio! > 100) {
          throw const TimeoutConfigException(
              'Variable "timeoutRefreshRatio" must be between 0 and 100 inclusive');
        }
      }
    }
  }

  late final SharedPreferences _prefs;
  late final FlutterSecureStorage _secureStorage;

  ///  Unique key for storing current pin code.
  late final String key;

  /// Configuration for "Requesting pin code again" feature.
  ///
  /// Disabled if null.
  final PinCodeRequestAgainConfig? requestAgainConfig;

  /// Configuration for "Timeouts" feature.
  /// Number of tries is unlimited if disabled.
  ///
  /// Disabled if null.
  final PinCodeTimeoutConfig? timeoutConfig;

  /// Number of milliseconds between tests.
  final int millisecondsBetweenTests;

  // TODO(Sosnovyy): add timeout stream

  /// Completer for checking if initialization method is called before any other operations.
  final _initCompleter = Completer();

  /// Returns current pin code.
  String? _currentPin;

  /// Method you must call before any other method in this class.
  Future<void> initialize() async {
    if (_initCompleter.isCompleted) {
      throw const InitializationAlreadyCompletedException(
          'Initialization already completed');
    }
    try {
      _prefs = await SharedPreferences.getInstance();
      _secureStorage = const FlutterSecureStorage();
      _currentPin = await _fetchPin();
    } on Object catch (e) {
      _initCompleter.completeError(e);
      rethrow;
    }
    _initCompleter.complete(true);
  }

  /// Verification of initialization.
  /// Must be called before any other method in this class.
  void _verifyInitialized() {
    if (!_initCompleter.isCompleted) {
      throw const ControllerNotInitializedException(
          'Call async initialize() method before any other method');
    }
  }

  /// Checks if pin code can be tested (not disabled by timeout)
  Future<bool> canTest() async {
    _verifyInitialized();
    // TODO(Sosnovyy): check if there are no timeout right now
    if (_currentPin == null) return false;
    return true;
  }

  /// Checks if pin code is set.
  bool get isPinCodeSet {
    _verifyInitialized();
    return _currentPin != null;
  }

  Future<String?> _fetchPin() async {
    final pin = await _secureStorage.read(key: key);
    _currentPin = pin;
    return pin;
  }

  /// Returns the number of tries left before falling into another timeout.
  ///
  /// Null if timeout feature is disabled and number of tries is unlimited.
  int? get numberOfTries {
    _verifyInitialized();
    throw UnimplementedError();
  }

  /// Returns the current pin code length.
  ///
  /// Returns null if pin code is not set.
  int? get pinLength {
    _verifyInitialized();
    return _currentPin?.length;
  }

  /// Removes pin from storage.
  Future<void> clear() async {
    _verifyInitialized();
    if (_currentPin == null) return;
    _currentPin = null;
    await _secureStorage.delete(key: key);
    await _prefs.setBool(kIsPinCodeSetKey, false);
  }

  /// Checks if provided pin matches the current set one.
  ///
  /// If pin is valid, returns true and resets timeouts to initial state
  /// according to provided configuration.
  Future<bool> test(String pin) async {
    _verifyInitialized();
    if (_currentPin == null) {
      throw const PinCodeNotSetException('Pin code is not set but was tested');
    }
    if (pin == _currentPin) return true;
    return false;
  }

  /// Sets pin in storage.
  Future<void> set(String pin) async {
    _verifyInitialized();
    if (pin.isEmpty) {
      throw const WrongPinCodeFormatException('Pin code cannot be empty');
    } else if (pin.length > kPinCodeMaxLength) {
      throw const WrongPinCodeFormatException(
          'Pin code is too long, max length is $kPinCodeMaxLength');
    }
    _currentPin = pin;
    await _secureStorage.write(key: key, value: pin);
    await _prefs.setBool(kIsPinCodeSetKey, true);
  }
}
