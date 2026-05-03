import 'package:equatable/equatable.dart';
import 'transaction_type.dart';

class TransactionEntity extends Equatable {
  final String id;
  final double amount;
  final String description;
  final DateTime date;
  final String categoryId;
  final TransactionType type;
  final String userId;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? loanId;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.categoryId,
    required this.type,
    required this.userId,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.loanId,
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    description,
    date,
    categoryId,
    type,
    userId,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    loanId,
  ];
}
