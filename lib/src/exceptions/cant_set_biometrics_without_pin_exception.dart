class CantSetBiometricsWithoutPinException implements Exception {
  const CantSetBiometricsWithoutPinException(this.cause);

  final String cause;
}
