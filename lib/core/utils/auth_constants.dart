class AuthConstants {
  static const String _user1 = String.fromEnvironment('USER_EMAIL_1');
  static const String _user2 = String.fromEnvironment('USER_EMAIL_2');

  static const List<String> whitelist = [
    _user1,
    _user2,
  ];

  static bool isAuthorized(String? email) {
    if (email == null || email.isEmpty) return false;
    return whitelist.any((authorized) => authorized.toLowerCase() == email.toLowerCase());
  }
}
