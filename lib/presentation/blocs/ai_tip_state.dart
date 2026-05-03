part of 'ai_tip_cubit.dart';

abstract class AiTipState {}

class AiTipInitial extends AiTipState {}

class AiTipLoading extends AiTipState {}

class AiTipLoaded extends AiTipState {
  final String tip;
  final bool dismissed;

  AiTipLoaded({required this.tip, this.dismissed = false});

  AiTipLoaded copyWith({String? tip, bool? dismissed}) {
    return AiTipLoaded(
      tip: tip ?? this.tip,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}

class AiTipError extends AiTipState {
  final String message;
  AiTipError(this.message);
}
