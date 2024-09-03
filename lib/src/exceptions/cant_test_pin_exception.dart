import 'package:flutter_pin_code/src/exceptions/abstract_exception.dart';

class CantTestPinException implements PinException {
  const CantTestPinException(this.cause);

  @override
  final String cause;

  @override
  String toString() => 'CantTestPinException: $cause';
}
