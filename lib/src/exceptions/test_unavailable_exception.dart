class TestUnavailableException implements Exception {
  const TestUnavailableException(this.cause);

  final String cause;

  @override
  String toString() => 'TestUnavailableException: $cause';
}
