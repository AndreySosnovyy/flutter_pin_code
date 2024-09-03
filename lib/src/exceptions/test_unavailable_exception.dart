import 'package:pin/src/exceptions/abstract_exception.dart';

///
class TestUnavailableException implements PinException {
  ///
  const TestUnavailableException(this.cause);

  @override
  final String cause;

  @override
  String toString() => 'TestUnavailableException: $cause';
}
