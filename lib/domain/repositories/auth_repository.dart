import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> signInWithGoogle();
  Future<void> signOut();
  Future<void> handleRedirectResult();
  Stream<UserEntity?> get user;
}
