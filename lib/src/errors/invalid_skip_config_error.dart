class InvalidSkipConfigError implements Error {
  const InvalidSkipConfigError(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;

  @override
  String toString() => 'InvalidSkipConfigError: $cause';
}
