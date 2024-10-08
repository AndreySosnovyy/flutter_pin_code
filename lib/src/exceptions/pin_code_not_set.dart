import 'package:pin/src/exceptions/abstract_exception.dart';

///
class PinCodeNotSetException implements PinException {
  ///
  const PinCodeNotSetException(this.cause);

  @override
  final String cause;

  @override
  String toString() => 'PinCodeNotSetException: $cause';
}
