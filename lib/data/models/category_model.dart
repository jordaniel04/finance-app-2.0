import '../../core/utils/icon_map.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_type.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.iconName,
    required super.colorValue,
    required super.type,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    String iconName = map['iconName'] as String? ?? '';

    if (!kIconCodePoints.containsKey(iconName)) {
      final code = map['iconCode'];
      if (code is int) {
        iconName = kIconCodePoints.entries
            .firstWhere((e) => e.value == code,
                orElse: () => const MapEntry('card_giftcard', 0))
            .key;
      } else {
        iconName = 'card_giftcard';
      }
    }

    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      iconName: iconName,
      colorValue: _parseColor(map['colorValue'] ?? map['color']),
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
    );
  }

  static int _parseColor(dynamic color) {
    if (color is int) return color;
    if (color is String && color.startsWith('#')) {
      return int.parse('0xFF${color.substring(1)}');
    }
    return 0xFF9E9E9E;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,
      'type': type == TransactionType.income ? 'income' : 'expense',
    };
  }
}
