import 'item_model.dart';

class InventoryEntryModel {
  final String id;
  final String userId;
  final String itemId;
  final int quantity;
  final DateTime updatedAt;
  final ItemModel item;

  const InventoryEntryModel({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.quantity,
    required this.updatedAt,
    required this.item,
  });

  factory InventoryEntryModel.fromJson(Map<String, dynamic> json) {
    final itemJson = json['items'] as Map<String, dynamic>?;
    final itemId = json['item_id']?.toString() ?? '';

    final resolvedItem = itemJson != null
        ? ItemModel.fromJson(itemJson)
        : ItemModel.defaultCatalog.firstWhere(
            (i) => i.id == itemId,
            orElse: () => ItemModel(
              id: itemId,
              name: 'Suprimento Desconhecido',
              description: 'Suprimento tático recuperado em expedição.',
              category: 'ferramentas',
              iconName: 'inventory_2',
              isStarterItem: false,
              starterQuantity: 0,
            ),
          );

    return InventoryEntryModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      itemId: itemId,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      item: resolvedItem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_id': itemId,
      'quantity': quantity,
      'updated_at': updatedAt.toIso8601String(),
      'items': item.toJson(),
    };
  }
}
