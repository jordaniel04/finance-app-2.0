class AuthConstants {
  static const String _user1 = String.fromEnvironment('USER_EMAIL_1');
  static const String _user2 = String.fromEnvironment('USER_EMAIL_2');

  static const List<String> whitelist = [_user1, _user2];

  static bool isAuthorized(String? email) {
    if (email == null || email.isEmpty) return false;

    // Lista de emergencia por si fallan las variables de entorno
    const hardcodedWhitelist = [
      'jordaniel04@gmail.com',
      'becerrasotoleydivanesa@gmail.com',
    ];

    final existsInEnv = whitelist.any(
      (authorized) =>
          authorized.isNotEmpty &&
          authorized.toLowerCase() == email.toLowerCase(),
    );
    final existsInHardcoded = hardcodedWhitelist.any(
      (authorized) => authorized.toLowerCase() == email.toLowerCase(),
    );

    return existsInEnv || existsInHardcoded;
  }
}
