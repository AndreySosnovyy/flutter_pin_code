class TimeoutConfigException implements Exception {
  const TimeoutConfigException(this.cause);

  final String cause;
}
