import 'package:flutter_pin_code/src/exceptions/abstract_exception.dart';

class TimeoutIsAlreadyRunningException implements PinException {
  const TimeoutIsAlreadyRunningException(this.cause);

  @override
  final String cause;

  @override
  String toString() => 'TimeoutIsAlreadyRunningException: $cause';
}
