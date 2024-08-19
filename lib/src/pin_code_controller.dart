import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pin_code/src/errors/controller_not_initialized_error.dart';
import 'package:flutter_pin_code/src/errors/general_config_error.dart';
import 'package:flutter_pin_code/src/errors/initialization_already_completed_error.dart';
import 'package:flutter_pin_code/src/errors/request_again_callback_not_set_error.dart';
import 'package:flutter_pin_code/src/errors/request_again_config_error.dart';
import 'package:flutter_pin_code/src/errors/timeout_config_error.dart';
import 'package:flutter_pin_code/src/exceptions/cant_set_biometrics_without_pin_exception.dart';
import 'package:flutter_pin_code/src/exceptions/cant_test_pin_exception.dart';
import 'package:flutter_pin_code/src/exceptions/pin_code_not_set.dart';
import 'package:flutter_pin_code/src/exceptions/wrong_pin_code_format_exception.dart';
import 'package:flutter_pin_code/src/features/request_again/request_again_config.dart';
import 'package:flutter_pin_code/src/features/timeout/attempts_handler.dart';
import 'package:flutter_pin_code/src/features/timeout/timeout_config.dart';
import 'package:flutter_pin_code/src/features/timeout/timeout_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kDefaultPinCodeKey = 'flutter_pin_code.default_key';
const String _kIsPinCodeSetKey = 'flutter_pin_code.is_pin_code_set';
const String _kPinCodeRequestAgainSeconds =
    'flutter_pin_code.request_again_seconds';
const String _kBiometricsTypeKeySuffix = '.biometrics';
const String _kBackgroundTimestampKey = 'flutter_pin_code.background_timestamp';

class PinCodeController {
  PinCodeController({
    String? storageKey,
    this.millisecondsBetweenTests = 0,
    PinCodeRequestAgainConfig? requestAgainConfig,
    PinCodeTimeoutConfig? timeoutConfig,
  })  : _storageKey = storageKey ?? _kDefaultPinCodeKey,
        _timeoutConfig = timeoutConfig,
        _requestAgainConfig = requestAgainConfig {
    if (requestAgainConfig != null) {
      if (requestAgainConfig.secondsBeforeRequestingAgain < 0) {
        throw const RequestAgainConfigError(
            'Variable "secondsBeforeRequestingAgain" must be positive or zero');
      }
    }
    if (isTimeoutConfigured) {
      if (_timeoutConfig!.timeouts.isEmpty) {
        throw const TimeoutConfigError('Variable "timeouts" cannot be empty');
      }
      if (_timeoutConfig!.timeouts.keys.reduce(math.min) < 0) {
        throw const TimeoutConfigError('Timeout cannot be negative');
      }
      if (_timeoutConfig!.timeouts.values.reduce(math.min) < 0) {
        throw const TimeoutConfigError('Number of tries cannot be negative');
      }
      if (_timeoutConfig!.timeouts.keys.reduce(math.max) > kPinCodeMaxTimeout) {
        throw const TimeoutConfigError(
            'Max timeout is $kPinCodeMaxTimeout seconds');
      }
      if (_timeoutConfig!.timeoutRefreshRatio != null) {
        if (_timeoutConfig!.timeoutRefreshRatio! < 0 ||
            _timeoutConfig!.timeoutRefreshRatio! > 100) {
          throw const TimeoutConfigError(
              'Variable "timeoutRefreshRatio" must be between 0 and 100 inclusive');
        }
      }
    }
    if (millisecondsBetweenTests < 0 || millisecondsBetweenTests > 3000) {
      throw const GeneralConfigError(
          'Milliseconds between tests must be between 0 and 3000');
    }
  }

  late final SharedPreferences _prefs;

  late final FlutterSecureStorage _secureStorage;

  late final LocalAuthentication _localAuthentication;

  ///  Unique key for storing current pin code.
  late final String _storageKey;

  /// Configuration for "Requesting pin code again" feature.
  ///
  /// Disabled if null.
  PinCodeRequestAgainConfig? _requestAgainConfig;

  /// Configuration for "Timeouts" feature.
  /// Number of tries is unlimited if disabled.
  ///
  /// Disabled if null.
  PinCodeTimeoutConfig? _timeoutConfig;

  /// Attempts handler.
  late AttemptsHandler? _attemptsHandler;

  /// Timeout handler.
  late TimeoutHandler? _timeoutHandler;

  /// Number of milliseconds between tests.
  ///
  /// Max value is 3000.
  final int millisecondsBetweenTests;

  /// Completer for checking if initialization method is called before any other operations.
  final _initCompleter = Completer();

  /// Current pin code.
  String? _currentPin;

  /// Current biometrics.
  late BiometricsType _currentBiometrics;

  /// Constant pin code max length.
  final int pinCodeMaxLength = 64;

  /// Timestamp of last pin code test.
  ///
  /// Null if pin code hasn't been tested yet in this session.
  DateTime? _lastTestTimestamp;

  BiometricsType get currentBiometrics {
    _verifyInitialized();
    return _currentBiometrics;
  }

  /// Returns current request again config.
  PinCodeRequestAgainConfig? get requestAgainConfig {
    return _requestAgainConfig;
  }

  /// Returns true if Timeout config is provided
  bool get isTimeoutConfigured => _timeoutConfig != null;

  /// Sets request again config and writes it in prefs.
  ///
  /// Provide null to remove config.
  set requestAgainConfig(PinCodeRequestAgainConfig? config) {
    _requestAgainConfig = config;
    if (config == null) {
      _prefs.remove(_kPinCodeRequestAgainSeconds);
    } else {
      _prefs.setInt(
          _kPinCodeRequestAgainSeconds, config.secondsBeforeRequestingAgain);
    }
  }

  /// Returns current timeout config.
  PinCodeTimeoutConfig? get timeoutConfig {
    return _timeoutConfig;
  }

  /// Sets timeout config and writes it in prefs.
  ///
  /// Provide null to remove config.
  set timeoutConfig(PinCodeTimeoutConfig? config) {
    _timeoutConfig = config;
    if (config == null) {
      _prefs.remove(_kPinCodeRequestAgainSeconds);
    } else {
      // TODO(Sosnovyy): write necessary data from config to prefs
    }
  }

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
        throw const RequestAgainCallbackNotSetError(
            'Request again callback not set');
      }
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
    /// Message for requesting fingerprint touch.
    String? fingerprintReason,

    /// Message for requesting face id use.
    String? faceIdReason,
  }) async {
    if (_initCompleter.isCompleted) {
      throw const InitializationAlreadyCompletedError(
          'Initialization already completed');
    }
    try {
      _prefs = await SharedPreferences.getInstance();
      _secureStorage = const FlutterSecureStorage();
      _localAuthentication = LocalAuthentication();

      if (isTimeoutConfigured) {
        _attemptsHandler = AttemptsHandler(
          prefs: _prefs,
          timeoutsMap: _timeoutConfig!.timeouts,
        );
        _timeoutHandler = TimeoutHandler(
          prefs: _prefs,
          onTimeoutEnded: _timeoutConfig!.onTimeoutEnded,
        );
        await _attemptsHandler!.initialize();
        await _timeoutHandler!.initialize();
      } else {
        _attemptsHandler = null;
        _timeoutHandler = null;
      }

      if (requestAgainConfig != null) {
        await _prefs.setInt(
          _kPinCodeRequestAgainSeconds,
          requestAgainConfig!.secondsBeforeRequestingAgain,
        );
      } else {
        final secondsFromPrefs = _prefs.getInt(_kPinCodeRequestAgainSeconds);
        if (secondsFromPrefs != null) {
          requestAgainConfig = PinCodeRequestAgainConfig(
            secondsBeforeRequestingAgain: secondsFromPrefs,
          );
        }
      }

      _currentPin = await _fetchPinCode();
      final isPinCodeSet = _prefs.getBool(_kIsPinCodeSetKey) ?? false;
      if (!isPinCodeSet && _currentPin != null) {
        _initCompleter.complete();
        return await clear();
      }
      _currentBiometrics = await _fetchBiometricsType();

      // TODO(Sosnovyy): start timeout here if needed
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
      throw const ControllerNotInitializedError(
          'Call async initialize() method before any other method or getter');
    }
  }

  /// Checks if necessary delay set in [millisecondsBetweenTests] between tests passed.
  bool get isDelayBetweenTestsPassed =>
      _lastTestTimestamp == null ||
      DateTime.now().difference(_lastTestTimestamp!).inMilliseconds >
          millisecondsBetweenTests;

  /// Checks if pin code can be tested (not disabled by timeout)
  Future<bool> canTestPinCode() async {
    _verifyInitialized();
    if (isTimeoutConfigured && _timeoutHandler!.isTimeoutRunning) return false;
    if (!isDelayBetweenTestsPassed) return false;
    if (_currentPin == null) return false;
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
    final pin = await _secureStorage.read(key: _storageKey);
    _currentPin = pin;
    return pin;
  }

  /// Returns the amount of tries left before falling into another timeout.
  ///
  /// Null if timeout feature is disabled and number of tries is unlimited.
  int? get amountOfAttemptsLeftBeforeTimeout {
    _verifyInitialized();
    return _attemptsHandler?.attemptsAmountBeforeTimeout;
  }

  /// Returns the current pin code's length.
  ///
  /// Returns null if pin code is not set.
  int? get pinCodeLength {
    _verifyInitialized();
    return _currentPin?.length;
  }

  /// Removes pin code (+ its configs) and biometrics from storage.
  Future<void> clear({bool clearConfigs = true}) async {
    _verifyInitialized();
    if (_currentPin == null) return;
    _currentPin = null;
    await _secureStorage.delete(key: _storageKey);
    await _prefs.setBool(_kIsPinCodeSetKey, false);
    await disableBiometrics();
    if (clearConfigs) {
      await _prefs.remove(_kPinCodeRequestAgainSeconds);
    }
  }

  /// Checks if provided pin matches the current set one.
  ///
  /// If pin is valid, returns true and resets timeouts to initial state
  /// according to provided configuration.
  Future<bool> testPinCode(String pin) async {
    _verifyInitialized();
    if (_currentPin == null) {
      throw const PinCodeNotSetException('Pin code is not set, but was tested');
    }
    if (!isDelayBetweenTestsPassed) {
      throw CantTestPinException(
          'Too fast tests. You must delay $millisecondsBetweenTests ms between tests');
    }
    if (isTimeoutConfigured && _timeoutHandler!.isTimeoutRunning) {
      throw const CantTestPinException('Timeout is running!');
    }
    if (pin == _currentPin) return true;
    if (isTimeoutConfigured) {
      final wasteResponse = await _attemptsHandler!.wasteAttempt();
      if (wasteResponse.areAllAttemptsWasted) {
        if (!_timeoutConfig!.isRefreshable) {
          _timeoutConfig!.onMaxTimeoutsReached!();
          return false;
        }
      }
      if (wasteResponse.amountOfAvailableAttemptsBeforeTimeout == 0) {
        // FIXME(Sosnovyy): Null check operator used on a null value
        _timeoutHandler!.startTimeout(
            durationInSeconds: wasteResponse.timeoutDurationInSeconds!);
      }
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
    await _secureStorage.write(key: _storageKey, value: pin);
    await _prefs.setBool(_kIsPinCodeSetKey, true);
  }

  /// Sets biometrics type.
  Future<void> _setBiometricsType(BiometricsType type) async {
    _verifyInitialized();
    _currentBiometrics = type;
    await _prefs.setString(_storageKey + _kBiometricsTypeKeySuffix, type.name);
  }

  /// Returns the type of set biometrics.
  Future<BiometricsType> _fetchBiometricsType() async {
    final name = _prefs.getString(_storageKey + _kBiometricsTypeKeySuffix);
    if (name == null) return BiometricsType.none;
    return BiometricsType.values.byName(name);
  }

  /// Returns true if biometrics are available on the device and can be set.
  ///
  /// Call this method before calling enableBiometricsIfAvailable() to check if
  /// you should ask user to use biometrics.
  Future<bool> canSetBiometrics() async {
    _verifyInitialized();
    return await _localAuthentication.isDeviceSupported() &&
        await _localAuthentication.canCheckBiometrics &&
        (await _localAuthentication.getAvailableBiometrics()).isNotEmpty;
  }

  /// Returns true if biometrics is set and can be tested by user.
  bool get isBiometricsSet => currentBiometrics != BiometricsType.none;

  /// Enables biometrics if available on the device and returns the type of
  /// set biometrics.
  Future<BiometricsType> enableBiometricsIfAvailable() async {
    _verifyInitialized();
    if (isBiometricsSet) return currentBiometrics;
    if (_currentPin == null) {
      throw const CantSetBiometricsWithoutPinException(
          'Cant set biometrics without PIN CODE being set first');
    }
    if (!await _localAuthentication.isDeviceSupported()) {
      return BiometricsType.none;
    }
    final availableNativeTypes =
        await _localAuthentication.getAvailableBiometrics();
    if (availableNativeTypes.contains(BiometricType.face)) {
      await _setBiometricsType(BiometricsType.face);
      return BiometricsType.face;
    } else if (availableNativeTypes.contains(BiometricType.fingerprint) ||
        availableNativeTypes.contains(BiometricType.strong) ||
        availableNativeTypes.contains(BiometricType.weak)) {
      await _setBiometricsType(BiometricsType.fingerprint);
      return BiometricsType.fingerprint;
    }
    return BiometricsType.none;
  }

  /// Disables biometrics.
  Future<void> disableBiometrics() async {
    _currentBiometrics = BiometricsType.none;
    await _prefs.setString(
        _storageKey + _kBiometricsTypeKeySuffix, BiometricsType.none.name);
  }

  /// Requests biometrics from user to sign in by system dialog and without pin.
  ///
  /// If you want to have the initial request when you open your app or go to
  /// the pin code screen, you have to implement this logic manually!
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
      reason = ''; // This will throw an exception
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
    await _timeoutHandler?.dispose();
  }
}

/// Types of biometrics.
enum BiometricsType { none, face, fingerprint }
