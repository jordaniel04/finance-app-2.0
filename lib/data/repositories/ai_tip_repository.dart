import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';

class AiTipEntry {
  final String date;
  final String tip;
  final DateTime generatedAt;
  final DocumentSnapshot snapshot;

  const AiTipEntry({
    required this.date,
    required this.tip,
    required this.generatedAt,
    required this.snapshot,
  });
}

class AiTipRepository {
  final FirebaseFirestore _firestore;

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  AiTipRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<String> getTodayTip(
    String userId,
    List<TransactionEntity> transactions,
    List<CategoryEntity> categories,
  ) async {
    final cached = await _getCachedTip(userId);
    if (cached != null) return cached;

    final tip = await _generateTip(transactions, categories);
    await _saveTip(userId, tip);
    return tip;
  }

  Future<List<AiTipEntry>> getHistory(
    String userId, {
    DocumentSnapshot? startAfter,
    int pageSize = 7,
  }) async {
    try {
      var query = _firestore
          .collection('ai_tips')
          .doc(userId)
          .collection('daily')
          .orderBy('generatedAt', descending: true)
          .limit(pageSize);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final ts = data['generatedAt'];
        final generatedAt = ts is Timestamp ? ts.toDate() : DateTime.now();
        return AiTipEntry(
          date: doc.id,
          tip: data['tip'] as String? ?? '',
          generatedAt: generatedAt,
          snapshot: doc,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> _getCachedTip(String userId) async {
    try {
      final doc = await _firestore
          .collection('ai_tips')
          .doc(userId)
          .collection('daily')
          .doc(_today)
          .get();
      if (doc.exists) return doc.data()?['tip'] as String?;
    } catch (_) {}
    return null;
  }

  Future<void> _saveTip(String userId, String tip) async {
    await _firestore
        .collection('ai_tips')
        .doc(userId)
        .collection('daily')
        .doc(_today)
        .set({'tip': tip, 'generatedAt': Timestamp.now()});
  }

  Future<String> _generateTip(
    List<TransactionEntity> transactions,
    List<CategoryEntity> categories,
  ) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY no configurada');
    }

    final prompt = _buildPrompt(transactions, categories);

    final response = await http.post(
      Uri.parse('$_apiUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2048,
        },
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('Gemini error body: ${response.body}');
      throw Exception('Error Gemini ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final finishReason = data['candidates'][0]['finishReason'];
    debugPrint('Gemini finishReason: $finishReason');
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  String _buildPrompt(
    List<TransactionEntity> transactions,
    List<CategoryEntity> categories,
  ) {
    final now = DateTime.now();
    final fmt = NumberFormat.currency(locale: 'en_US', symbol: 'S/.', decimalDigits: 2);
    final monthName = DateFormat('MMMM', 'es_PE').format(now);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;

    const loanCategoryIds = {'exp_prestamo', 'inc_prestamo', 'inc_devolucion'};

    final thisMonth = transactions
        .where((t) => t.date.month == now.month && t.date.year == now.year)
        .where((t) => !loanCategoryIds.contains(t.categoryId))
        .toList();

    final monthIncome = thisMonth
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final monthExpense = thisMonth
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final monthBalance = monthIncome - monthExpense;

    // Top 5 categorías por volumen histórico (últimos 3 meses + mes actual)
    final top5CatNames = _top5HistoricalCategories(transactions, categories, now);

    // Desglose mes a mes de esas top 5 categorías
    final historySectionBuffer = StringBuffer();
    for (final catName in top5CatNames) {
      final monthlyAmounts = <String>[];
      for (int i = 3; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final total = transactions
            .where((t) =>
                t.date.month == month.month &&
                t.date.year == month.year &&
                t.type == TransactionType.expense)
            .where((t) =>
                (categories.where((c) => c.id == t.categoryId).firstOrNull?.name ?? 'Otros') ==
                catName)
            .fold(0.0, (s, t) => s + t.amount);
        final label = DateFormat('MMM', 'es_PE').format(month);
        monthlyAmounts.add('$label ${fmt.format(total)}');
      }
      historySectionBuffer.writeln('- $catName: ${monthlyAmounts.join(' → ')}');
    }

    // Total de egresos por mes para contexto
    final monthTotals = <String>[];
    for (int i = 3; i >= 1; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final total = transactions
          .where((t) =>
              t.date.month == month.month &&
              t.date.year == month.year &&
              t.type == TransactionType.expense &&
              !loanCategoryIds.contains(t.categoryId))
          .fold(0.0, (s, t) => s + t.amount);
      if (total > 0) {
        final label = DateFormat('MMM', 'es_PE').format(month);
        monthTotals.add('$label: ${fmt.format(total)}');
      }
    }
    final monthTotalsLine = monthTotals.isNotEmpty
        ? 'Egresos totales previos: ${monthTotals.join(', ')}'
        : '';

    return '''Finanzas de una pareja peruana — $monthName ${now.year} (día $dayOfMonth de $daysInMonth):

Ingresos: ${fmt.format(monthIncome)}
Egresos: ${fmt.format(monthExpense)}
Balance: ${fmt.format(monthBalance)}
${monthTotalsLine.isNotEmpty ? '$monthTotalsLine\n' : ''}
Evolución de las principales categorías de gasto (últimos 3 meses → mes actual):
${historySectionBuffer.toString().trimRight()}

Da UN consejo financiero concreto en 2-3 oraciones basado en las tendencias por categoría. Menciona cifras específicas. Empieza directo con el consejo, sin presentación ni introducción. Sin asteriscos ni markdown.''';
  }

  List<String> _top5HistoricalCategories(
    List<TransactionEntity> transactions,
    List<CategoryEntity> categories,
    DateTime now,
  ) {
    const loanCategoryIds = {'exp_prestamo', 'inc_prestamo', 'inc_devolucion'};
    final totals = <String, double>{};
    for (int i = 0; i <= 3; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      for (final t in transactions.where((t) =>
          t.date.month == month.month &&
          t.date.year == month.year &&
          t.type == TransactionType.expense &&
          !loanCategoryIds.contains(t.categoryId))) {
        final catName =
            categories.where((c) => c.id == t.categoryId).firstOrNull?.name ?? 'Otros';
        totals[catName] = (totals[catName] ?? 0) + t.amount;
      }
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }
}
