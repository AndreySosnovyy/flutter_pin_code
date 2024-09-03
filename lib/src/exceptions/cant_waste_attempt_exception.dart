import 'package:pin/src/exceptions/abstract_exception.dart';

///
class CantWasteAttemptException implements PinException {
  ///
  const CantWasteAttemptException(this.cause);

  @override
  final String cause;

  @override
  String toString() => 'CantWasteAttemptException: $cause';
}
