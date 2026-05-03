import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/repositories/loan_repository.dart';
import '../models/loan_model.dart';

class FirebaseLoanRepositoryImpl implements LoanRepository {
  final FirebaseFirestore _firestore;

  FirebaseLoanRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<LoanEntity>> getLoans(String userId) {
    return _firestore
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((_) {});
  }

  @override
  Future<void> addLoan(LoanEntity loan) async {
    final model = loan as LoanModel;
    await _firestore.collection('loans').doc(model.id).set(model.toMap());
  }

  @override
  Future<void> updateLoan(LoanEntity loan) async {
    final model = loan as LoanModel;
    await _firestore.collection('loans').doc(model.id).update(model.toMap());
  }

  @override
  Future<void> deleteLoan(String loanId) async {
    await _firestore.collection('loans').doc(loanId).delete();
  }

  @override
  Future<void> addPayment(String loanId, LoanPaymentEntity payment) async {
    final doc = _firestore.collection('loans').doc(loanId);
    final snap = await doc.get();
    if (!snap.exists) return;

    final loan = LoanModel.fromMap(snap.data()!, loanId);
    final updatedPayments = [
      ...loan.payments.map((p) => LoanPaymentModel.fromMap({
            'id': p.id,
            'amount': p.amount,
            'date': Timestamp.fromDate(p.date),
            'note': p.note,
          })),
      LoanPaymentModel(
        id: payment.id,
        amount: payment.amount,
        date: payment.date,
        note: payment.note,
      ),
    ];

    final newPaid = loan.paidAmount + payment.amount;
    final newStatus =
        newPaid >= loan.totalAmount ? LoanStatus.settled : LoanStatus.active;

    await doc.update({
      'payments': updatedPayments.map((p) => p.toMap()).toList(),
      'paidAmount': newPaid,
      'status': newStatus.name,
    });
  }
}
