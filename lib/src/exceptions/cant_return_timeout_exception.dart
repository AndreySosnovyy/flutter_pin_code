import 'package:pin/src/exceptions/abstract_exception.dart';

///
class CantReturnTimeoutException implements PinException {
  ///
  const CantReturnTimeoutException(this.cause);

  @override
  final String cause;

  @override
  String toString() => 'CantReturnTimeoutException: $cause';
}
