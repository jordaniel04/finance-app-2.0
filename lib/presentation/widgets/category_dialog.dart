import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/icon_map.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../blocs/category_cubit.dart';

class CategoryDialog extends StatefulWidget {
  final CategoryEntity? category;
  const CategoryDialog({super.key, this.category});

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late TransactionType _selectedType;
  late String _selectedIconName;
  late int _selectedColorValue;

  bool get _isEditing => widget.category != null;

  static const _colors = [
    0xFF4CAF50, 0xFF2E7D32, 0xFF8BC34A, 0xFF00BCD4,
    0xFF1565C0, 0xFF2196F3, 0xFF3F51B5, 0xFF5C6BC0,
    0xFF9C27B0, 0xFF7B1FA2, 0xFFE91E63, 0xFFD81B60,
    0xFFE53935, 0xFFC62828, 0xFFFF5722, 0xFFEF6C00,
    0xFFFF9800, 0xFFF9A825, 0xFFFFEB3B, 0xFF795548,
    0xFF78909C, 0xFF607D8B, 0xFF9E9E9E, 0xFF00ACC1,
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: _isEditing ? widget.category!.name : '');
    _selectedType =
        _isEditing ? widget.category!.type : TransactionType.expense;
    _selectedIconName =
        _isEditing ? widget.category!.iconName : kIconNames.first;
    _selectedColorValue =
        _isEditing ? widget.category!.colorValue : _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final category = CategoryEntity(
      id: _isEditing ? widget.category!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      iconName: _selectedIconName,
      colorValue: _selectedColorValue,
      type: _selectedType,
    );
    if (_isEditing) {
      context.read<CategoryCubit>().updateCategory(category);
    } else {
      context.read<CategoryCubit>().addCategory(category);
    }
    Navigator.pop(context);
  }

  void _delete() {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Eliminar categoría',
            style: TextStyle(color: c.textPrimary)),
        content: Text(
          '¿Estás seguro? Las transacciones con esta categoría no se eliminarán.',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: c.iconMuted)),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<CategoryCubit>()
                  .deleteCategory(widget.category!.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
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
    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Editar Categoría' : 'Nueva Categoría',
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger),
                        onPressed: _delete,
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                Text('Tipo',
                    style: TextStyle(color: c.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                _buildTypeToggle(c),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: c.textPrimary),
                  decoration: _inputDecoration('Nombre*', c),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 20),

                _buildPreview(c),
                const SizedBox(height: 20),

                Text('Icono',
                    style: TextStyle(color: c.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                _buildIconGrid(c),
                const SizedBox(height: 20),

                Text('Color',
                    style: TextStyle(color: c.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                _buildColorGrid(),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar',
                          style: TextStyle(color: c.iconMuted)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submit,
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
              label: 'Gasto',
              isSelected: _selectedType == TransactionType.expense,
              color: AppColors.expense,
              onTap: () =>
                  setState(() => _selectedType = TransactionType.expense),
            ),
          ),
          Expanded(
            child: _TypeButton(
              label: 'Ingreso',
              isSelected: _selectedType == TransactionType.income,
              color: AppColors.income,
              onTap: () =>
                  setState(() => _selectedType = TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(AppColors c) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(_selectedColorValue).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              iconDataFromName(_selectedIconName),
              color: Color(_selectedColorValue),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _nameController.text.isEmpty ? 'Vista previa' : _nameController.text,
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildIconGrid(AppColors c) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kIconNames.map((name) {
        final isSelected = name == _selectedIconName;
        return GestureDetector(
          onTap: () => setState(() => _selectedIconName = name),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(_selectedColorValue).withValues(alpha: 0.3)
                  : c.inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Color(_selectedColorValue)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              iconDataFromName(name),
              color: isSelected ? Color(_selectedColorValue) : c.iconMuted,
              size: 22,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colors.map((colorValue) {
        final isSelected = colorValue == _selectedColorValue;
        return GestureDetector(
          onTap: () => setState(() => _selectedColorValue = colorValue),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(colorValue),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
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
