class RequestAgainConfigError implements Error {
  const RequestAgainConfigError(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;

  @override
  String toString() => 'RequestAgainConfigError: $cause';
}
