import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/loan_entity.dart';

class LoanPaymentModel extends LoanPaymentEntity {
  const LoanPaymentModel({
    required super.id,
    required super.amount,
    required super.date,
    super.note,
  });

  factory LoanPaymentModel.fromMap(Map<String, dynamic> map) {
    final dynamic dateValue = map['date'];
    final DateTime date;
    if (dateValue is Timestamp) {
      date = dateValue.toDate();
    } else if (dateValue is String) {
      date = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return LoanPaymentModel(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: date,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'note': note,
  };
}

class LoanModel extends LoanEntity {
  const LoanModel({
    required super.id,
    required super.userId,
    required super.counterparty,
    required super.direction,
    required super.originalAmount,
    required super.totalAmount,
    required super.paidAmount,
    required super.description,
    required super.date,
    super.dueDate,
    required super.status,
    required super.payments,
    super.createdAt,
    super.createdBy,
  });

  factory LoanModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final direction = map['direction'] == 'borrowed'
        ? LoanDirection.borrowed
        : LoanDirection.lent;

    final status = switch (map['status'] as String?) {
      'settled' => LoanStatus.settled,
      'defaulted' => LoanStatus.defaulted,
      _ => LoanStatus.active,
    };

    final rawPayments = map['payments'] as List<dynamic>? ?? [];
    final payments = rawPayments
        .map((p) => LoanPaymentModel.fromMap(p as Map<String, dynamic>))
        .toList();

    return LoanModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      counterparty: map['counterparty'] as String? ?? '',
      direction: direction,
      originalAmount: (map['originalAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      date: parseDate(map['date']),
      dueDate: map['dueDate'] != null ? parseDate(map['dueDate']) : null,
      status: status,
      payments: payments,
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
      createdBy: map['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final paymentsData = payments
        .map((p) => (p as LoanPaymentModel).toMap())
        .toList();

    return {
      'userId': userId,
      'counterparty': counterparty,
      'direction': direction == LoanDirection.borrowed ? 'borrowed' : 'lent',
      'originalAmount': originalAmount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status.name,
      'payments': paymentsData,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'createdBy': createdBy,
    };
  }
}
