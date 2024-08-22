class CantSetBiometricsWithoutPinException implements Exception {
  const CantSetBiometricsWithoutPinException(this.cause);

  final String cause;

  @override
  String toString() => 'CantSetBiometricsWithoutPinException: $cause';
}
