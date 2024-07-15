class ControllerNotInitializedException implements Exception {
  const ControllerNotInitializedException(this.cause);

  final String cause;
}
