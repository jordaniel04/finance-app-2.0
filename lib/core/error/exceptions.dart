class ServerException implements Exception {}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
