import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _transactionRepository;
  String? _currentUserId;
  StreamSubscription? _transactionSubscription;
  List<TransactionEntity> _allTransactions = [];
  List<CategoryEntity> _categories = [];

  // Guardamos el filtro activo como miembros de la clase
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  TransactionCubit(this._transactionRepository) : super(TransactionInitial());

  Future<void> loadTransactions(String userId, {int? month, int? year}) async {
    // Si ya estamos suscritos al mismo usuario, solo actualizamos el filtro
    if (_currentUserId == userId && _transactionSubscription != null) {
      if (month != null) _selectedMonth = month;
      if (year != null) _selectedYear = year;
      _updateState(_selectedMonth, _selectedYear, _categories);
      return;
    }

    _currentUserId = userId;
    if (month != null) _selectedMonth = month;
    if (year != null) _selectedYear = year;

    emit(TransactionLoading());

    await _transactionSubscription?.cancel();

    _transactionSubscription = _transactionRepository
        .getTransactions(userId)
        .listen(
          (transactions) {
            _allTransactions = transactions;
            _updateState(_selectedMonth, _selectedYear, _categories);
          },
          onError: (_) {
            emit(
              const TransactionError('Error al conectar con la base de datos.'),
            );
          },
        );
  }

  void _updateState(
    int filterMonth,
    int filterYear,
    List<CategoryEntity> categories,
  ) {
    final now = DateTime.now();

    // Ordenamos localmente
    final sortedAll = List<TransactionEntity>.from(_allTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    double incomes = 0;
    double expenses = 0;
    double todayIncomes = 0;
    double todayExpenses = 0;
    double previousBalance = 0;
    final List<TransactionEntity> filteredTransactions = [];

    for (var tx in sortedAll) {
      final isToday =
          tx.date.day == now.day &&
          tx.date.month == now.month &&
          tx.date.year == now.year;

      final isInSelectedPeriod =
          tx.date.month == filterMonth && tx.date.year == filterYear;

      final isBeforeSelectedPeriod =
          tx.date.year < filterYear ||
          (tx.date.year == filterYear && tx.date.month < filterMonth);

      if (isInSelectedPeriod) {
        filteredTransactions.add(tx);
        if (tx.type == TransactionType.income) {
          incomes += tx.amount;
        } else {
          expenses += tx.amount;
        }
      }

      if (isBeforeSelectedPeriod) {
        if (tx.type == TransactionType.income) {
          previousBalance += tx.amount;
        } else {
          previousBalance -= tx.amount;
        }
      }

      if (isToday) {
        if (tx.type == TransactionType.income) {
          todayIncomes += tx.amount;
        } else {
          todayExpenses += tx.amount;
        }
      }
    }

    emit(
      TransactionLoaded(
        transactions: filteredTransactions,
        categories: categories,
        totalBalance: previousBalance + incomes - expenses,
        totalIncomes: incomes,
        totalExpenses: expenses,
        previousBalance: previousBalance,
        todayIncomes: todayIncomes,
        todayExpenses: todayExpenses,
        selectedMonth: filterMonth,
        selectedYear: filterYear,
      ),
    );
  }

  Future<void> changeFilter(int month, int year) async {
    _selectedMonth = month;
    _selectedYear = year;

    final currentState = state;
    if (currentState is TransactionLoaded) {
      _updateState(month, year, currentState.categories);
    } else if (_currentUserId != null) {
      await loadTransactions(_currentUserId!, month: month, year: year);
    }
  }

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;

    try {
      final expenseCategories = await _transactionRepository.getCategories(
        TransactionType.expense,
      );
      final incomeCategories = await _transactionRepository.getCategories(
        TransactionType.income,
      );

      _categories = [...expenseCategories, ...incomeCategories];

      final currentState = state;
      if (currentState is TransactionLoaded) {
        _updateState(
          currentState.selectedMonth,
          currentState.selectedYear,
          _categories,
        );
      }
    } catch (_) {}
  }

  List<CategoryEntity> get allCategories => List.unmodifiable(_categories);
  List<TransactionEntity> get allTransactions => List.unmodifiable(_allTransactions);

  // ─── Datos para Reportes (calculados desde memoria, sin Firestore) ──────────

  /// Gastos agrupados por categoría para el mes/año seleccionado.
  Map<String, double> getExpensesByCategory(int month, int year) {
    final result = <String, double>{};
    for (final tx in _allTransactions) {
      if (tx.type != TransactionType.expense) continue;
      if (tx.date.month != month || tx.date.year != year) continue;
      result[tx.categoryId] = (result[tx.categoryId] ?? 0) + tx.amount;
    }
    return result;
  }

  /// Ingresos agrupados por categoría para el mes/año seleccionado.
  Map<String, double> getIncomesByCategory(int month, int year) {
    final result = <String, double>{};
    for (final tx in _allTransactions) {
      if (tx.type != TransactionType.income) continue;
      if (tx.date.month != month || tx.date.year != year) continue;
      result[tx.categoryId] = (result[tx.categoryId] ?? 0) + tx.amount;
    }
    return result;
  }

  /// Acumulado mensual por categoría durante un año completo.
  /// Retorna mapa de categoryId → lista de 12 montos (enero=0 … diciembre=11).
  Map<String, List<double>> getAnnualByCategory(int year, TransactionType type) {
    final result = <String, List<double>>{};
    for (final tx in _allTransactions) {
      if (tx.type != type) continue;
      if (tx.date.year != year) continue;
      result.putIfAbsent(tx.categoryId, () => List.filled(12, 0.0));
      result[tx.categoryId]![tx.date.month - 1] += tx.amount;
    }
    return result;
  }

  /// Transacciones de una categoría específica en un mes/año.
  List<TransactionEntity> getTransactionsByCategory(
    String categoryId,
    int month,
    int year,
  ) {
    return _allTransactions
        .where(
          (tx) =>
              tx.categoryId == categoryId &&
              tx.date.month == month &&
              tx.date.year == year,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Totales de ingresos y egresos por mes para los últimos [months] meses.
  /// Retorna lista ordenada del más antiguo al más reciente.
  List<({int month, int year, double incomes, double expenses})>
  getMonthlyTrend(int months) {
    final now = DateTime.now();
    final result =
        <({int month, int year, double incomes, double expenses})>[];

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      double inc = 0, exp = 0;
      for (final tx in _allTransactions) {
        if (tx.date.month != date.month || tx.date.year != date.year) continue;
        if (tx.type == TransactionType.income) {
          inc += tx.amount;
        } else {
          exp += tx.amount;
        }
      }
      result.add((month: date.month, year: date.year, incomes: inc, expenses: exp));
    }
    return result;
  }

  /// Top [limit] transacciones de egreso del mes/año seleccionado, ordenadas por monto.
  List<TransactionEntity> getTopExpenses(int month, int year, {int limit = 5}) {
    final filtered = _allTransactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.date.month == month &&
              tx.date.year == year,
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return filtered.take(limit).toList();
  }

  // ────────────────────────────────────────────────────────────────────────────

  Future<void> addTransaction(TransactionEntity transaction) async {
    try {
      await _transactionRepository.addTransaction(transaction);
    } catch (e) {
      emit(const TransactionError('Error al añadir la transacción.'));
    }
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    try {
      await _transactionRepository.updateTransaction(transaction);
    } catch (e) {
      emit(const TransactionError('Error al actualizar la transacción.'));
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _transactionRepository.deleteTransaction(id);
    } catch (e) {
      emit(const TransactionError('Error al eliminar la transacción.'));
    }
  }

  @override
  Future<void> close() {
    _transactionSubscription?.cancel();
    return super.close();
  }
}
