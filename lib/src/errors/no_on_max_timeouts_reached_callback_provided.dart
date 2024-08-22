class NoOnMaxTimeoutsReachedCallbackProvided implements Error {
  const NoOnMaxTimeoutsReachedCallbackProvided(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;

  @override
  String toString() => 'NoOnMaxTimeoutsReachedCallbackProvided: $cause';
}
