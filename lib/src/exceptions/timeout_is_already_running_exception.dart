class TimeoutIsAlreadyRunningException implements Exception {
  const TimeoutIsAlreadyRunningException(this.cause);

  final String cause;
}
