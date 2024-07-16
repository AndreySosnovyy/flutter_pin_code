class TimeoutConfigError implements Error {
  const TimeoutConfigError(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;
}
