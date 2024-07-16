class BiometricsMessagesNotProvidedError implements Error {
  const BiometricsMessagesNotProvidedError(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;
}
