import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/auth_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _userSubscription;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _init();
  }

  void _init() {
    // Usamos directamente el stream de auth para detectar el usuario.
    // No hacemos `await user.first` porque eso bloquea y duplica trabajo.
    // El stream emitirá inmediatamente el estado actual del usuario.
    _userSubscription = _authRepository.user.listen((user) async {
      if (user != null) {
        // Si ya estamos Authenticated con el mismo ID, no re-emitimos
        if (state is Authenticated &&
            (state as Authenticated).user.id == user.id) {
          return;
        }

        final authorized = AuthConstants.isAuthorized(user.email);
        if (authorized) {
          emit(Authenticated(user));
        } else {
          await _authRepository.signOut();
          emit(
            const AuthError(
              'Acceso denegado: Tu correo no está en la lista de autorizados.',
            ),
          );
        }
      } else {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();

      if (user != null) {
        final authorized = AuthConstants.isAuthorized(user.email);
        if (authorized) {
          emit(Authenticated(user));
        } else {
          await _authRepository.signOut();
          emit(
            const AuthError(
              'Acceso denegado: Tu correo no está en la lista de autorizados.',
            ),
          );
        }
      } else {
        emit(Unauthenticated());
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(
        const AuthError('Ocurrió un error inesperado al acceder con Google.'),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      emit(const AuthError('Error al cerrar sesión.'));
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
