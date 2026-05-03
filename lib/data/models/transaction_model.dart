import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.description,
    required super.date,
    required super.categoryId,
    required super.type,
    required super.userId,
    super.createdAt,
    super.createdBy,
    super.updatedAt,
    super.updatedBy,
    super.loanId,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    final dynamic dateValue = map['date'];

    if (dateValue is Timestamp) {
      parsedDate = dateValue.toDate();
    } else if (dateValue is String) {
      parsedDate = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else if (dateValue is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? parsedCreatedAt;
    final dynamic createdAtValue = map['createdAt'];
    if (createdAtValue is Timestamp) {
      parsedCreatedAt = createdAtValue.toDate();
    }

    DateTime? parsedUpdatedAt;
    final dynamic updatedAtValue = map['updatedAt'];
    if (updatedAtValue is Timestamp) {
      parsedUpdatedAt = updatedAtValue.toDate();
    }

    return TransactionModel(
      id: id,
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      date: parsedDate,
      categoryId: map['categoryId'] ?? '',
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      userId: map['userId'] ?? '',
      createdAt: parsedCreatedAt,
      createdBy: map['createdBy'] as String?,
      updatedAt: parsedUpdatedAt,
      updatedBy: map['updatedBy'] as String?,
      loanId: map['loanId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'categoryId': categoryId,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'userId': userId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (loanId != null) 'loanId': loanId,
    };
  }
}
