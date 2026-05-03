import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/app_theme.dart';
import '../../data/models/loan_model.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/auth_state.dart';
import '../blocs/loan_cubit.dart';
import '../blocs/loan_state.dart';
import '../blocs/transaction_cubit.dart';

final _currencyFmt = NumberFormat.currency(locale: 'es_PE', symbol: 'S/.');
final _dateFmt = DateFormat('dd/MM/yyyy', 'es_PE');

class LoansPage extends StatelessWidget {
  const LoansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.surface,
          elevation: 0,
          title: Text('Préstamos',
              style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: c.primary,
            unselectedLabelColor: c.textMuted,
            indicatorColor: c.primary,
            tabs: const [
              Tab(text: 'Me deben'),
              Tab(text: 'Debo'),
            ],
          ),
        ),
        body: BlocConsumer<LoanCubit, LoanState>(
          listener: (context, state) {
            if (state is LoanError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is LoanLoading || state is LoanInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LoanLoaded) {
              return TabBarView(
                children: [
                  _LoanList(
                    loans: state.lent,
                    totalPending: state.totalLent,
                    emptyMessage: 'No has prestado dinero',
                    emptyIcon: Icons.volunteer_activism_rounded,
                  ),
                  _LoanList(
                    loans: state.borrowed,
                    totalPending: state.totalBorrowed,
                    emptyMessage: 'No tienes deudas',
                    emptyIcon: Icons.sentiment_satisfied_rounded,
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_loans',
          onPressed: () => _showAddLoanDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo préstamo'),
        ),
      ),
    );
  }

  void _showAddLoanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LoanCubit>(),
        child: _AddLoanDialog(
          authState: context.read<AuthCubit>().state,
          transactionCubit: context.read<TransactionCubit>(),
        ),
      ),
    );
  }
}

// ─── Lista de préstamos ──────────────────────────────────────────────────────

class _LoanList extends StatelessWidget {
  final List<LoanEntity> loans;
  final double totalPending;
  final String emptyMessage;
  final IconData emptyIcon;

  const _LoanList({
    required this.loans,
    required this.totalPending,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, color: c.textDisabled, size: 56),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: TextStyle(color: c.textMuted, fontSize: 15)),
          ],
        ),
      );
    }

    final active = loans.where((l) => l.status == LoanStatus.active).toList();
    final settled =
        loans.where((l) => l.status != LoanStatus.active).toList();

    return Column(
      children: [
        if (totalPending > 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.surfaceBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total pendiente',
                    style: TextStyle(color: c.textMuted, fontSize: 13)),
                Text(
                  _currencyFmt.format(totalPending),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              ...active.map((l) => _LoanCard(loan: l)),
              if (settled.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Expanded(child: Divider(color: c.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Saldados',
                          style: TextStyle(
                              color: c.textDisabled, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: c.divider)),
                  ]),
                ),
                ...settled.map((l) => _LoanCard(loan: l)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta de préstamo ─────────────────────────────────────────────────────

class _LoanCard extends StatelessWidget {
  final LoanEntity loan;
  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isSettled = loan.status == LoanStatus.settled;
    final isDefaulted = loan.status == LoanStatus.defaulted;

    Color statusColor = c.primary;
    if (isSettled) statusColor = AppColors.income;
    if (isDefaulted) statusColor = AppColors.danger;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: c.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loan.counterparty,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _StatusChip(status: loan.status, color: statusColor),
                ],
              ),
              if (loan.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(loan.description,
                    style: TextStyle(color: c.textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Original',
                            style: TextStyle(
                                color: c.textDisabled, fontSize: 11)),
                        Text(
                          _currencyFmt.format(loan.originalAmount),
                          style: TextStyle(
                              color: c.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (loan.interest > 0)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Interés',
                              style: TextStyle(
                                  color: c.textDisabled, fontSize: 11)),
                          Text(
                            _currencyFmt.format(loan.interest),
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Pendiente',
                            style: TextStyle(
                                color: c.textDisabled, fontSize: 11)),
                        Text(
                          _currencyFmt.format(loan.pendingAmount),
                          style: TextStyle(
                            color: isSettled
                                ? AppColors.income
                                : c.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isSettled) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: loan.progressPercent,
                    backgroundColor: c.surfaceBorder,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pagado: ${_currencyFmt.format(loan.paidAmount)}',
                      style:
                          TextStyle(color: c.textDisabled, fontSize: 11),
                    ),
                    Text(
                      _dateFmt.format(loan.date),
                      style:
                          TextStyle(color: c.textDisabled, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<LoanCubit>()),
          BlocProvider.value(value: context.read<TransactionCubit>()),
          BlocProvider.value(value: context.read<AuthCubit>()),
        ],
        child: _LoanDetailSheet(loan: loan),
      ),
    );
  }
}

// ─── Chip de estado ──────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final LoanStatus status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      LoanStatus.active => 'Activo',
      LoanStatus.settled => 'Saldado',
      LoanStatus.defaulted => 'Moroso',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Detalle y pagos ─────────────────────────────────────────────────────────

class _LoanDetailSheet extends StatelessWidget {
  final LoanEntity loan;
  const _LoanDetailSheet({required this.loan});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      loan.counterparty,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (loan.status == LoanStatus.active)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.calendar_today_outlined,
                              color: c.textMuted),
                          tooltip: 'Editar fecha',
                          onPressed: () => _editDate(context),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline,
                              color: c.primary),
                          tooltip: 'Registrar pago',
                          onPressed: () =>
                              _showPaymentDialog(context),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: AppColors.danger),
                          tooltip: 'Eliminar préstamo',
                          onPressed: () =>
                              _confirmDelete(context),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (loan.description.isNotEmpty)
                    Text(loan.description,
                        style:
                            TextStyle(color: c.textMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  _infoRow('Fecha',
                      _dateFmt.format(loan.date), c),
                  if (loan.dueDate != null)
                    _infoRow('Vence',
                        _dateFmt.format(loan.dueDate!), c),
                  _infoRow('Monto original',
                      _currencyFmt.format(loan.originalAmount), c),
                  if (loan.interest > 0)
                    _infoRow('Interés',
                        _currencyFmt.format(loan.interest), c),
                  _infoRow('Total acordado',
                      _currencyFmt.format(loan.totalAmount), c),
                  _infoRow('Pagado',
                      _currencyFmt.format(loan.paidAmount), c),
                  _infoRow(
                    'Pendiente',
                    _currencyFmt.format(loan.pendingAmount),
                    c,
                    valueColor: loan.status == LoanStatus.settled
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: c.divider, height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Historial de pagos',
                  style: TextStyle(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Expanded(
              child: loan.payments.isEmpty
                  ? Center(
                      child: Text('Sin pagos registrados',
                          style: TextStyle(
                              color: c.textDisabled, fontSize: 13)),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: loan.payments.length,
                      itemBuilder: (_, i) {
                        final reversed = loan.payments.reversed.toList();
                        final p = reversed[i];
                        return _PaymentItem(
                          payment: p,
                          loan: loan,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, AppColors c,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: c.textMuted, fontSize: 13)),
          Text(value,
              style: TextStyle(
                color: valueColor ?? c.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  void _editDate(BuildContext context) async {
    final loanCubit = context.read<LoanCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate: loan.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || picked == loan.date) return;

    final updated = LoanModel(
      id: loan.id,
      userId: loan.userId,
      counterparty: loan.counterparty,
      direction: loan.direction,
      originalAmount: loan.originalAmount,
      totalAmount: loan.totalAmount,
      paidAmount: loan.paidAmount,
      description: loan.description,
      date: picked,
      dueDate: loan.dueDate,
      status: loan.status,
      payments: loan.payments,
      createdAt: loan.createdAt,
      createdBy: loan.createdBy,
    );
    await loanCubit.updateLoan(updated);

    if (context.mounted) Navigator.pop(context);
  }

  void _showPaymentDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<LoanCubit>()),
          BlocProvider.value(value: context.read<TransactionCubit>()),
          BlocProvider.value(value: context.read<AuthCubit>()),
        ],
        child: _AddPaymentDialog(loan: loan),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Eliminar préstamo',
            style: TextStyle(color: c.textPrimary)),
        content: Text(
          '¿Eliminar el préstamo con ${loan.counterparty}? Esta acción no se puede deshacer.',
          style: TextStyle(color: c.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancelar', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              context.read<LoanCubit>().deleteLoan(loan.id);
              Navigator.pop(context); // dialog
              Navigator.pop(context); // bottom sheet
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ─── Diálogo nuevo préstamo ──────────────────────────────────────────────────

class _AddLoanDialog extends StatefulWidget {
  final AuthState authState;
  final TransactionCubit transactionCubit;

  const _AddLoanDialog({
    required this.authState,
    required this.transactionCubit,
  });

  @override
  State<_AddLoanDialog> createState() => _AddLoanDialogState();
}

class _AddLoanDialogState extends State<_AddLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _counterpartyCtrl = TextEditingController();
  final _originalAmountCtrl = TextEditingController();
  final _totalAmountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  LoanDirection _direction = LoanDirection.lent;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _counterpartyCtrl.dispose();
    _originalAmountCtrl.dispose();
    _totalAmountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Dialog(
      backgroundColor: c.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nuevo préstamo',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Dirección
              Row(
                children: [
                  Expanded(
                    child: _DirectionButton(
                      label: 'Presté',
                      icon: Icons.arrow_upward_rounded,
                      selected: _direction == LoanDirection.lent,
                      color: AppColors.expense,
                      onTap: () =>
                          setState(() => _direction = LoanDirection.lent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DirectionButton(
                      label: 'Me prestaron',
                      icon: Icons.arrow_downward_rounded,
                      selected: _direction == LoanDirection.borrowed,
                      color: AppColors.income,
                      onTap: () => setState(
                          () => _direction = LoanDirection.borrowed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildField(
                context,
                controller: _counterpartyCtrl,
                label: 'Nombre de la persona',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              _buildField(
                context,
                controller: _originalAmountCtrl,
                label: 'Monto entregado (S/.)',
                icon: Icons.payments_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
                onChanged: (v) {
                  if (_totalAmountCtrl.text.isEmpty) {
                    _totalAmountCtrl.text = v;
                  }
                },
              ),
              const SizedBox(height: 10),
              _buildField(
                context,
                controller: _totalAmountCtrl,
                label: 'Total acordado con interés (S/.)',
                icon: Icons.calculate_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  final total = double.tryParse(v);
                  final original =
                      double.tryParse(_originalAmountCtrl.text) ?? 0;
                  if (total == null || total < original) {
                    return 'Debe ser ≥ al monto entregado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildField(
                context,
                controller: _descriptionCtrl,
                label: 'Descripción (opcional)',
                icon: Icons.notes_outlined,
              ),
              const SizedBox(height: 10),

              // Fecha del préstamo
              _DatePickerRow(
                label: 'Fecha',
                date: _date,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                colors: c,
              ),
              const SizedBox(height: 8),

              // Fecha límite (opcional)
              _DatePickerRow(
                label: 'Vence (opcional)',
                date: _dueDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                colors: c,
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar',
                        style: TextStyle(color: c.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : () => _submit(context),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final c = AppColors.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(color: c.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: c.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: c.iconMuted, size: 18),
        filled: true,
        fillColor: c.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.inputBorder),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final userId = widget.authState is Authenticated
        ? (widget.authState as Authenticated).user.id
        : '';
    final userEmail = widget.authState is Authenticated
        ? (widget.authState as Authenticated).user.email
        : '';

    final loanCubit = context.read<LoanCubit>();
    final original = double.parse(_originalAmountCtrl.text);
    final total = double.parse(_totalAmountCtrl.text);
    final loanId = const Uuid().v4();

    final loan = LoanModel(
      id: loanId,
      userId: userId,
      counterparty: _counterpartyCtrl.text.trim(),
      direction: _direction,
      originalAmount: original,
      totalAmount: total,
      paidAmount: 0,
      description: _descriptionCtrl.text.trim(),
      date: _date,
      dueDate: _dueDate,
      status: LoanStatus.active,
      payments: const [],
      createdAt: DateTime.now(),
      createdBy: userEmail,
    );

    await loanCubit.addLoan(loan);

    // Crear transacción vinculada automáticamente
    final txType = _direction == LoanDirection.lent
        ? TransactionType.expense
        : TransactionType.income;
    final txCategory = _direction == LoanDirection.lent
        ? 'exp_prestamo'
        : 'inc_prestamo';

    final tx = _buildLinkedTransaction(
      loanId: loanId,
      userId: userId,
      userEmail: userEmail,
      amount: original,
      type: txType,
      categoryId: txCategory,
      counterparty: _counterpartyCtrl.text.trim(),
      date: _date,
    );
    await widget.transactionCubit.addTransaction(tx);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Préstamo registrado')),
      );
    }
  }
}

// ─── Diálogo registrar pago ──────────────────────────────────────────────────

class _AddPaymentDialog extends StatefulWidget {
  final LoanEntity loan;
  const _AddPaymentDialog({required this.loan});

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pending = widget.loan.pendingAmount;

    return Dialog(
      backgroundColor: c.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registrar pago',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Pendiente: ${_currencyFmt.format(pending)}',
                style: TextStyle(color: c.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'))
                ],
                style: TextStyle(color: c.textPrimary),
                decoration: _inputDecoration(
                    'Monto del pago (S/.)', Icons.payments_outlined, c),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) return 'Monto inválido';
                  if (amount > pending + 0.01) {
                    return 'No puede superar el pendiente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noteCtrl,
                style: TextStyle(color: c.textPrimary),
                decoration: _inputDecoration(
                    'Nota (opcional)', Icons.notes_outlined, c),
              ),
              const SizedBox(height: 10),
              _DatePickerRow(
                label: 'Fecha del pago',
                date: _date,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                colors: c,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar',
                        style: TextStyle(color: c.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : () => _submit(context),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Registrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String label, IconData icon, AppColors c) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: c.iconMuted, size: 18),
      filled: true,
      fillColor: c.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.inputBorder),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final authState = context.read<AuthCubit>().state;
    final userId = authState is Authenticated ? authState.user.id : '';
    final userEmail =
        authState is Authenticated ? authState.user.email : '';
    final loanCubit = context.read<LoanCubit>();
    final transactionCubit = context.read<TransactionCubit>();

    final amount = double.parse(_amountCtrl.text);
    final payment = LoanPaymentModel(
      id: const Uuid().v4(),
      amount: amount,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    await loanCubit.addPayment(widget.loan.id, payment);

    // Crear transacción vinculada automáticamente
    final txType = widget.loan.direction == LoanDirection.lent
        ? TransactionType.income   // me devuelven → ingreso
        : TransactionType.expense; // pago mi deuda → egreso
    final txCategory = widget.loan.direction == LoanDirection.lent
        ? 'inc_devolucion'
        : 'exp_prestamo';

    final tx = _buildLinkedTransaction(
      loanId: widget.loan.id,
      userId: userId,
      userEmail: userEmail,
      amount: amount,
      type: txType,
      categoryId: txCategory,
      counterparty: widget.loan.counterparty,
      date: _date,
    );
    await transactionCubit.addTransaction(tx);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago registrado')),
      );
    }
  }
}

// ─── Helper para construir transacción vinculada ─────────────────────────────

TransactionEntity _buildLinkedTransaction({
  required String loanId,
  required String userId,
  required String userEmail,
  required double amount,
  required TransactionType type,
  required String categoryId,
  required String counterparty,
  required DateTime date,
}) {
  return TransactionEntity(
    id: const Uuid().v4(),
    userId: userId,
    amount: amount,
    description: 'Préstamo — $counterparty',
    date: date,
    categoryId: categoryId,
    type: type,
    createdAt: DateTime.now(),
    createdBy: userEmail,
    loanId: loanId,
  );
}

// ─── Item de pago con edición inline ────────────────────────────────────────

class _PaymentItem extends StatefulWidget {
  final LoanPaymentEntity payment;
  final LoanEntity loan;

  const _PaymentItem({required this.payment, required this.loan});

  @override
  State<_PaymentItem> createState() => _PaymentItemState();
}

class _PaymentItemState extends State<_PaymentItem> {
  bool _editing = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.payment.amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    final newAmount = double.tryParse(_ctrl.text);
    if (newAmount == null || newAmount <= 0) {
      setState(() => _editing = false);
      return;
    }
    if (newAmount == widget.payment.amount) {
      setState(() => _editing = false);
      return;
    }

    final loanCubit = context.read<LoanCubit>();
    final loan = widget.loan;
    final oldAmount = widget.payment.amount;

    final updatedPayments = loan.payments.map((p) {
      if (p.id == widget.payment.id) {
        return LoanPaymentModel(
          id: p.id,
          amount: newAmount,
          date: p.date,
          note: p.note,
        );
      }
      return p;
    }).toList();

    final newPaid = loan.paidAmount - oldAmount + newAmount;
    final newStatus =
        newPaid >= loan.totalAmount ? LoanStatus.settled : LoanStatus.active;

    final updated = LoanModel(
      id: loan.id,
      userId: loan.userId,
      counterparty: loan.counterparty,
      direction: loan.direction,
      originalAmount: loan.originalAmount,
      totalAmount: loan.totalAmount,
      paidAmount: newPaid,
      description: loan.description,
      date: loan.date,
      dueDate: loan.dueDate,
      status: newStatus,
      payments: updatedPayments,
      createdAt: loan.createdAt,
      createdBy: loan.createdBy,
    );

    await loanCubit.updateLoan(updated);
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = widget.payment;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.income.withValues(alpha: 0.15),
            child: const Icon(Icons.check, size: 14, color: AppColors.income),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _editing
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            prefixText: 'S/. ',
                            prefixStyle: TextStyle(color: c.textMuted),
                            filled: true,
                            fillColor: c.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: c.primary),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: c.primary),
                            ),
                          ),
                          onSubmitted: (_) => _save(context),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.check_circle_outline,
                            color: AppColors.income, size: 20),
                        padding: EdgeInsets.zero,
                        onPressed: () => _save(context),
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel_outlined,
                            color: c.textDisabled, size: 20),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _ctrl.text =
                              widget.payment.amount.toStringAsFixed(2);
                          setState(() => _editing = false);
                        },
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => setState(() => _editing = true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _currencyFmt.format(p.amount),
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_outlined,
                                size: 12, color: c.textDisabled),
                          ],
                        ),
                        if (p.note != null && p.note!.isNotEmpty)
                          Text(p.note!,
                              style: TextStyle(
                                  color: c.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
          ),
          if (!_editing)
            Text(
              _dateFmt.format(p.date),
              style: TextStyle(color: c.textDisabled, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

// ─── Widgets de soporte ──────────────────────────────────────────────────────

class _DirectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DirectionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : c.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : c.inputBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? color : c.iconMuted, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: selected ? color : c.textMuted,
                  fontSize: 12,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final AppColors colors;

  const _DatePickerRow({
    required this.label,
    required this.date,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: c.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.inputBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: c.iconMuted, size: 18),
            const SizedBox(width: 10),
            Text(
              date != null ? '$label: ${_dateFmt.format(date!)}' : label,
              style: TextStyle(
                color: date != null ? c.textPrimary : c.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
