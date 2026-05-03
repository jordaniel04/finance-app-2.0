import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  final List<CategoryEntity> categories;
  final double totalBalance;
  final double totalIncomes;
  final double totalExpenses;
  final double previousBalance;
  final double todayIncomes;
  final double todayExpenses;
  final int selectedMonth;
  final int selectedYear;

  const TransactionLoaded({
    required this.transactions,
    required this.categories,
    required this.totalBalance,
    required this.totalIncomes,
    required this.totalExpenses,
    required this.previousBalance,
    required this.todayIncomes,
    required this.todayExpenses,
    required this.selectedMonth,
    required this.selectedYear,
  });

  @override
  List<Object?> get props => [
    transactions,
    categories,
    totalBalance,
    totalIncomes,
    totalExpenses,
    previousBalance,
    todayIncomes,
    todayExpenses,
    selectedMonth,
    selectedYear,
  ];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}
