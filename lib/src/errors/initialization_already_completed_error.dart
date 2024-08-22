class InitializationAlreadyCompletedError implements Error {
  const InitializationAlreadyCompletedError(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;

  @override
  String toString() => 'InitializationAlreadyCompletedError: $cause';
}
