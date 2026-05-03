import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/ai_tip_repository.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';

part 'ai_tip_state.dart';

class AiTipCubit extends Cubit<AiTipState> {
  final AiTipRepository _repository;
  bool _dismissedToday = false;

  AiTipCubit(this._repository) : super(AiTipInitial());

  Future<void> loadTip(
    String userId,
    List<TransactionEntity> transactions,
    List<CategoryEntity> categories,
  ) async {
    if (state is AiTipLoaded) return;
    emit(AiTipLoading());
    try {
      final tip = await _repository.getTodayTip(userId, transactions, categories);
      emit(AiTipLoaded(tip: tip, dismissed: _dismissedToday));
    } catch (e) {
      emit(AiTipError(e.toString()));
    }
  }

  void dismiss() {
    _dismissedToday = true;
    if (state is AiTipLoaded) {
      emit((state as AiTipLoaded).copyWith(dismissed: true));
    }
  }
}
