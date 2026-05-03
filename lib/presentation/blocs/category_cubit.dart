import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final TransactionRepository _repository;

  CategoryCubit(this._repository) : super(CategoryInitial());

  Future<void> loadCategories() async {
    emit(CategoryLoading());
    try {
      final expenses = await _repository.getCategories(TransactionType.expense);
      final incomes = await _repository.getCategories(TransactionType.income);
      emit(CategoryLoaded([...expenses, ...incomes]));
    } catch (e) {
      emit(const CategoryError('Error al cargar categorías.'));
    }
  }

  Future<void> addCategory(CategoryEntity category) async {
    try {
      await _repository.addCategory(category);
      await loadCategories();
    } catch (e) {
      emit(const CategoryError('Error al agregar categoría.'));
    }
  }

  Future<void> updateCategory(CategoryEntity category) async {
    try {
      await _repository.updateCategory(category);
      await loadCategories();
    } catch (e) {
      emit(const CategoryError('Error al actualizar categoría.'));
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _repository.deleteCategory(categoryId);
      await loadCategories();
    } catch (e) {
      emit(const CategoryError('Error al eliminar categoría.'));
    }
  }
}
