class RequestAgainCallbackNotSetError implements Error {
  const RequestAgainCallbackNotSetError(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;
}
