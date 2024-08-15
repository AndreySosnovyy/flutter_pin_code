class CantReturnTimeoutException implements Exception {
  const CantReturnTimeoutException(this.cause);

  final String cause;
}
