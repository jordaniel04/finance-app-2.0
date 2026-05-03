import '../entities/transaction_entity.dart';
import '../entities/transaction_type.dart';
import '../entities/category_entity.dart';

abstract class TransactionRepository {
  Stream<List<TransactionEntity>> getTransactions(String userId);
  Future<void> addTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String transactionId);
  Future<List<CategoryEntity>> getCategories(TransactionType type);
  Future<void> addCategory(CategoryEntity category);
  Future<void> updateCategory(CategoryEntity category);
  Future<void> deleteCategory(String categoryId);
  Future<void> seedDefaultCategoriesIfEmpty();
}
