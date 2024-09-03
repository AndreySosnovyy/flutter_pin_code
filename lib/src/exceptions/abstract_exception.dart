abstract class PinException implements Exception {
  const PinException(this.cause);

  final String cause;

  @override
  String toString();
}
