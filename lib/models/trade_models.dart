import 'item_model.dart';

class TradeItemModel {
  final String id;
  final String tradeId;
  final String itemId;
  final int quantity;
  final String side; // 'offered' or 'requested'
  final ItemModel item;

  const TradeItemModel({
    required this.id,
    required this.tradeId,
    required this.itemId,
    required this.quantity,
    required this.side,
    required this.item,
  });

  bool get isOffered => side == 'offered';

  factory TradeItemModel.fromJson(Map<String, dynamic> json) {
    final itemId = json['item_id']?.toString() ?? '';
    ItemModel resolved;
    if (json['items'] is Map<String, dynamic>) {
      resolved = ItemModel.fromJson(json['items'] as Map<String, dynamic>);
    } else {
      resolved = ItemModel.defaultCatalog.firstWhere(
        (i) => i.id == itemId,
        orElse: () => ItemModel(
          id: itemId,
          name: 'Suprimento',
          description: '',
          category: 'ferramentas',
          iconName: 'inventory_2',
          isStarterItem: false,
          starterQuantity: 0,
        ),
      );
    }

    return TradeItemModel(
      id: json['id']?.toString() ?? '',
      tradeId: json['trade_id']?.toString() ?? '',
      itemId: itemId,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      side: json['side']?.toString() ?? 'offered',
      item: resolved,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trade_id': tradeId,
    'item_id': itemId,
    'quantity': quantity,
    'side': side,
    'items': item.toJson(),
  };
}

class TradeModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled', 'expired'
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? senderNickname;
  final String? receiverNickname;
  final List<TradeItemModel> items;

  const TradeModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.resolvedAt,
    this.senderNickname,
    this.receiverNickname,
    this.items = const [],
  });

  List<TradeItemModel> get offeredItems =>
      items.where((i) => i.side == 'offered').toList();

  List<TradeItemModel> get requestedItems =>
      items.where((i) => i.side == 'requested').toList();

  bool get isExpiredByTime =>
      status == 'pending' && DateTime.now().isAfter(expiresAt);

  String get effectiveStatus => isExpiredByTime ? 'expired' : status;

  String get statusLabel {
    switch (effectiveStatus) {
      case 'pending':
        return 'PENDENTE';
      case 'accepted':
        return 'ACEITA';
      case 'rejected':
        return 'RECUSADA';
      case 'cancelled':
        return 'CANCELADA';
      case 'expired':
        return 'EXPIRADA';
      default:
        return effectiveStatus.toUpperCase();
    }
  }

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    String? senderNick = json['sender_nickname']?.toString();
    String? receiverNick = json['receiver_nickname']?.toString();

    if (json['sender'] is Map<String, dynamic>) {
      senderNick = (json['sender'] as Map<String, dynamic>)['nickname']
          ?.toString();
    }
    if (json['receiver'] is Map<String, dynamic>) {
      receiverNick = (json['receiver'] as Map<String, dynamic>)['nickname']
          ?.toString();
    }

    final List<TradeItemModel> parsedItems = [];
    if (json['trade_items'] is List) {
      for (final ti in json['trade_items'] as List) {
        if (ti is Map<String, dynamic>) {
          parsedItems.add(TradeItemModel.fromJson(ti));
        }
      }
    }

    return TradeModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())?.toLocal() ??
                DateTime.now().add(const Duration(hours: 24))
          : DateTime.now().add(const Duration(hours: 24)),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())?.toLocal()
          : null,
      senderNickname: senderNick,
      receiverNickname: receiverNick,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'status': status,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'resolved_at': resolvedAt?.toUtc().toIso8601String(),
    'sender_nickname': senderNickname,
    'receiver_nickname': receiverNickname,
    'trade_items': items.map((e) => e.toJson()).toList(),
  };
}
