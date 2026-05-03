import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/icon_map.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../blocs/category_cubit.dart';
import '../blocs/category_state.dart';
import '../widgets/category_dialog.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<CategoryCubit>().loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDialog([CategoryEntity? category]) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryCubit>(),
        child: CategoryDialog(category: category),
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
        title: Text('Categorías',
            style: TextStyle(
                color: c.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: c.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: c.primary,
          labelColor: c.textPrimary,
          unselectedLabelColor: c.iconMuted,
          tabs: const [Tab(text: 'Gastos'), Tab(text: 'Ingresos')],
        ),
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading) {
            return Center(
                child: CircularProgressIndicator(color: c.primary));
          }
          if (state is CategoryError) {
            return Center(
                child: Text(state.message,
                    style: TextStyle(color: c.textSecondary)));
          }
          if (state is CategoryLoaded) {
            final expenses = state.categories
                .where((cat) => cat.type == TransactionType.expense)
                .toList();
            final incomes = state.categories
                .where((cat) => cat.type == TransactionType.income)
                .toList();
            return TabBarView(
              controller: _tabController,
              children: [
                _CategoryList(categories: expenses, onTap: _openDialog),
                _CategoryList(categories: incomes, onTap: _openDialog),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_categories',
        onPressed: () => _openDialog(),
        backgroundColor: c.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<CategoryEntity> categories;
  final void Function(CategoryEntity) onTap;

  const _CategoryList(
      {required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined,
                color: c.textDisabled, size: 64),
            const SizedBox(height: 16),
            Text(
              'No hay categorías aún.\n¡Crea la primera!',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        final color = Color(category.colorValue);
        return InkWell(
          onTap: () => onTap(category),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.surfaceBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconDataFromName(category.iconName),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(category.name,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ),
                Icon(Icons.chevron_right,
                    color: c.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
