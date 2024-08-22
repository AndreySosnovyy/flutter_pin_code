class CantTestPinException implements Exception {
  const CantTestPinException(this.cause);

  final String cause;

  @override
  String toString() => 'CantTestPinException: $cause';
}
