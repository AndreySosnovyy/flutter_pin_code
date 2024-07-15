class InitializationAlreadyCompletedException implements Exception {
  const InitializationAlreadyCompletedException(this.cause);

  final String cause;
}
