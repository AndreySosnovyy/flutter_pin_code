import 'package:flutter_pin_code/src/exceptions/abstract_exception.dart';

///
class WrongPinCodeFormatException implements PinException {
  ///
  const WrongPinCodeFormatException(this.cause);

  @override
  final String cause;

  @override
  String toString() => 'WrongPinCodeFormatException: $cause';
}
