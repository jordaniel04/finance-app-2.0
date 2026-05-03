import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/icon_map.dart';
import '../../data/repositories/ai_tip_repository.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/auth_state.dart';
import '../widgets/ai_tip_banner.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../blocs/transaction_cubit.dart';
import '../blocs/transaction_state.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedMonth;
  late int _selectedYear;
  String? _pendingCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMonthPicker() {
    final c = AppColors.of(context);
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
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
                  final isSelected = i + 1 == tempMonth;
                  return GestureDetector(
                    onTap: () => setS(() => tempMonth = i + 1),
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
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Cancelar', style: TextStyle(color: c.iconMuted)),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: c.primary),
              onPressed: () {
                setState(() {
                  _selectedMonth = tempMonth;
                  _selectedYear = tempYear;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text('Reportes',
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        actions: [
          GestureDetector(
            onTap: _showMonthPicker,
            child: Container(
              margin:
                  const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Mes',
                          style: TextStyle(
                              color: c.iconMuted, fontSize: 10)),
                      Text('$_selectedMonth/$_selectedYear',
                          style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.calendar_month_rounded,
                      color: c.textSecondary, size: 18),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: c.primary,
          labelColor: c.textPrimary,
          unselectedLabelColor: c.iconMuted,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Mensual'),
            Tab(text: 'Anual'),
            Tab(text: 'Detalle'),
            Tab(text: 'Comparar'),
            Tab(text: 'Consejos IA'),
          ],
        ),
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading || state is TransactionInitial) {
            return Center(
                child:
                    CircularProgressIndicator(color: c.primary));
          }
          if (state is TransactionError) {
            return Center(
                child: Text(state.message,
                    style: TextStyle(color: c.textSecondary)));
          }
          if (state is! TransactionLoaded) return const SizedBox.shrink();

          final cubit = context.read<TransactionCubit>();
          final categories = cubit.allCategories;

          return TabBarView(
            controller: _tabController,
            children: [
              _MensualTab(
                month: _selectedMonth,
                year: _selectedYear,
                cubit: cubit,
                categories: categories,
                onCategoryTap: (catId) {
                  setState(() => _pendingCategoryId = catId);
                  _tabController.animateTo(2);
                },
              ),
              _AnualTab(
                  year: _selectedYear,
                  cubit: cubit,
                  categories: categories),
              _DetalleTab(
                month: _selectedMonth,
                year: _selectedYear,
                cubit: cubit,
                categories: categories,
                initialCategoryId: _pendingCategoryId,
              ),
              _CompararTab(
                month: _selectedMonth,
                year: _selectedYear,
                cubit: cubit,
                categories: categories,
              ),
              const _IaHistoryTab(),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — MENSUAL
// ═══════════════════════════════════════════════════════════════════════════════

class _MensualTab extends StatelessWidget {
  final int month;
  final int year;
  final TransactionCubit cubit;
  final List<CategoryEntity> categories;
  final void Function(String) onCategoryTap;

  const _MensualTab({
    required this.month,
    required this.year,
    required this.cubit,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final expenses = cubit.getExpensesByCategory(month, year);
    final incomes = cubit.getIncomesByCategory(month, year);

    if (expenses.isEmpty && incomes.isEmpty) {
      return const _EmptyState(message: 'Sin transacciones\npara este período.');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AiTipCard(),
        const SizedBox(height: 16),
        if (expenses.isNotEmpty) ...[
          _SectionHeader(
              label: 'Egresos', color: AppColors.expense),
          const SizedBox(height: 12),
          _CategoryDonut(
              dataByCategory: expenses,
              categories: categories,
              onCategoryTap: onCategoryTap),
          const SizedBox(height: 8),
          _CategoryBars(
              dataByCategory: expenses,
              categories: categories,
              onCategoryTap: onCategoryTap),
          const SizedBox(height: 24),
        ],
        if (incomes.isNotEmpty) ...[
          _SectionHeader(
              label: 'Ingresos', color: AppColors.income),
          const SizedBox(height: 12),
          _CategoryDonut(
              dataByCategory: incomes,
              categories: categories,
              onCategoryTap: onCategoryTap),
          const SizedBox(height: 8),
          _CategoryBars(
              dataByCategory: incomes,
              categories: categories,
              onCategoryTap: onCategoryTap),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — ANUAL
// ═══════════════════════════════════════════════════════════════════════════════

class _AnualTab extends StatefulWidget {
  final int year;
  final TransactionCubit cubit;
  final List<CategoryEntity> categories;

  const _AnualTab(
      {required this.year,
      required this.cubit,
      required this.categories});

  @override
  State<_AnualTab> createState() => _AnualTabState();
}

class _AnualTabState extends State<_AnualTab> {
  TransactionType _type = TransactionType.expense;
  String? _expandedCategoryId;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final data = widget.cubit.getAnnualByCategory(widget.year, _type);
    final typeColor =
        _type == TransactionType.expense ? AppColors.expense : AppColors.income;

    final grandTotal = data.values.fold(
        0.0, (sum, months) => sum + months.fold(0.0, (s, v) => s + v));

    final sorted = data.entries.toList()
      ..sort((a, b) {
        final ta = a.value.fold(0.0, (s, v) => s + v);
        final tb = b.value.fold(0.0, (s, v) => s + v);
        return tb.compareTo(ta);
      });

    return Column(
      children: [
        // Toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: c.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.inputBorder),
            ),
            child: Row(
              children: [
                _TypeChip(
                  label: 'Egresos',
                  selected: _type == TransactionType.expense,
                  color: AppColors.expense,
                  onTap: () => setState(() {
                    _type = TransactionType.expense;
                    _expandedCategoryId = null;
                  }),
                ),
                _TypeChip(
                  label: 'Ingresos',
                  selected: _type == TransactionType.income,
                  color: AppColors.income,
                  onTap: () => setState(() {
                    _type = TransactionType.income;
                    _expandedCategoryId = null;
                  }),
                ),
              ],
            ),
          ),
        ),

        if (data.isEmpty)
          const Expanded(
              child: _EmptyState(message: 'Sin datos para este año.'))
        else ...[
          // Total del año
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total ${widget.year}',
                    style: TextStyle(color: c.iconMuted, fontSize: 13)),
                Text(
                  NumberFormat.currency(
                          locale: 'en_US', symbol: 'S/.', decimalDigits: 2)
                      .format(grandTotal),
                  style: TextStyle(
                      color: typeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final entry = sorted[index];
                final cat = widget.categories
                    .where((c) => c.id == entry.key)
                    .firstOrNull;
                final color = cat != null
                    ? Color(cat.colorValue)
                    : _fallbackColor(index);
                final name = cat?.name ?? 'Sin categoría';
                final icon = cat != null
                    ? iconDataFromName(cat.iconName)
                    : Icons.label_outline;
                final monthly = entry.value;
                final total = monthly.fold(0.0, (s, v) => s + v);
                final ratio = grandTotal > 0 ? total / grandTotal : 0.0;
                final isExpanded = _expandedCategoryId == entry.key;

                return _AnualCategoryCard(
                  key: ValueKey(entry.key),
                  name: name,
                  icon: icon,
                  color: color,
                  total: total,
                  ratio: ratio,
                  monthly: monthly,
                  year: widget.year,
                  isExpanded: isExpanded,
                  onTap: () => setState(() {
                    _expandedCategoryId = isExpanded ? null : entry.key;
                  }),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _AnualCategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final double total;
  final double ratio;
  final List<double> monthly;
  final int year;
  final bool isExpanded;
  final VoidCallback onTap;

  const _AnualCategoryCard({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.total,
    required this.ratio,
    required this.monthly,
    required this.year,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: 'S/.', decimalDigits: 2);
    const monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Sep.', 'Octubre', 'Noviembre', 'Dic.',
    ];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? color.withValues(alpha: 0.4)
                : c.surfaceBorder,
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon, color: color, size: 17),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(name,
                            style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text(fmt.format(total),
                          style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.expand_more_rounded,
                            color: c.textMuted, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (_, constraints) => Stack(
                      children: [
                        Container(
                          height: 4, width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: c.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 4,
                          width: constraints.maxWidth * ratio,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(ratio * 100).toStringAsFixed(1)}% del total',
                      style:
                          TextStyle(color: c.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              Container(
                  height: 1, color: color.withValues(alpha: 0.15)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  children: List.generate(12, (i) {
                    final val = monthly[i];
                    final maxMonth =
                        monthly.fold(0.0, (a, b) => a > b ? a : b);
                    final barRatio =
                        maxMonth > 0 ? val / maxMonth : 0.0;
                    final hasData = val > 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              monthNames[i].substring(0, 3),
                              style: TextStyle(
                                color: hasData
                                    ? c.textSecondary
                                    : c.textDisabled,
                                fontSize: 11,
                                fontWeight: hasData
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (_, constraints) => Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    width: constraints.maxWidth,
                                    decoration: BoxDecoration(
                                      color: c.divider,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                  if (hasData)
                                    Container(
                                      height: 6,
                                      width: constraints.maxWidth *
                                          barRatio,
                                      decoration: BoxDecoration(
                                        color:
                                            color.withValues(alpha: 0.7),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 90,
                            child: Text(
                              hasData ? fmt.format(val) : '—',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: hasData
                                    ? c.textSecondary
                                    : c.textDisabled,
                                fontSize: 12,
                                fontWeight: hasData
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — DETALLE
// ═══════════════════════════════════════════════════════════════════════════════

class _DetalleTab extends StatefulWidget {
  final int month;
  final int year;
  final TransactionCubit cubit;
  final List<CategoryEntity> categories;
  final String? initialCategoryId;

  const _DetalleTab({
    required this.month,
    required this.year,
    required this.cubit,
    required this.categories,
    this.initialCategoryId,
  });

  @override
  State<_DetalleTab> createState() => _DetalleTabState();
}

class _DetalleTabState extends State<_DetalleTab> {
  CategoryEntity? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _syncCategory();
  }

  @override
  void didUpdateWidget(_DetalleTab old) {
    super.didUpdateWidget(old);
    if (widget.initialCategoryId != old.initialCategoryId) {
      _syncCategory();
    }
  }

  void _syncCategory() {
    if (widget.initialCategoryId != null) {
      _selectedCategory = widget.categories
          .where((c) => c.id == widget.initialCategoryId)
          .firstOrNull;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: 'S/.', decimalDigits: 2);
    final dateFmt = DateFormat("d MMM '·' HH:mm", 'es_PE');

    final expenseIds =
        widget.cubit.getExpensesByCategory(widget.month, widget.year).keys.toSet();
    final incomeIds =
        widget.cubit.getIncomesByCategory(widget.month, widget.year).keys.toSet();

    final expenseCategories = widget.categories
        .where((cat) => expenseIds.contains(cat.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final incomeCategories = widget.categories
        .where((cat) => incomeIds.contains(cat.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (expenseCategories.isEmpty && incomeCategories.isEmpty) {
      return const _EmptyState(
          message: 'Sin transacciones\npara este período.');
    }

    final transactions = _selectedCategory != null
        ? widget.cubit.getTransactionsByCategory(
            _selectedCategory!.id, widget.month, widget.year)
        : <TransactionEntity>[];

    return Column(
      children: [
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expenseCategories.isNotEmpty) ...[
                Text('EGRESOS',
                    style: TextStyle(
                        color: c.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                _CategoryChipsRow(
                  categories: expenseCategories,
                  selectedId: _selectedCategory?.id,
                  onTap: (cat) =>
                      setState(() => _selectedCategory = cat),
                ),
              ],
              if (expenseCategories.isNotEmpty &&
                  incomeCategories.isNotEmpty)
                const SizedBox(height: 12),
              if (incomeCategories.isNotEmpty) ...[
                Text('INGRESOS',
                    style: TextStyle(
                        color: c.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                _CategoryChipsRow(
                  categories: incomeCategories,
                  selectedId: _selectedCategory?.id,
                  onTap: (cat) =>
                      setState(() => _selectedCategory = cat),
                ),
              ],
            ],
          ),
        ),
        Container(height: 1, color: c.surfaceBorder),

        if (_selectedCategory == null)
          Expanded(
            child: _EmptyState(
                message: 'Selecciona una categoría\npara ver el detalle.'),
          )
        else if (transactions.isEmpty)
          const Expanded(
            child: _EmptyState(
                message: 'Sin transacciones\nen esta categoría.'),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: transactions.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final tx = transactions[i];
                final isIncome = tx.type == TransactionType.income;
                final color =
                    isIncome ? AppColors.income : AppColors.expense;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description.isNotEmpty
                                  ? tx.description
                                  : '(sin descripción)',
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(dateFmt.format(tx.date),
                                style: TextStyle(
                                    color: c.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}${fmt.format(tx.amount)}',
                        style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS COMPARTIDOS
// ═══════════════════════════════════════════════════════════════════════════════

class _CategoryChipsRow extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedId;
  final void Function(CategoryEntity) onTap;

  const _CategoryChipsRow({
    required this.categories,
    required this.selectedId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = selectedId == cat.id;
          final color = Color(cat.colorValue);
          return GestureDetector(
            onTap: () => onTap(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : c.inputFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : c.inputBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      iconDataFromName(cat.iconName),
                      color: isSelected ? color : c.iconMuted,
                      size: 13),
                  const SizedBox(width: 6),
                  Text(cat.name,
                      style: TextStyle(
                        color: isSelected ? color : c.iconMuted,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 16,
            color: color,
            margin: const EdgeInsets.only(right: 8)),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CategoryDonut extends StatefulWidget {
  final Map<String, double> dataByCategory;
  final List<CategoryEntity> categories;
  final void Function(String) onCategoryTap;

  const _CategoryDonut({
    required this.dataByCategory,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  State<_CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<_CategoryDonut> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: 'S/.', decimalDigits: 2);
    final entries = widget.dataByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);

    final sections = entries.asMap().entries.map((e) {
      final idx = e.key;
      final entry = e.value;
      final cat =
          widget.categories.where((c) => c.id == entry.key).firstOrNull;
      final color =
          cat != null ? Color(cat.colorValue) : _fallbackColor(idx);
      final isTouched = idx == _touchedIndex;
      final pct = total > 0 ? entry.value / total * 100 : 0.0;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 60 : 48,
        titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.surfaceBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 46,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = response!
                          .touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...entries.asMap().entries.map((e) {
            final idx = e.key;
            final entry = e.value;
            final cat = widget.categories
                .where((c) => c.id == entry.key)
                .firstOrNull;
            final color =
                cat != null ? Color(cat.colorValue) : _fallbackColor(idx);
            final name = cat?.name ?? 'Sin categoría';
            final pct = total > 0 ? entry.value / total * 100 : 0.0;
            return GestureDetector(
              onTap: () => widget.onCategoryTap(entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(name,
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 13))),
                    Text('${pct.toStringAsFixed(1)}%',
                        style:
                            TextStyle(color: c.textMuted, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text(fmt.format(entry.value),
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        color: c.textDisabled, size: 16),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryBars extends StatelessWidget {
  final Map<String, double> dataByCategory;
  final List<CategoryEntity> categories;
  final void Function(String) onCategoryTap;

  const _CategoryBars({
    required this.dataByCategory,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: 'S/.', decimalDigits: 2);
    final entries = dataByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.first.value;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.surfaceBorder),
      ),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          final cat =
              categories.where((c) => c.id == entry.key).firstOrNull;
          final color =
              cat != null ? Color(cat.colorValue) : _fallbackColor(idx);
          final icon = cat != null
              ? iconDataFromName(cat.iconName)
              : Icons.label_outline;
          final name = cat?.name ?? 'Sin categoría';
          final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;

          return GestureDetector(
            onTap: () => onCategoryTap(entry.key),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(name,
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(fmt.format(entry.value),
                          style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          color: c.textDisabled, size: 16),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (_, constraints) => Stack(
                      children: [
                        Container(
                          height: 5,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: c.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 5,
                          width: constraints.maxWidth * ratio,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? color : c.iconMuted,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              )),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, color: c.textDisabled, size: 56),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 15)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4 — COMPARAR
// ═══════════════════════════════════════════════════════════════════════════════

class _CompararTab extends StatefulWidget {
  final int month;
  final int year;
  final TransactionCubit cubit;
  final List<CategoryEntity> categories;

  const _CompararTab({
    required this.month,
    required this.year,
    required this.cubit,
    required this.categories,
  });

  @override
  State<_CompararTab> createState() => _CompararTabState();
}

class _CompararTabState extends State<_CompararTab> {
  final Set<String> _selectedIncomeIds = {};
  final Set<String> _selectedExpenseIds = {};

  List<CategoryEntity> get _incomeCategories => widget.categories
      .where((c) => c.type == TransactionType.income)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  List<CategoryEntity> get _expenseCategories => widget.categories
      .where((c) => c.type == TransactionType.expense)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  double _totalForIds(Set<String> ids, TransactionType type) {
    if (ids.isEmpty) return 0;
    final expenses = type == TransactionType.expense
        ? widget.cubit.getExpensesByCategory(widget.month, widget.year)
        : widget.cubit.getIncomesByCategory(widget.month, widget.year);
    return ids.fold(0.0, (sum, id) => sum + (expenses[id] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: 'S/.', decimalDigits: 2);

    final totalIncome = _totalForIds(_selectedIncomeIds, TransactionType.income);
    final totalExpense = _totalForIds(_selectedExpenseIds, TransactionType.expense);
    final result = totalIncome - totalExpense;
    final isPositive = result >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sección ingresos
        _CompararSection(
          label: 'INGRESOS',
          color: AppColors.income,
          categories: _incomeCategories,
          selectedIds: _selectedIncomeIds,
          amountsByCategory: widget.cubit.getIncomesByCategory(widget.month, widget.year),
          onToggle: (id) => setState(() {
            if (_selectedIncomeIds.contains(id)) {
              _selectedIncomeIds.remove(id);
            } else {
              _selectedIncomeIds.add(id);
            }
          }),
        ),
        const SizedBox(height: 12),

        // Sección egresos
        _CompararSection(
          label: 'EGRESOS',
          color: AppColors.expense,
          categories: _expenseCategories,
          selectedIds: _selectedExpenseIds,
          amountsByCategory: widget.cubit.getExpensesByCategory(widget.month, widget.year),
          onToggle: (id) => setState(() {
            if (_selectedExpenseIds.contains(id)) {
              _selectedExpenseIds.remove(id);
            } else {
              _selectedExpenseIds.add(id);
            }
          }),
        ),
        const SizedBox(height: 20),

        // Resultado
        if (_selectedIncomeIds.isNotEmpty || _selectedExpenseIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPositive
                    ? AppColors.income.withValues(alpha: 0.4)
                    : AppColors.expense.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ingresos seleccionados',
                        style: TextStyle(color: c.textMuted, fontSize: 13)),
                    Text(fmt.format(totalIncome),
                        style: const TextStyle(
                            color: AppColors.income,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Egresos seleccionados',
                        style: TextStyle(color: c.textMuted, fontSize: 13)),
                    Text(fmt.format(totalExpense),
                        style: const TextStyle(
                            color: AppColors.expense,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: c.divider, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPositive ? 'Ganancia' : 'Déficit',
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      fmt.format(result.abs()),
                      style: TextStyle(
                          color: isPositive ? AppColors.income : AppColors.expense,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_selectedIncomeIds.isNotEmpty && _selectedExpenseIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${fmt.format(totalIncome)} − ${fmt.format(totalExpense)} = ${fmt.format(result)}',
                      style: TextStyle(color: c.textMuted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          )
        else
          _EmptyState(
            message:
                'Selecciona al menos una categoría\npara ver el cálculo.',
          ),
      ],
    );
  }
}

class _CompararSection extends StatelessWidget {
  final String label;
  final Color color;
  final List<CategoryEntity> categories;
  final Set<String> selectedIds;
  final Map<String, double> amountsByCategory;
  final void Function(String) onToggle;

  const _CompararSection({
    required this.label,
    required this.color,
    required this.categories,
    required this.selectedIds,
    required this.amountsByCategory,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: c.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        if (categories.isEmpty)
          Text('Sin categorías de este tipo.',
              style: TextStyle(color: c.textMuted, fontSize: 13))
        else
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = categories[i];
                final isSelected = selectedIds.contains(cat.id);
                final catColor = Color(cat.colorValue);
                final icon =
                    iconDataFromName(cat.iconName);
                return GestureDetector(
                  onTap: () => onToggle(cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? catColor.withValues(alpha: 0.2)
                          : c.inputFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? catColor : c.inputBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            color: isSelected ? catColor : c.iconMuted,
                            size: 13),
                        const SizedBox(width: 6),
                        Text(cat.name,
                            style: TextStyle(
                              color: isSelected ? catColor : c.iconMuted,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 5 — CONSEJOS IA
// ═══════════════════════════════════════════════════════════════════════════════

class _IaHistoryTab extends StatefulWidget {
  const _IaHistoryTab();

  @override
  State<_IaHistoryTab> createState() => _IaHistoryTabState();
}

class _IaHistoryTabState extends State<_IaHistoryTab> {
  final List<AiTipEntry> _entries = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  static const _pageSize = 7;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      setState(() => _loading = false);
      return;
    }
    final userId = authState.user.id;
    final lastDoc = _entries.isNotEmpty ? _entries.last.snapshot : null;
    final page = await context.read<AiTipRepository>().getHistory(
          userId,
          startAfter: lastDoc,
          pageSize: _pageSize,
        );
    if (mounted) {
      setState(() {
        _entries.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final dateFmt = DateFormat("EEEE d 'de' MMMM yyyy", 'es_PE');

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, color: c.textDisabled, size: 48),
            const SizedBox(height: 16),
            Text(
              'Aún no hay consejos guardados.\nAparecerán aquí cada día.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == _entries.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: _loadingMore
                  ? CircularProgressIndicator(color: c.primary)
                  : TextButton.icon(
                      onPressed: _loadMore,
                      icon: Icon(Icons.expand_more_rounded, color: c.primary),
                      label: Text('Cargar más',
                          style: TextStyle(color: c.primary)),
                    ),
            ),
          );
        }
        final entry = _entries[i];
        final dateLabel = dateFmt.format(entry.generatedAt);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: c.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                entry.tip,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _fallbackColor(int index) {
  const colors = [
    Color(0xFF5C6BC0), Color(0xFF26C6DA), Color(0xFFFFCA28),
    Color(0xFFEC407A), Color(0xFF66BB6A), Color(0xFFFF7043),
  ];
  return colors[index % colors.length];
}
