class BiometricsNotConfiguredException implements Exception {
  const BiometricsNotConfiguredException(this.cause);

  final String cause;
}
