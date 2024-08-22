import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_pin_code/src/errors/controller_not_initialized_error.dart';
import 'package:flutter_pin_code/src/errors/general_config_error.dart';
import 'package:flutter_pin_code/src/errors/initialization_already_completed_error.dart';
import 'package:flutter_pin_code/src/errors/no_on_max_timeouts_reached_callback_provided.dart';
import 'package:flutter_pin_code/src/errors/request_again_callback_not_set_error.dart';
import 'package:flutter_pin_code/src/exceptions/cant_set_biometrics_without_pin_exception.dart';
import 'package:flutter_pin_code/src/exceptions/cant_test_pin_exception.dart';
import 'package:flutter_pin_code/src/exceptions/pin_code_not_set.dart';
import 'package:flutter_pin_code/src/exceptions/wrong_pin_code_format_exception.dart';
import 'package:flutter_pin_code/src/features/logging/logger.dart';
import 'package:flutter_pin_code/src/features/request_again/request_again_config.dart';
import 'package:flutter_pin_code/src/features/skip_pin/skip_pin_config.dart';
import 'package:flutter_pin_code/src/features/timeout/attempts_handler.dart';
import 'package:flutter_pin_code/src/features/timeout/timeout_config.dart';
import 'package:flutter_pin_code/src/features/timeout/timeout_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kDefaultPinCodeKey = 'flutter_pin_code.default_key';
const String _kIsPinCodeSetKey = 'flutter_pin_code.is_pin_code_set';
const String _kPinCodeRequestAgainSecondsKey =
    'flutter_pin_code.request_again_seconds';
const String _kSkipPinConfigKey = 'flutter_pin_code.skip_pin_config';
const String _kBiometricsTypeKeySuffix = '.biometrics';
const String _kBackgroundTimestampKey = 'flutter_pin_code.background_timestamp';

// TODO(Sosnovyy): add stream of states
class PinCodeController {
  PinCodeController({
    this.logsEnabled = false,
    String? storageKey,
    this.millisecondsBetweenTests = 0,
    PinCodeRequestAgainConfig? requestAgainConfig,
    SkipPinCodeConfig? skipPinCodeConfig,
    this.timeoutConfig,
    this.iterateInterval,
  })  : _storageKey = storageKey ?? _kDefaultPinCodeKey,
        _requestAgainConfig = requestAgainConfig,
        _skipPinCodeConfig = skipPinCodeConfig {
    if (millisecondsBetweenTests < 0 || millisecondsBetweenTests > 3000) {
      throw const GeneralConfigError(
          'Milliseconds between tests must be between 0 and 3000');
    }
    logger.filter.enabled = logsEnabled;
  }

  late final SharedPreferences _prefs;

  late final FlutterSecureStorage _secureStorage;

  late final LocalAuthentication _localAuthentication;

  /// Enables logs (for debug purposes). Disabled by default.
  final bool logsEnabled;

  ///  Unique key for storing current pin code.
  late final String _storageKey;

  /// {@template requestAgainConfig}
  /// Configuration for "Requesting pin code again" feature.
  ///
  /// Disabled if null.
  ///
  /// Configurable by developer in advance or in runtime by user (if app allows so)!
  /// {@endtemplate}
  PinCodeRequestAgainConfig? _requestAgainConfig;

  /// Configuration for "Timeouts" feature.
  /// Number of tries is unlimited if disabled.
  ///
  /// Disabled if null.
  ///
  /// Configurable only by developer in advance!
  PinCodeTimeoutConfig? timeoutConfig;

  /// {@template skipPinCodeConfig}
  /// Configuration for "Requesting pin code again" feature.
  ///
  /// Disabled if null.
  ///
  /// Pay attention that the developer has to check if pin code can be skipped
  /// before navigating user to the pin code screen! It is possible by using
  /// [canSkipPinCodeNow] getter.
  /// The only case where it can be done automatically is when app state
  /// changes in [onAppLifecycleStateChanged] and Request Again can be skipped.
  ///
  /// Configurable by developer in advance or in runtime by user (if app allows so)!
  /// But prioritized one is set by the user. Which means that if you as a
  /// developer provide SkipPinCodeConfig but another configuration is already
  /// exists in disk, it will override provided SkipPinCodeConfig from constructor.
  /// {@endtemplate}
  SkipPinCodeConfig? _skipPinCodeConfig;

  /// Attempts handler.
  late AttemptsHandler? _attemptsHandler;

  /// Timeout handler.
  late TimeoutHandler? _timeoutHandler;

  /// {@macro iterateInterval}
  final int? iterateInterval;

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

  /// Returns true if Timeout config is provided
  bool get isTimeoutConfigured => timeoutConfig != null;

  /// {@macro requestAgainConfig}
  PinCodeRequestAgainConfig? get requestAgainConfig => _requestAgainConfig;

  /// Sets request again config and writes it in prefs.
  ///
  /// Provide null to remove config.
  set requestAgainConfig(PinCodeRequestAgainConfig? config) {
    _requestAgainConfig = config;
    if (config == null) {
      _prefs.remove(_kPinCodeRequestAgainSecondsKey);
    } else {
      _prefs.setInt(
          _kPinCodeRequestAgainSecondsKey, config.secondsBeforeRequestingAgain);
    }
  }

  /// {@macro skipPinCodeConfig}
  SkipPinCodeConfig? get skipPinCodeConfig => _skipPinCodeConfig;

  /// Sets skip pin config and writes it in prefs.
  ///
  /// Provide null to remove config.
  set skipPinCodeConfig(SkipPinCodeConfig? config) {
    _skipPinCodeConfig = config;
    if (config == null) {
      _prefs.remove(_kSkipPinConfigKey);
    } else {
      _prefs.setString(
          _kSkipPinConfigKey, json.encode(SkipConfigUtils.toMap(config)));
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
      if (_skipPinCodeConfig != null &&
          !_skipPinCodeConfig!.forcedForRequestAgain &&
          canSkipPinCodeNow) {
        return logger.d('Request again was skipped');
      }
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
        logger.d('Request again callback was called');
      }
    }
  }

  /// Returns true if controller is initialized.
  bool get isInitialized => _initCompleter.isCompleted;

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
          isRefreshable: timeoutConfig!.isRefreshable,
          timeoutsMap: timeoutConfig!.timeouts,
        );
        _timeoutHandler = TimeoutHandler(
          prefs: _prefs,
          iterateInterval: iterateInterval,
          onTimeoutEnded: () {
            timeoutConfig!.onTimeoutEnded?.call();
            if (_attemptsHandler!.isInLoop) _attemptsHandler!.restoreAttempt();
          },
          onTimeoutStarted: (durationInSeconds) => timeoutConfig!
              .onTimeoutStarted
              ?.call(Duration(seconds: durationInSeconds)),
        );
        await _attemptsHandler!.initialize();
        await _timeoutHandler!.initialize();
      } else {
        _attemptsHandler = null;
        _timeoutHandler = null;
      }

      if (requestAgainConfig != null) {
        await _prefs.setInt(
          _kPinCodeRequestAgainSecondsKey,
          requestAgainConfig!.secondsBeforeRequestingAgain,
        );
      } else {
        final secondsFromPrefs = _prefs.getInt(_kPinCodeRequestAgainSecondsKey);
        if (secondsFromPrefs != null) {
          requestAgainConfig = PinCodeRequestAgainConfig(
            secondsBeforeRequestingAgain: secondsFromPrefs,
          );
        }
      }

      final skipPinConfigFromDisk = await _fetchSkipPinConfigFromDisk();
      if (skipPinConfigFromDisk != null) {
        _skipPinCodeConfig = skipPinConfigFromDisk;
      }

      _currentPin = await _fetchPinCode();
      final isPinCodeSet = _prefs.getBool(_kIsPinCodeSetKey) ?? false;
      if (!isPinCodeSet && _currentPin != null) {
        _initCompleter.complete();
        return await clear();
      }
      _currentBiometrics = await _fetchBiometricsType();
    } on Object catch (e) {
      _initCompleter.completeError(e);
      rethrow;
    }
    _initCompleter.complete();
  }

  Future<SkipPinCodeConfig?> _fetchSkipPinConfigFromDisk() async {
    final rawSkipPinConfig = _prefs.getString(_kSkipPinConfigKey);
    if (rawSkipPinConfig == null) return null;
    return SkipConfigUtils.fromMap(json.decode(rawSkipPinConfig));
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

  /// Checks if pin code can be skipped because of skip pin config
  bool get canSkipPinCodeNow {
    if (_lastTestTimestamp == null) return false;
    return _skipPinCodeConfig != null &&
        _lastTestTimestamp!
            .add(_skipPinCodeConfig!.duration)
            .isBefore(DateTime.now());
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
      await _prefs.remove(_kPinCodeRequestAgainSecondsKey);
    }
    await _timeoutHandler?.clearTimeout();
    await _attemptsHandler?.restoreAllAttempts();
    await _prefs.remove(_kSkipPinConfigKey);
    logger.d('All pin related data were successfully cleared');
  }

  /// Returns whether timeout is currently running.
  bool get isTimeoutRunning => _timeoutHandler?.isTimeoutRunning ?? false;

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

    _lastTestTimestamp = DateTime.now();
    if (pin == _currentPin) {
      logger.d('Pin code was successfully tested');
      _attemptsHandler?.restoreAllAttempts();
      _timeoutHandler?.clearTimeout();
      return true;
    }
    if (isTimeoutConfigured) {
      final wasteResponse = await _attemptsHandler!.wasteAttempt();
      if (wasteResponse.areAllAttemptsWasted && !timeoutConfig!.isRefreshable) {
        if (timeoutConfig!.onMaxTimeoutsReached == null) {
          throw const NoOnMaxTimeoutsReachedCallbackProvided(
              'No callback provided, but it must be already called');
        }
        await clear();
        timeoutConfig!.onMaxTimeoutsReached!();
        return false;
      }
      if (wasteResponse.amountOfAvailableAttemptsBeforeTimeout == 0) {
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
    logger.d('Pin code was successfully set');
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
      logger.d('Face ID was successfully set as biometrics type');
      return BiometricsType.face;
    } else if (availableNativeTypes.contains(BiometricType.fingerprint) ||
        availableNativeTypes.contains(BiometricType.strong) ||
        availableNativeTypes.contains(BiometricType.weak)) {
      await _setBiometricsType(BiometricsType.fingerprint);
      logger.d('Fingerprint was successfully set as biometrics type');
      return BiometricsType.fingerprint;
    }
    return BiometricsType.none;
  }

  /// Disables biometrics.
  Future<void> disableBiometrics() async {
    _currentBiometrics = BiometricsType.none;
    await _prefs.setString(
        _storageKey + _kBiometricsTypeKeySuffix, BiometricsType.none.name);
    logger.d('Biometrics was successfully disabled');
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
    final String reason;
    if (_currentBiometrics == BiometricsType.fingerprint) {
      reason = fingerprintReason;
    } else if (_currentBiometrics == BiometricsType.face) {
      reason = faceIdReason;
    } else {
      reason = ''; // This will throw an exception
    }
    final result = await _localAuthentication.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        useErrorDialogs: true,
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
    if (result) {
      logger.d('Biometrics was successfully tested');
      return true;
    } else {
      logger.d('Something went wrong during biometrics test');
      return false;
    }
  }

  /// Disposes pin code controller.
  Future<void> dispose() async {
    _verifyInitialized();
    await _timeoutHandler?.dispose();
    logger.d('Pin code controller was disposed');
  }
}

/// Types of biometrics.
enum BiometricsType { none, face, fingerprint }
