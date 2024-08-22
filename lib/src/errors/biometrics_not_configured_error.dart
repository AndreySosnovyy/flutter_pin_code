class BiometricsNotConfiguredError implements Error {
  const BiometricsNotConfiguredError(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;

  @override
  String toString() => 'BiometricsNotConfiguredError: $cause';
}
