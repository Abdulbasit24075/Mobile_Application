class AppException implements Exception {
  final String code;   // e.g., 'network-timeout', 'not-found'
  final String message;
  AppException(this.code, this.message);

  @override
  String toString() => '$code: $message';
}

/// Factory helpers
class AppError {
  static AppException network([String? m]) =>
      AppException('network', m ?? 'No internet connection');

  static AppException timeout([String? m]) =>
      AppException('network-timeout', m ?? 'Request timed out');

  static AppException notFound([String? m]) =>
      AppException('not-found', m ?? 'City not found');

  static AppException badKey([String? m]) =>
      AppException('bad-api-key', m ?? 'Invalid API key');

  static AppException forbidden([String? m]) =>
      AppException('forbidden', m ?? 'Access forbidden');

  static AppException rateLimited([String? m]) =>
      AppException('rate-limit', m ?? 'Too many requests, try later');

  static AppException server([String? m]) =>
      AppException('server', m ?? 'Server error, try again');

  static AppException locationDenied([String? m]) =>
      AppException('location-denied', m ?? 'Location permission denied');

  static AppException locationDisabled([String? m]) =>
      AppException('location-disabled', m ?? 'Location services disabled');

  static AppException parsing([String? m]) =>
      AppException('parsing', m ?? 'Data format changed');

  static AppException unknown([String? m]) =>
      AppException('unknown', m ?? 'Something went wrong');
}
