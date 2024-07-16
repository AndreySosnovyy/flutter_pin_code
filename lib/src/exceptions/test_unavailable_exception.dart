class TestUnavailableException implements Exception {
  const TestUnavailableException(this.cause);

  final String cause;
}
