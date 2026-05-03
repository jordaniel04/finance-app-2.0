import 'package:equatable/equatable.dart';
import 'transaction_type.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final TransactionType type;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.type,
  });

  @override
  List<Object?> get props => [id, name, iconName, colorValue, type];
}
