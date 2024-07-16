import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pin_code/src/exceptions/configuration/biometrics_messages_not_provided_exception.dart';
import 'package:flutter_pin_code/src/exceptions/configuration/biometrics_not_configured_exception.dart';
import 'package:flutter_pin_code/src/exceptions/configuration/controller_not_initialized_exception.dart';
import 'package:flutter_pin_code/src/exceptions/configuration/initialization_already_completed_exception.dart';
import 'package:flutter_pin_code/src/exceptions/configuration/request_again_callback_not_set.dart';
import 'package:flutter_pin_code/src/exceptions/configuration/request_again_config_exception.dart';
import 'package:flutter_pin_code/src/exceptions/configuration/timeout_config_exception.dart';
import 'package:flutter_pin_code/src/exceptions/runtime/pin_code_not_set.dart';
import 'package:flutter_pin_code/src/exceptions/runtime/wrong_pin_code_format_exception.dart';
import 'package:flutter_pin_code/src/features/request_again_config.dart';
import 'package:flutter_pin_code/src/features/timeout/timeout_config.dart';
import 'package:flutter_pin_code/src/features/timeout/timeouts_refresh_event_loop.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kDefaultPinCodeKey = 'flutter_pin_code.default_key';
const String _kIsPinCodeSetKey = 'flutter_pin_code.is_pin_code_set';
const String _kBiometricsTypeKeySuffix = '.biometrics';
const String _kBackgroundTimestampKey = 'flutter_pin_code.background_timestamp';

class PinCodeController {
  PinCodeController({
    String? key,
    this.millisecondsBetweenTests = 0,
    this.requestAgainConfig,
    this.timeoutConfig,
  }) : key = key ?? _kDefaultPinCodeKey {
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
  late final LocalAuthentication _localAuthentication;

  late final TimeoutsRefreshEventLoop _timeoutsRefreshEventLoop;
  late final StreamSubscription _timeoutRefreshLoopStreamSubscription;

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

  /// Completer for checking if initialization method is called before any other operations.
  final _initCompleter = Completer();

  /// Current pin code.
  String? _currentPin;

  /// Current biometrics.
  late BiometricsType _currentBiometrics;

  BiometricsType get currentBiometrics {
    _verifyInitialized();
    return _currentBiometrics;
  }

  /// Constant pin code max length.
  final int pinCodeMaxLength = 64;

  /// Handles lifecycle state changes for Request again feature.
  Future<void> onAppLifecycleStateChanged(AppLifecycleState state) async {
    _verifyInitialized();
    if (state == AppLifecycleState.hidden) {
      await _prefs.setString(
        _kBackgroundTimestampKey,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } else if (state == AppLifecycleState.resumed) {
      if (requestAgainConfig == null) return;
      if (requestAgainConfig!.onRequestAgain == null) {
        throw const RequestAgainCallbackNotSet(
            'Request again callback not set');
      }
      // TODO(Sosnovyy): check if there is no timeout
      final rawTimestamp = _prefs.getString(_kBackgroundTimestampKey);
      if (rawTimestamp == null) return;
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(int.parse(rawTimestamp));
      if (DateTime.now().difference(timestamp).inSeconds >=
          requestAgainConfig!.secondsBeforeRequestingAgain) {
        requestAgainConfig!.onRequestAgain!();
      }
    }
  }

  /// Method you must call before any other method in this class.
  Future<void> initialize({
    /// Decides if there will be an initial biometric test if set.
    bool doInitialBiometricTestIfSet = true,

    /// Message for requesting fingerprint touch.
    String? fingerprintReason,

    /// Message for requesting face id use.
    String? faceIdReason,
  }) async {
    if (_initCompleter.isCompleted) {
      throw const InitializationAlreadyCompletedException(
          'Initialization already completed');
    }
    try {
      _prefs = await SharedPreferences.getInstance();
      _secureStorage = const FlutterSecureStorage();
      _localAuthentication = LocalAuthentication();

      // TODO(Sosnovyy): start timeout here if needed and return

      if (timeoutConfig != null && timeoutConfig!.isRefreshable) {
        _timeoutsRefreshEventLoop = TimeoutsRefreshEventLoop(prefs: _prefs);
        await _timeoutsRefreshEventLoop.initialize();
        _timeoutRefreshLoopStreamSubscription = _timeoutsRefreshEventLoop
            .refreshStream
            .listen((refreshedTimeoutDuration) {
              // TODO(Sosnovyy): add one available attempt to test pin code
        });
      }

      _currentPin = await _fetchPinCode();
      final isPinCodeSet = _prefs.getBool(_kIsPinCodeSetKey) ?? false;
      if (!isPinCodeSet && _currentPin != null) {
        _initCompleter.complete();
        return await clear();
      }

      _currentBiometrics = await fetchBiometricsType();
      if (_currentBiometrics == BiometricsType.none) {
        throw const BiometricsNotConfiguredException(
            'Biometrics not configured');
      }
      if (doInitialBiometricTestIfSet) {
        if (faceIdReason == null || fingerprintReason == null) {
          throw const BiometricsMessagesNotProvidedException(
              'Biometrics not configured');
        }
        await testBiometrics(
          faceIdReason: faceIdReason,
          fingerprintReason: fingerprintReason,
        );
      }
    } on Object catch (e) {
      _initCompleter.completeError(e);
      rethrow;
    }
    _initCompleter.complete();
  }

  /// Verification of initialization.
  /// Must be called before any other method in this class.
  void _verifyInitialized() {
    if (!_initCompleter.isCompleted) {
      throw const ControllerNotInitializedException(
          'Call async initialize() method before any other method or getter');
    }
  }

  /// Checks if pin code can be tested (not disabled by timeout)
  Future<bool> canTestPinCode() async {
    _verifyInitialized();
    // TODO(Sosnovyy): check if there are no timeout right now
    if (_currentPin == null) return false;
    // TODO(Sosnovyy): reset timeouts
    return true;
  }

  /// Checks if pin code is set.
  ///
  /// Can be used for initial navigation while deciding if send user to pin code
  /// screen or strait to some other home screen.
  bool get isPinCodeSet {
    _verifyInitialized();
    return _currentPin != null;
  }

  Future<String?> _fetchPinCode() async {
    final pin = await _secureStorage.read(key: key);
    _currentPin = pin;
    return pin;
  }

  /// Returns the number of tries left before falling into another timeout.
  ///
  /// Null if timeout feature is disabled and number of tries is unlimited.
  int? get numberOfPinCodeTries {
    _verifyInitialized();
    throw UnimplementedError();
  }

  /// Returns the current pin code length.
  ///
  /// Returns null if pin code is not set.
  int? get pinCodeLength {
    _verifyInitialized();
    return _currentPin?.length;
  }

  /// Removes pin code and biometrics from storage.
  Future<void> clear() async {
    _verifyInitialized();
    if (_currentPin == null) return;
    _currentPin = null;
    await _secureStorage.delete(key: key);
    await _prefs.setBool(_kIsPinCodeSetKey, false);
  }

  /// Checks if provided pin matches the current set one.
  ///
  /// If pin is valid, returns true and resets timeouts to initial state
  /// according to provided configuration.
  Future<bool> testPinCode(String pin) async {
    _verifyInitialized();
    if (_currentPin == null) {
      throw const PinCodeNotSetException('Pin code is not set but was tested');
    }
    if (pin == _currentPin) return true;
    if (timeoutConfig != null && timeoutConfig!.isRefreshable) {
      // TODO(Sosnovyy): add timeout to refresh loop
    }
    return false;
  }

  /// Sets pin in storage.
  Future<void> setPinCode(String pin) async {
    _verifyInitialized();
    if (pin.isEmpty) {
      throw const WrongPinCodeFormatException('Pin code cannot be empty');
    } else if (pin.length > pinCodeMaxLength) {
      throw WrongPinCodeFormatException(
          'Pin code is too long, max length is $pinCodeMaxLength');
    }
    _currentPin = pin;
    await _secureStorage.write(key: key, value: pin);
    await _prefs.setBool(_kIsPinCodeSetKey, true);
  }

  /// Sets biometrics type.
  Future<void> _setBiometricsType(BiometricsType type) async {
    _verifyInitialized();
    await _prefs.setString(key + _kBiometricsTypeKeySuffix, type.name);
  }

  /// Returns the type of set biometrics.
  Future<BiometricsType> fetchBiometricsType() async {
    _verifyInitialized();
    final name = _prefs.getString(key + _kBiometricsTypeKeySuffix);
    if (name == null) return BiometricsType.none;
    return BiometricsType.values.byName(name);
  }

  /// Returns true if biometrics are available on the device and can be set.
  ///
  /// Call this method before calling enableBiometricsIfAvailable() to check if
  /// you should ask user to use biometrics.
  Future<bool> canAuthenticateWithBiometrics() async {
    _verifyInitialized();
    return await _localAuthentication.isDeviceSupported() &&
        await _localAuthentication.canCheckBiometrics;
  }

  /// Enables biometrics if available on the device and returns the type of
  /// set biometrics.
  Future<BiometricsType> enableBiometricsIfAvailable() async {
    _verifyInitialized();
    final availableNativeTypes =
        await _localAuthentication.getAvailableBiometrics();
    if (availableNativeTypes.contains(BiometricType.face)) {
      await _setBiometricsType(BiometricsType.face);
      return BiometricsType.face;
    } else if (availableNativeTypes.contains(BiometricType.fingerprint) ||
        availableNativeTypes.contains(BiometricType.strong) ||
        availableNativeTypes.contains(BiometricType.weak)) {
      // TODO(Sosnovyy): check if the condition if fully valid
      await _setBiometricsType(BiometricsType.fingerprint);
      return BiometricsType.fingerprint;
    }
    return BiometricsType.none;
  }

  Future<bool> testBiometrics({
    /// Message for requesting fingerprint touch.
    required String fingerprintReason,

    /// Message for requesting face id use.
    required String faceIdReason,
  }) async {
    _verifyInitialized();
    final availableBiometrics =
        await _localAuthentication.getAvailableBiometrics();
    final String reason;
    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      reason = fingerprintReason;
    } else if (availableBiometrics.contains(BiometricType.face)) {
      reason = faceIdReason;
    } else {
      reason = '';
    }
    return await _localAuthentication.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        useErrorDialogs: true,
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
  }

  /// Disposes pin code controller.
  Future<void> dispose() async {
    _verifyInitialized();
    if (timeoutConfig != null && timeoutConfig!.isRefreshable) {
      _timeoutRefreshLoopStreamSubscription.cancel();
      await _timeoutsRefreshEventLoop.dispose();
    }
  }
}

/// Types of biometrics.
enum BiometricsType { none, face, fingerprint }
