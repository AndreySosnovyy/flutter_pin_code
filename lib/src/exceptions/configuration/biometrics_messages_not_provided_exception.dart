class BiometricsMessagesNotProvidedException implements Exception {
  const BiometricsMessagesNotProvidedException(this.cause);

  final String cause;
}
