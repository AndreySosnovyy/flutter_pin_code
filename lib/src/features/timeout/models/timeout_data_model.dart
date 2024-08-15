class Timeout {
  Timeout({
    required this.duration,
    required this.expirationTimestamp,
  });

  /// Duration of the timeout in seconds
  final int duration;

  /// Timestamp of the expiration
  final DateTime expirationTimestamp;

  factory Timeout.fromMap(Map<String, dynamic> json) {
    return Timeout(
      duration: json['duration'] as int,
      expirationTimestamp: DateTime.fromMillisecondsSinceEpoch(
          json['expirationTimestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'duration': duration,
      'expirationTimestamp': expirationTimestamp.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'Timeout('
        'duration: $duration, '
        'expirationTimestamp: $expirationTimestamp'
        ')';
  }
}
