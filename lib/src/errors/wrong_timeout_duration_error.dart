class WrongTimeoutDurationError implements Error {
  const WrongTimeoutDurationError(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;
}
