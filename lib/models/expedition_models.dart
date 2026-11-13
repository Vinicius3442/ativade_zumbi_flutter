import 'item_model.dart';

class ExpeditionLootModel {
  final String id;
  final String expeditionTypeId;
  final String itemId;
  final int minQuantity;
  final int maxQuantity;
  final int dropWeight;
  final ItemModel? item;

  const ExpeditionLootModel({
    required this.id,
    required this.expeditionTypeId,
    required this.itemId,
    required this.minQuantity,
    required this.maxQuantity,
    required this.dropWeight,
    this.item,
  });

  factory ExpeditionLootModel.fromJson(Map<String, dynamic> json) {
    ItemModel? parsedItem;
    if (json['items'] is Map<String, dynamic>) {
      parsedItem = ItemModel.fromJson(json['items'] as Map<String, dynamic>);
    } else {
      final iid = json['item_id']?.toString() ?? '';
      parsedItem = ItemModel.defaultCatalog
          .where((e) => e.id == iid)
          .firstOrNull;
    }

    return ExpeditionLootModel(
      id: json['id']?.toString() ?? '',
      expeditionTypeId: json['expedition_type_id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      minQuantity: (json['min_quantity'] as num?)?.toInt() ?? 1,
      maxQuantity: (json['max_quantity'] as num?)?.toInt() ?? 2,
      dropWeight: (json['drop_weight'] as num?)?.toInt() ?? 10,
      item: parsedItem,
    );
  }
}

class ExpeditionTypeModel {
  final String id;
  final String name;
  final String description;
  final int durationSeconds;
  final String riskLevel; // 'baixo', 'medio', 'alto'
  final int minRewardTypes;
  final int maxRewardTypes;
  final List<ExpeditionLootModel> lootTable;

  const ExpeditionTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.durationSeconds,
    required this.riskLevel,
    required this.minRewardTypes,
    required this.maxRewardTypes,
    this.lootTable = const [],
  });

  factory ExpeditionTypeModel.fromJson(Map<String, dynamic> json) {
    final List<ExpeditionLootModel> loots = [];
    if (json['expedition_loot_table'] is List) {
      for (final el in json['expedition_loot_table'] as List) {
        if (el is Map<String, dynamic>) {
          loots.add(ExpeditionLootModel.fromJson(el));
        }
      }
    }

    return ExpeditionTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 60,
      riskLevel: json['risk_level']?.toString() ?? 'baixo',
      minRewardTypes: (json['min_reward_types'] as num?)?.toInt() ?? 1,
      maxRewardTypes: (json['max_reward_types'] as num?)?.toInt() ?? 2,
      lootTable: loots,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration_seconds': durationSeconds,
      'risk_level': riskLevel,
      'min_reward_types': minRewardTypes,
      'max_reward_types': maxRewardTypes,
    };
  }

  static List<ExpeditionTypeModel> get defaultTypes => [
    ExpeditionTypeModel(
      id: 'bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      name: 'Mercado Abandonado',
      description:
          'Corredores saqueados na zona cinza, mas ainda restam mantimentos básicos.',
      durationSeconds: 60,
      riskLevel: 'baixo',
      minRewardTypes: 1,
      maxRewardTypes: 2,
      lootTable: [
        ExpeditionLootModel(
          id: 'l1',
          expeditionTypeId: 'bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          itemId: 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          minQuantity: 1,
          maxQuantity: 3,
          dropWeight: 50,
          item: ItemModel.defaultCatalog[0],
        ),
        ExpeditionLootModel(
          id: 'l2',
          expeditionTypeId: 'bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          itemId: 'aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          minQuantity: 1,
          maxQuantity: 3,
          dropWeight: 50,
          item: ItemModel.defaultCatalog[1],
        ),
        ExpeditionLootModel(
          id: 'l3',
          expeditionTypeId: 'bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          itemId: 'aaaaaaa6-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          minQuantity: 1,
          maxQuantity: 2,
          dropWeight: 20,
          item: ItemModel.defaultCatalog[5],
        ),
      ],
    ),
    ExpeditionTypeModel(
      id: 'bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      name: 'Hospital Central',
      description:
          'Área escura e perigosa sob alerta biológico, rica em suprimentos médicos.',
      durationSeconds: 120,
      riskLevel: 'medio',
      minRewardTypes: 2,
      maxRewardTypes: 3,
      lootTable: [
        ExpeditionLootModel(
          id: 'l4',
          expeditionTypeId: 'bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          itemId: 'aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          minQuantity: 2,
          maxQuantity: 4,
          dropWeight: 60,
          item: ItemModel.defaultCatalog[2],
        ),
        ExpeditionLootModel(
          id: 'l5',
          expeditionTypeId: 'bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          itemId: 'aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          minQuantity: 1,
          maxQuantity: 2,
          dropWeight: 35,
          item: ItemModel.defaultCatalog[3],
        ),
        ExpeditionLootModel(
          id: 'l6',
          expeditionTypeId: 'bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          itemId: 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          minQuantity: 1,
          maxQuantity: 2,
          dropWeight: 25,
          item: ItemModel.defaultCatalog[0],
        ),
      ],
    ),
    ExpeditionTypeModel(
      id: 'bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      name: 'Posto de Gasolina',
      description:
          'Tanques subterrâneos e oficina mecânica expostos à horda vermelha.',
      durationSeconds: 180,
      riskLevel: 'alto',
      minRewardTypes: 2,
      maxRewardTypes: 4,
      lootTable: [
        ExpeditionLootModel(
          id: 'l7',
          expeditionTypeId: 'bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          itemId: 'aaaaaaa7-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          minQuantity: 1,
          maxQuantity: 3,
          dropWeight: 55,
          item: ItemModel.defaultCatalog[6],
        ),
        ExpeditionLootModel(
          id: 'l8',
          expeditionTypeId: 'bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          itemId: 'aaaaaaa8-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          minQuantity: 1,
          maxQuantity: 2,
          dropWeight: 35,
          item: ItemModel.defaultCatalog[7],
        ),
        ExpeditionLootModel(
          id: 'l9',
          expeditionTypeId: 'bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          itemId: 'aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          minQuantity: 1,
          maxQuantity: 1,
          dropWeight: 20,
          item: ItemModel.defaultCatalog[4],
        ),
        ExpeditionLootModel(
          id: 'l10',
          expeditionTypeId: 'bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          itemId: 'aaaaaaa6-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          minQuantity: 2,
          maxQuantity: 5,
          dropWeight: 45,
          item: ItemModel.defaultCatalog[5],
        ),
      ],
    ),
  ];
}

class ExpeditionRewardItem {
  final String itemId;
  final String name;
  final String iconName;
  final int quantity;

  const ExpeditionRewardItem({
    required this.itemId,
    required this.name,
    required this.iconName,
    required this.quantity,
  });

  factory ExpeditionRewardItem.fromJson(Map<String, dynamic> json) {
    return ExpeditionRewardItem(
      itemId: json['item_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Item',
      iconName: json['icon_name']?.toString() ?? 'inventory_2',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'name': name,
    'icon_name': iconName,
    'quantity': quantity,
  };
}

class ExpeditionModel {
  final String id;
  final String userId;
  final String expeditionTypeId;
  final DateTime startedAt;
  final DateTime endsAt;
  final String status; // 'in_progress' or 'completed'
  final List<ExpeditionRewardItem> rewards;
  final DateTime? completedAt;
  final ExpeditionTypeModel? expeditionType;

  const ExpeditionModel({
    required this.id,
    required this.userId,
    required this.expeditionTypeId,
    required this.startedAt,
    required this.endsAt,
    required this.status,
    this.rewards = const [],
    this.completedAt,
    this.expeditionType,
  });

  bool get isInProgress => status == 'in_progress';
  bool get isReadyToClaim =>
      isInProgress && DateTime.now().isAfter(endsAt);

  Duration get remainingDuration {
    final diff = endsAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get progressFraction {
    final total = endsAt.difference(startedAt).inMilliseconds;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  factory ExpeditionModel.fromJson(Map<String, dynamic> json) {
    final List<ExpeditionRewardItem> parsedRewards = [];
    if (json['rewards_json'] is List) {
      for (final r in json['rewards_json'] as List) {
        if (r is Map<String, dynamic>) {
          parsedRewards.add(ExpeditionRewardItem.fromJson(r));
        }
      }
    }

    ExpeditionTypeModel? expType;
    if (json['expedition_types'] is Map<String, dynamic>) {
      expType = ExpeditionTypeModel.fromJson(
        json['expedition_types'] as Map<String, dynamic>,
      );
    } else {
      final tid = json['expedition_type_id']?.toString() ?? '';
      expType = ExpeditionTypeModel.defaultTypes
          .where((t) => t.id == tid)
          .firstOrNull;
    }

    return ExpeditionModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      expeditionTypeId: json['expedition_type_id']?.toString() ?? '',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'].toString())?.toLocal() ??
                DateTime.now().add(const Duration(minutes: 1))
          : DateTime.now().add(const Duration(minutes: 1)),
      status: json['status']?.toString() ?? 'in_progress',
      rewards: parsedRewards,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())?.toLocal()
          : null,
      expeditionType: expType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'expedition_type_id': expeditionTypeId,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'status': status,
      'rewards_json': rewards.map((e) => e.toJson()).toList(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      if (expeditionType != null) 'expedition_types': expeditionType!.toJson(),
    };
  }
}
