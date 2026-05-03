import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/icon_map.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/entities/category_entity.dart';
import '../blocs/transaction_cubit.dart';
import '../blocs/transaction_state.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/auth_state.dart';

class AddTransactionDialog extends StatefulWidget {
  final TransactionEntity? transaction;
  const AddTransactionDialog({super.key, this.transaction});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late TransactionType _selectedType;
  CategoryEntity? _selectedCategory;
  late DateTime _selectedDate;

  bool get _isEditing => widget.transaction != null;
  static const _loanCategoryIds = {
    'exp_prestamo',
    'inc_prestamo',
    'inc_devolucion',
  };

  bool get _isReadOnly =>
      _isEditing &&
      (widget.transaction!.loanId != null ||
          _loanCategoryIds.contains(widget.transaction!.categoryId));

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _isEditing ? widget.transaction!.amount.toString() : '',
    );
    _descriptionController = TextEditingController(
      text: _isEditing ? widget.transaction!.description : '',
    );
    _selectedType =
        _isEditing ? widget.transaction!.type : TransactionType.expense;
    _selectedDate = _isEditing ? widget.transaction!.date : DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionCubit>().loadCategories();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final c = AppColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('es', 'PE'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: c.primary,
                surface: c.surface,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  InputDecoration _inputDecoration(String label, AppColors c) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.iconMuted),
      filled: true,
      fillColor: c.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        List<CategoryEntity> categories = [];
        if (state is TransactionLoaded) {
          categories =
              state.categories.where((cat) => cat.type == _selectedType).toList();
          if (_isEditing && _selectedCategory == null) {
            try {
              _selectedCategory = categories
                  .firstWhere((cat) => cat.id == widget.transaction!.categoryId);
            } catch (_) {}
          }
        }
        if (_selectedCategory != null &&
            !categories.any((cat) => cat.id == _selectedCategory!.id)) {
          _selectedCategory = null;
        }

        return Dialog(
          backgroundColor: c.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isReadOnly
                              ? 'Detalle de Transacción'
                              : _isEditing
                                  ? 'Editar Transacción'
                                  : 'Nueva Transacción',
                          style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        if (_isEditing && !_isReadOnly)
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: _deleteTransaction,
                          ),
                      ],
                    ),
                    if (_isReadOnly) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: c.primaryMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.link_rounded,
                                size: 14, color: c.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Generada automáticamente por un préstamo. Solo lectura.',
                                style: TextStyle(
                                    color: c.primary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_isEditing) ...[
                      const SizedBox(height: 4),
                      if (widget.transaction!.createdBy != null)
                        Text(
                          'Creado por ${widget.transaction!.createdBy!}${widget.transaction!.createdAt != null ? ' · ${DateFormat('d/M/yyyy HH:mm').format(widget.transaction!.createdAt!)}' : ''}',
                          style: TextStyle(color: c.textMuted, fontSize: 11),
                        ),
                      if (widget.transaction!.updatedBy != null && widget.transaction!.updatedAt != null)
                        Text(
                          'Editado por ${widget.transaction!.updatedBy!} · ${DateFormat('d/M/yyyy HH:mm').format(widget.transaction!.updatedAt!)}',
                          style: TextStyle(color: c.textMuted, fontSize: 11),
                        ),
                      const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 20),

                    // Toggle tipo
                    Text('Tipo de Transacción',
                        style:
                            TextStyle(color: c.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _buildTypeToggle(c),
                    const SizedBox(height: 20),

                    // Categoría
                    DropdownButtonFormField<CategoryEntity>(
                      initialValue: _selectedCategory,
                      dropdownColor: c.surfaceVariant,
                      decoration: _inputDecoration('Categoría', c),
                      style: TextStyle(color: c.textPrimary),
                      icon: Icon(Icons.arrow_drop_down, color: c.iconMuted),
                      items: categories.map((cat) {
                        return DropdownMenuItem<CategoryEntity>(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(
                                iconDataFromName(cat.iconName),
                                color: Color(cat.colorValue),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(cat.name,
                                  style: TextStyle(color: c.textPrimary)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _isReadOnly
                          ? null
                          : (value) =>
                              setState(() => _selectedCategory = value),
                      validator: _isReadOnly
                          ? null
                          : (value) =>
                              value == null ? 'Selecciona una categoría' : null,
                    ),
                    const SizedBox(height: 16),

                    // Monto
                    TextFormField(
                      controller: _amountController,
                      readOnly: _isReadOnly,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      style: TextStyle(color: c.textPrimary, fontSize: 16),
                      decoration: _inputDecoration('Monto', c),
                      validator: _isReadOnly
                          ? null
                          : (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa un monto';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Monto inválido';
                              }
                              return null;
                            },
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      readOnly: _isReadOnly,
                      style: TextStyle(color: c.textPrimary, fontSize: 16),
                      decoration: _inputDecoration('Descripción', c),
                      validator: _isReadOnly
                          ? null
                          : (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Ingresa una descripción'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    // Fecha
                    InkWell(
                      onTap: _isReadOnly ? null : _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _inputDecoration('Fecha', c).copyWith(
                          suffixIcon: Icon(Icons.calendar_today_rounded,
                              color: c.iconMuted, size: 20),
                        ),
                        child: Text(
                          DateFormat('d/M/yyyy').format(_selectedDate),
                          style:
                              TextStyle(color: c.textPrimary, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            _isReadOnly ? 'Cerrar' : 'Cancelar',
                            style: TextStyle(color: c.iconMuted),
                          ),
                        ),
                        if (!_isReadOnly) ...[
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              _isEditing ? 'Actualizar' : 'Guardar',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeToggle(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: 'Ingreso',
              isSelected: _selectedType == TransactionType.income,
              color: AppColors.income,
              onTap: _isReadOnly
                  ? () {}
                  : () => setState(() {
                        _selectedType = TransactionType.income;
                        _selectedCategory = null;
                      }),
            ),
          ),
          Expanded(
            child: _TypeButton(
              label: 'Gasto',
              isSelected: _selectedType == TransactionType.expense,
              color: AppColors.expense,
              onTap: _isReadOnly
                  ? () {}
                  : () => setState(() {
                        _selectedType = TransactionType.expense;
                        _selectedCategory = null;
                      }),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final transaction = TransactionEntity(
      id: _isEditing ? widget.transaction!.id : const Uuid().v4(),
      amount: double.parse(_amountController.text),
      description: _descriptionController.text,
      date: _selectedDate,
      categoryId: _selectedCategory!.id,
      type: _selectedType,
      userId: _isEditing ? widget.transaction!.userId : authState.user.id,
      createdAt: _isEditing ? widget.transaction!.createdAt : DateTime.now(),
      createdBy: _isEditing ? widget.transaction!.createdBy : (authState.user.displayName ?? authState.user.email),
      updatedAt: _isEditing ? DateTime.now() : null,
      updatedBy: _isEditing ? (authState.user.displayName ?? authState.user.email) : null,
    );

    if (_isEditing) {
      context.read<TransactionCubit>().updateTransaction(transaction);
    } else {
      context.read<TransactionCubit>().addTransaction(transaction);
    }

    Navigator.pop(context);

    final c = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Transacción actualizada' : 'Transacción guardada',
          style: TextStyle(color: c.textPrimary),
        ),
        backgroundColor: c.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _deleteTransaction() {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title:
            Text('Eliminar', style: TextStyle(color: c.textPrimary)),
        content: Text(
          '¿Estás seguro de eliminar esta transacción?',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancelar', style: TextStyle(color: c.iconMuted)),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<TransactionCubit>()
                  .deleteTransaction(widget.transaction!.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transacción eliminada',
                      style: TextStyle(color: c.textPrimary)),
                  backgroundColor: c.surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : c.iconMuted,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
