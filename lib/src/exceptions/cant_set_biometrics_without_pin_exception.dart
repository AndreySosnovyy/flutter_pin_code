import 'package:pin/src/exceptions/abstract_exception.dart';

///
class CantSetBiometricsWithoutPinException implements PinException {
  ///
  const CantSetBiometricsWithoutPinException(this.cause);

  @override
  final String cause;

  @override
  String toString() => 'CantSetBiometricsWithoutPinException: $cause';
}
