class ControllerNotInitializedError implements Error {
  const ControllerNotInitializedError(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;
}
