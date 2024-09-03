/// {@template flutter_pin_code.waste_attempt_response}
/// Response from the waste attempt handler.
/// {@endtemplate}
class WasteAttemptResponse {
  /// {@macro flutter_pin_code.waste_attempt_response}
  WasteAttemptResponse({
    required this.amountOfAvailableAttemptsBeforeTimeout,
    required this.timeoutDurationInSeconds,
    required this.areAllAttemptsWasted,
  });

  /// Amount of attempts available to waste before falling into timeout.
  final int amountOfAvailableAttemptsBeforeTimeout;

  /// Duration of the timeout to fall in (in seconds).
  ///
  /// 0 if no need to fall into timeout now and more attempts are available
  /// to waste before timeout.
  ///
  /// Null if timeouts are not refreshable and all wasted.
  final int? timeoutDurationInSeconds;

  /// Indicates if there are no more attempts available to waste in general.
  final bool areAllAttemptsWasted;

  /// Indicates if there are more attempts to waste before falling into timeout.
  bool get hasMoreAttemptsWithoutTimeout =>
      amountOfAvailableAttemptsBeforeTimeout > 0;
}
