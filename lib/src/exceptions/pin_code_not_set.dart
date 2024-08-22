class PinCodeNotSetException implements Exception {
  const PinCodeNotSetException(this.cause);

  final String cause;

  @override
  String toString() => 'PinCodeNotSetException: $cause';
}
