class CantTestBiometricsException implements Exception {
  const CantTestBiometricsException(this.cause);

  final String cause;

  @override
  String toString() => 'CantTestBiometricsException: $cause';
}
