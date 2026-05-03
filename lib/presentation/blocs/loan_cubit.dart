import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/repositories/loan_repository.dart';
import 'loan_state.dart';

class LoanCubit extends Cubit<LoanState> {
  final LoanRepository _repository;
  StreamSubscription? _subscription;

  LoanCubit(this._repository) : super(LoanInitial());

  void loadLoans(String userId) {
    emit(LoanLoading());
    _subscription?.cancel();
    _subscription = _repository.getLoans(userId).listen(
          (loans) {
            final sorted = [...loans]..sort((a, b) => b.date.compareTo(a.date));
            emit(LoanLoaded(sorted));
          },
          onError: (_) => emit(const LoanError('Error al cargar préstamos.')),
        );
  }

  Future<void> addLoan(LoanEntity loan) async {
    try {
      await _repository.addLoan(loan);
    } catch (_) {
      emit(const LoanError('Error al guardar el préstamo.'));
    }
  }

  Future<void> updateLoan(LoanEntity loan) async {
    try {
      await _repository.updateLoan(loan);
    } catch (_) {
      emit(const LoanError('Error al actualizar el préstamo.'));
    }
  }

  Future<void> deleteLoan(String loanId) async {
    try {
      await _repository.deleteLoan(loanId);
    } catch (_) {
      emit(const LoanError('Error al eliminar el préstamo.'));
    }
  }

  Future<void> addPayment(String loanId, LoanPaymentEntity payment) async {
    try {
      await _repository.addPayment(loanId, payment);
    } catch (_) {
      emit(const LoanError('Error al registrar el pago.'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
