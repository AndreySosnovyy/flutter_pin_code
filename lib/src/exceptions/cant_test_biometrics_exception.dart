import 'package:pin/src/exceptions/abstract_exception.dart';

///
class CantTestBiometricsException implements PinException {
  ///
  const CantTestBiometricsException(this.cause);

  @override
  final String cause;

  @override
  String toString() => 'CantTestBiometricsException: $cause';
}
