import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthRepositoryImpl({firebase_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Stream<UserEntity?> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );
    });
  }

  @override
  Future<void> handleRedirectResult() async {
    try {
      await _firebaseAuth.getRedirectResult();
    } catch (_) {}
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      final provider = firebase_auth.GoogleAuthProvider();
      final firebase_auth.UserCredential credential =
          await _firebaseAuth.signInWithPopup(provider);

      final firebaseUser = credential.user;
      if (firebaseUser == null) return null;

      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException();
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con diferentes credenciales.';
      case 'invalid-credential':
        return 'Las credenciales de acceso son inválidas.';
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexión.';
      default:
        return 'Ocurrió un error inesperado al acceder con Google.';
    }
  }
}
