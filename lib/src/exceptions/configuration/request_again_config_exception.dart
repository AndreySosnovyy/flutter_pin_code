class RequestAgainConfigException implements Exception {
  const RequestAgainConfigException(this.cause);

  final String cause;
}
