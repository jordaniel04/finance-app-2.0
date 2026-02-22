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
    _monitorAuthState();
  }

  void _monitorAuthState() {
    _userSubscription = _authRepository.user.listen((user) async {
      if (user != null) {
        if (AuthConstants.isAuthorized(user.email)) {
          emit(Authenticated(user));
        } else {
          await _authRepository.signOut();
          emit(const AuthError('Acceso denegado: Tu correo no está en la lista de autorizados.'));
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
      if (user == null) {
        emit(Unauthenticated());
        return;
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Ocurrió un error inesperado al acceder con Google.'));
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
