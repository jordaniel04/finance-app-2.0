import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class FirebaseTransactionRepositoryImpl implements TransactionRepository {
  final FirebaseFirestore _firestore;

  FirebaseTransactionRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<TransactionEntity>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((_) {});
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    final model = TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      description: transaction.description,
      date: transaction.date,
      categoryId: transaction.categoryId,
      type: transaction.type,
      userId: transaction.userId,
      createdAt: transaction.createdAt,
      createdBy: transaction.createdBy,
    );

    await _firestore
        .collection('transactions')
        .doc(model.id)
        .set(model.toMap());
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final model = TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      description: transaction.description,
      date: transaction.date,
      categoryId: transaction.categoryId,
      type: transaction.type,
      userId: transaction.userId,
      createdAt: transaction.createdAt,
      createdBy: transaction.createdBy,
      updatedAt: transaction.updatedAt,
      updatedBy: transaction.updatedBy,
      loanId: transaction.loanId,
    );

    await _firestore
        .collection('transactions')
        .doc(model.id)
        .update(model.toMap());

    if (transaction.loanId != null) {
      await _firestore
          .collection('loans')
          .doc(transaction.loanId)
          .update({'date': Timestamp.fromDate(transaction.date)});
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _firestore.collection('transactions').doc(transactionId).delete();
  }

  @override
  Future<List<CategoryEntity>> getCategories(TransactionType type) async {
    final typeStr = type == TransactionType.income ? 'income' : 'expense';
    final snapshot = await _firestore
        .collection('categories')
        .where('type', isEqualTo: typeStr)
        .get(const GetOptions(source: Source.server));

    return snapshot.docs
        .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> addCategory(CategoryEntity category) async {
    final model = CategoryModel(
      id: category.id,
      name: category.name,
      iconName: category.iconName,
      colorValue: category.colorValue,
      type: category.type,
    );
    await _firestore
        .collection('categories')
        .doc(model.id)
        .set(model.toMap());
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    final model = CategoryModel(
      id: category.id,
      name: category.name,
      iconName: category.iconName,
      colorValue: category.colorValue,
      type: category.type,
    );
    await _firestore
        .collection('categories')
        .doc(model.id)
        .update(model.toMap());
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  @override
  Future<void> seedDefaultCategoriesIfEmpty() async {
    final defaults = _defaultCategories();
    final existingSnapshot = await _firestore.collection('categories').get(const GetOptions(source: Source.server));
    final existingIds = existingSnapshot.docs.map((d) => d.id).toSet();

    final missing = defaults.where((cat) => !existingIds.contains(cat.id)).toList();
    if (missing.isEmpty) return;

    final batch = _firestore.batch();
    for (final category in missing) {
      final ref = _firestore.collection('categories').doc(category.id);
      batch.set(ref, category.toMap());
    }
    await batch.commit();
  }

  List<CategoryModel> _defaultCategories() {
    return const [
      // ── Ingresos ────────────────────────────────────────────────────────────
      CategoryModel(
        id: 'inc_sueldo',
        name: 'Sueldo',
        iconName: 'attach_money',
        colorValue: 0xFF4CAF50,
        type: TransactionType.income,
      ),
      CategoryModel(
        id: 'inc_prestamo',
        name: 'Préstamo',
        iconName: 'account_balance',
        colorValue: 0xFF1565C0,
        type: TransactionType.income,
      ),
      CategoryModel(
        id: 'inc_agendas',
        name: 'Agendas',
        iconName: 'book',
        colorValue: 0xFF2E7D32,
        type: TransactionType.income,
      ),
      CategoryModel(
        id: 'inc_venta_cosas',
        name: 'Venta Cosas',
        iconName: 'shopping_bag',
        colorValue: 0xFF6A1B9A,
        type: TransactionType.income,
      ),
      CategoryModel(
        id: 'inc_bono',
        name: 'Bono',
        iconName: 'star',
        colorValue: 0xFF388E3C,
        type: TransactionType.income,
      ),
      CategoryModel(
        id: 'inc_ofrenda',
        name: 'Ofrenda de Amor',
        iconName: 'favorite',
        colorValue: 0xFF558B2F,
        type: TransactionType.income,
      ),
      CategoryModel(
        id: 'inc_terapias',
        name: 'Terapias',
        iconName: 'psychology',
        colorValue: 0xFF7B1FA2,
        type: TransactionType.income,
      ),
      CategoryModel(
        id: 'inc_devolucion',
        name: 'Devolución de Préstamo',
        iconName: 'sync_alt',
        colorValue: 0xFF1976D2,
        type: TransactionType.income,
      ),

      // ── Egresos ─────────────────────────────────────────────────────────────
      CategoryModel(
        id: 'exp_agua',
        name: 'Agua',
        iconName: 'water_drop',
        colorValue: 0xFF1565C0,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_celular',
        name: 'Celular',
        iconName: 'smartphone',
        colorValue: 0xFFC62828,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_comida',
        name: 'Comida',
        iconName: 'restaurant',
        colorValue: 0xFF6D4C41,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_luz',
        name: 'Luz',
        iconName: 'lightbulb',
        colorValue: 0xFFFF00FF,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_entretenimiento',
        name: 'Entretenimiento',
        iconName: 'sports_esports',
        colorValue: 0xFF5C6BC0,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_programas_ia',
        name: 'Programas IA',
        iconName: 'smart_toy',
        colorValue: 0xFF78909C,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_alquiler',
        name: 'Alquiler Depa',
        iconName: 'home',
        colorValue: 0xFFEF6C00,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_cumpleanos',
        name: 'Cumpleaños',
        iconName: 'cake',
        colorValue: 0xFF9E9E9E,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_pinatas',
        name: 'Piñatas',
        iconName: 'celebration',
        colorValue: 0xFF00ACC1,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_diezmo',
        name: 'Diezmo',
        iconName: 'church',
        colorValue: 0xFFF9A825,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_tarjeta',
        name: 'Tarjeta',
        iconName: 'credit_card',
        colorValue: 0xFFD81B60,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_utiles_terapias',
        name: 'Útiles de Terapias',
        iconName: 'healing',
        colorValue: 0xFF00695C,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_utiles_agenda',
        name: 'Útiles Agenda',
        iconName: 'menu_book',
        colorValue: 0xFF00BCD4,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_prestamo',
        name: 'Préstamo',
        iconName: 'payments',
        colorValue: 0xFFE53935,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_colaboraciones',
        name: 'Colaboraciones',
        iconName: 'groups',
        colorValue: 0xFF5E35B1,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_compras',
        name: 'Compras',
        iconName: 'shopping_cart',
        colorValue: 0xFF8E24AA,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_ropa',
        name: 'Ropa',
        iconName: 'checkroom',
        colorValue: 0xFFB71C1C,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_gas',
        name: 'Gas',
        iconName: 'local_gas_station',
        colorValue: 0xFFFFEB3B,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_otros',
        name: 'Otros',
        iconName: 'card_giftcard',
        colorValue: 0xFF43A047,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_salud',
        name: 'Salud',
        iconName: 'local_hospital',
        colorValue: 0xFFEF6C00,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_internet',
        name: 'Internet',
        iconName: 'wifi',
        colorValue: 0xFFE040FB,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_transporte',
        name: 'Transporte',
        iconName: 'directions_car',
        colorValue: 0xFFC62828,
        type: TransactionType.expense,
      ),
      CategoryModel(
        id: 'exp_bebe',
        name: 'Bebé',
        iconName: 'stroller',
        colorValue: 0xFFEC407A,
        type: TransactionType.expense,
      ),
    ];
  }
}
