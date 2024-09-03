/// Base exception for all Pin exceptions
abstract class PinException implements Exception {
  ///
  const PinException(this.cause);

  /// Cause of this exception
  final String cause;

  @override
  String toString();
}
