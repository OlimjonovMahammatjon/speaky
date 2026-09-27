class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'A server exception occurred']);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'A cache exception occurred']);

  @override
  String toString() => 'CacheException: $message';
}
