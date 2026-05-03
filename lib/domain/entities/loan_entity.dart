import 'package:equatable/equatable.dart';

enum LoanDirection { lent, borrowed }

enum LoanStatus { active, settled, defaulted }

class LoanPaymentEntity extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  const LoanPaymentEntity({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  @override
  List<Object?> get props => [id, amount, date, note];
}

class LoanEntity extends Equatable {
  final String id;
  final String userId;
  final String counterparty;
  final LoanDirection direction;
  final double originalAmount;
  final double totalAmount;
  final double paidAmount;
  final String description;
  final DateTime date;
  final DateTime? dueDate;
  final LoanStatus status;
  final List<LoanPaymentEntity> payments;
  final DateTime? createdAt;
  final String? createdBy;

  const LoanEntity({
    required this.id,
    required this.userId,
    required this.counterparty,
    required this.direction,
    required this.originalAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.description,
    required this.date,
    this.dueDate,
    required this.status,
    required this.payments,
    this.createdAt,
    this.createdBy,
  });

  double get pendingAmount => totalAmount - paidAmount;
  double get interest => totalAmount - originalAmount;
  double get progressPercent =>
      totalAmount == 0 ? 0 : (paidAmount / totalAmount).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [
    id,
    userId,
    counterparty,
    direction,
    originalAmount,
    totalAmount,
    paidAmount,
    description,
    date,
    dueDate,
    status,
    payments,
    createdAt,
    createdBy,
  ];
}
