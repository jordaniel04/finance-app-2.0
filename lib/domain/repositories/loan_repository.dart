import '../entities/loan_entity.dart';

abstract class LoanRepository {
  Stream<List<LoanEntity>> getLoans(String userId);
  Future<void> addLoan(LoanEntity loan);
  Future<void> updateLoan(LoanEntity loan);
  Future<void> deleteLoan(String loanId);
  Future<void> addPayment(String loanId, LoanPaymentEntity payment);
}
