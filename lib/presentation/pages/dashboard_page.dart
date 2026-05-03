import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/icon_map.dart';
import '../blocs/transaction_cubit.dart';
import '../blocs/transaction_state.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/entities/category_entity.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/auth_state.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/ai_tip_banner.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () {},
        ),
        title: Text(
          'Transacciones',
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [_MonthPickerButton()],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final isLoading =
              state is TransactionLoading || state is TransactionInitial;

          if (state is TransactionError) {
            return Center(
              child: Text(state.message,
                  style: TextStyle(color: c.textSecondary)),
            );
          }

          final displayState = isLoading
              ? TransactionLoaded(
                  transactions: List.generate(
                    5,
                    (index) => TransactionEntity(
                      id: 'skel$index',
                      amount: 0,
                      description: 'Cargando datos...',
                      date: DateTime.now(),
                      categoryId: '',
                      type: TransactionType.expense,
                      userId: '',
                    ),
                  ),
                  categories: [],
                  totalBalance: 0,
                  totalIncomes: 0,
                  totalExpenses: 0,
                  previousBalance: 0,
                  todayIncomes: 0,
                  todayExpenses: 0,
                  selectedMonth: DateTime.now().month,
                  selectedYear: DateTime.now().year,
                )
              : (state as TransactionLoaded);

          return Skeletonizer(
            enabled: isLoading,
            child: Column(
              children: [
                const AiTipBanner(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () {
                      final authState =
                          context.read<AuthCubit>().state as Authenticated;
                      return context
                          .read<TransactionCubit>()
                          .loadTransactions(
                            authState.user.id,
                            month: displayState.selectedMonth,
                            year: displayState.selectedYear,
                          );
                    },
                    child: _buildDayGroupList(context, displayState, isLoading),
                  ),
                ),
                _BottomSummaryBar(state: displayState),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_dashboard',
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: c.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildDayGroupList(
      BuildContext context, TransactionLoaded state, bool isLoading) {
    final c = AppColors.of(context);
    if (state.transactions.isEmpty && !isLoading) {
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_rounded, color: c.textDisabled, size: 64),
                const SizedBox(height: 16),
                Text(
                  'No hay transacciones aún.\n¡Empieza a registrar tus movimientos!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textMuted, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Map<String, List<TransactionEntity>> grouped = {};
    for (var tx in state.transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(tx);
    }
    final dayKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: dayKeys.length,
      itemBuilder: (context, index) {
        final dayKey = dayKeys[index];
        final dayTransactions = grouped[dayKey]!;
        return _DayGroup(
          date: dayTransactions.first.date,
          transactions: dayTransactions,
          categories: state.categories,
          isInitiallyExpanded: index == 0,
        );
      },
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionCubit>(),
        child: BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: const AddTransactionDialog(),
        ),
      ),
    );
  }
}

// ─── Month Picker Button ────────────────────────────────────────────────────

class _MonthPickerButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) return const SizedBox.shrink();
        return InkWell(
          onTap: () => _showMonthPicker(context, state),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.divider,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Mes',
                        style:
                            TextStyle(color: c.iconMuted, fontSize: 10)),
                    Text(
                      '${state.selectedMonth}/${state.selectedYear}',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(Icons.calendar_month_rounded,
                    color: c.textSecondary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonthPicker(BuildContext context, TransactionLoaded state) {
    final c = AppColors.of(context);
    int tempMonth = state.selectedMonth;
    int tempYear = state.selectedYear;
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: c.surface,
          title: Text('Seleccionar Mes',
              style: TextStyle(color: c.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: c.textPrimary),
                    onPressed: () => setS(() => tempYear--),
                  ),
                  Text('$tempYear',
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: c.textPrimary),
                    onPressed: () => setS(() => tempYear++),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final isSelected = m == tempMonth;
                  return GestureDetector(
                    onTap: () => setS(() => tempMonth = m),
                    child: Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? c.primary
                            : c.monthChipUnselected,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        months[i].substring(0, 3),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : c.iconMuted,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancelar',
                  style: TextStyle(color: c.iconMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary),
              onPressed: () {
                context.read<TransactionCubit>().changeFilter(
                    tempMonth, tempYear);
                Navigator.pop(dialogContext);
              },
              child: const Text('Aplicar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Day Group ──────────────────────────────────────────────────────────────

class _DayGroup extends StatefulWidget {
  final DateTime date;
  final List<TransactionEntity> transactions;
  final List<CategoryEntity> categories;
  final bool isInitiallyExpanded;

  const _DayGroup({
    required this.date,
    required this.transactions,
    required this.categories,
    this.isInitiallyExpanded = false,
  });

  @override
  State<_DayGroup> createState() => _DayGroupState();
}

class _DayGroupState extends State<_DayGroup> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: 'S/.', decimalDigits: 2);

    double dayIncomes = 0;
    double dayExpenses = 0;
    for (var tx in widget.transactions) {
      if (tx.type == TransactionType.income) {
        dayIncomes += tx.amount;
      } else {
        dayExpenses += tx.amount;
      }
    }

    final dayName =
        _cap(DateFormat.EEEE('es_PE').format(widget.date));
    final monthName =
        _cap(DateFormat.MMMM('es_PE').format(widget.date));
    final dateLabel =
        '$dayName, ${widget.date.day} $monthName ${widget.date.year}';

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(
                bottom: BorderSide(color: c.divider),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(dateLabel,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14)),
                ),
                if (dayIncomes > 0) ...[
                  Text('+${fmt.format(dayIncomes)}',
                      style: const TextStyle(
                          color: AppColors.income,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(width: 8),
                ],
                if (dayExpenses > 0)
                  Text('-${fmt.format(dayExpenses)}',
                      style: const TextStyle(
                          color: AppColors.expense,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                const SizedBox(width: 12),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: c.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            color: c.background,
            child: Column(
              children: widget.transactions
                  .map((tx) => _TransactionRow(
                        transaction: tx,
                        categories: widget.categories,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Transaction Row ────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  final TransactionEntity transaction;
  final List<CategoryEntity> categories;

  const _TransactionRow(
      {required this.transaction, required this.categories});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: 'S/.', decimalDigits: 2);
    final isIncome = transaction.type == TransactionType.income;
    final timeStr = DateFormat.Hm().format(transaction.date);

    CategoryEntity? category;
    try {
      category =
          categories.firstWhere((c) => c.id == transaction.categoryId);
    } catch (_) {
      category = null;
    }

    final categoryName = category?.name ?? 'Sin categoría';
    final categoryColor =
        category != null ? Color(category.colorValue) : Colors.grey;
    final categoryIcon = category != null
        ? iconDataFromName(category.iconName)
        : Icons.label_outline;

    return InkWell(
      onTap: () {
        final authCubit = context.read<AuthCubit>();
        final transactionCubit = context.read<TransactionCubit>();
        showDialog(
          context: context,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: transactionCubit),
              BlocProvider.value(value: authCubit),
            ],
            child: AddTransactionDialog(transaction: transaction),
          ),
        );
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(timeStr,
                  style: TextStyle(
                      color: c.iconMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(categoryIcon, color: categoryColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(categoryName,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (transaction.description.isNotEmpty)
                    Text(transaction.description,
                        style: TextStyle(
                            color: c.textMuted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(
              '${isIncome ? "+" : "-"}${fmt.format(transaction.amount)}',
              style: TextStyle(
                color: isIncome
                    ? AppColors.income
                    : AppColors.expense,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Summary Bar ─────────────────────────────────────────────────────

class _BottomSummaryBar extends StatelessWidget {
  final TransactionLoaded state;
  const _BottomSummaryBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: 'S/.', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.summaryBar,
        border: Border(
            top: BorderSide(color: c.primary, width: 1.5)),
      ),
      child: Row(
        children: [
          _BottomItem(
              label: 'Saldo Anterior',
              value: fmt.format(state.previousBalance),
              color: AppColors.income),
          _Divider(),
          _BottomItem(
              label: 'Ingresos',
              value: '+${fmt.format(state.totalIncomes)}',
              color: AppColors.income),
          _Divider(),
          _BottomItem(
              label: 'Egresos',
              value: '-${fmt.format(state.totalExpenses)}',
              color: AppColors.expense),
          _Divider(),
          _BottomItem(
              label: 'Saldo Total',
              value: fmt.format(state.totalBalance),
              color: c.textPrimary,
              isBold: true),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _BottomItem({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(color: c.iconMuted, fontSize: 10),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: isBold ? 13 : 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: c.divider,
    );
  }
}
