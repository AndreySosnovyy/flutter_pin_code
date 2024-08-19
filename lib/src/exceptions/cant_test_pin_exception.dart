class CantTestPinException implements Exception {
  const CantTestPinException(this.cause);

  final String cause;
}
