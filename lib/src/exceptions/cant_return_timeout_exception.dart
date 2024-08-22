class CantReturnTimeoutException implements Exception {
  const CantReturnTimeoutException(this.cause);

  final String cause;

  @override
  String toString() => 'CantReturnTimeoutException: $cause';
}
