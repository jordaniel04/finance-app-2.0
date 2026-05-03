import 'package:equatable/equatable.dart';
import '../../domain/entities/loan_entity.dart';

abstract class LoanState extends Equatable {
  const LoanState();
  @override
  List<Object?> get props => [];
}

class LoanInitial extends LoanState {}

class LoanLoading extends LoanState {}

class LoanLoaded extends LoanState {
  final List<LoanEntity> loans;

  const LoanLoaded(this.loans);

  List<LoanEntity> get lent =>
      loans.where((l) => l.direction == LoanDirection.lent).toList();

  List<LoanEntity> get borrowed =>
      loans.where((l) => l.direction == LoanDirection.borrowed).toList();

  double get totalLent => lent.fold(0, (sum, l) => sum + l.pendingAmount);
  double get totalBorrowed =>
      borrowed.fold(0, (sum, l) => sum + l.pendingAmount);

  @override
  List<Object?> get props => [loans];
}

class LoanError extends LoanState {
  final String message;
  const LoanError(this.message);
  @override
  List<Object?> get props => [message];
}
