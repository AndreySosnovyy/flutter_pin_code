// TODO(Sosnovyy): add stack trace to every exception
// TODO(Sosnovyy): add toString to every exception and error
class CantReturnTimeoutException implements Exception {
  const CantReturnTimeoutException(this.cause);

  final String cause;
}
