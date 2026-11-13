class SurvivorRankModel {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final int reputation;
  final String? factionId;
  final String? factionName;
  final String? factionSymbol;
  final String? factionColor;
  final int rankPosition;

  const SurvivorRankModel({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.reputation,
    this.factionId,
    this.factionName,
    this.factionSymbol,
    this.factionColor,
    required this.rankPosition,
  });

  factory SurvivorRankModel.fromJson(Map<String, dynamic> json) {
    return SurvivorRankModel(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? 'Sobrevivente',
      avatarUrl: json['avatar_url']?.toString(),
      reputation: (json['reputation'] as num?)?.toInt() ?? 0,
      factionId: json['faction_id']?.toString(),
      factionName: json['faction_name']?.toString(),
      factionSymbol: json['faction_symbol']?.toString(),
      factionColor: json['faction_color']?.toString(),
      rankPosition: (json['rank_position'] as num?)?.toInt() ?? 1,
    );
  }
}

class FactionRankModel {
  final String id;
  final String name;
  final String symbol;
  final String colorHex;
  final int membersCount;
  final int totalReputation;
  final int rankPosition;

  const FactionRankModel({
    required this.id,
    required this.name,
    required this.symbol,
    required this.colorHex,
    required this.membersCount,
    required this.totalReputation,
    required this.rankPosition,
  });

  factory FactionRankModel.fromJson(Map<String, dynamic> json) {
    return FactionRankModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? 'shield',
      colorHex: json['color_hex']?.toString() ?? '#388E3C',
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
      totalReputation: (json['total_reputation'] as num?)?.toInt() ?? 0,
      rankPosition: (json['rank_position'] as num?)?.toInt() ?? 1,
    );
  }
}

class PlayerStatsModel {
  final int completedExpeditions;
  final int completedTrades;
  final int registeredShelters;
  final int confirmedAlerts;

  const PlayerStatsModel({
    this.completedExpeditions = 0,
    this.completedTrades = 0,
    this.registeredShelters = 0,
    this.confirmedAlerts = 0,
  });
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final bool unlocked;
  final double progress;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.unlocked,
    required this.progress,
  });
}

class RadioMessageModel {
  final String id;
  final String senderId;
  final String senderNickname;
  final String factionId;
  final String content;
  final DateTime timestamp;

  const RadioMessageModel({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    required this.factionId,
    required this.content,
    required this.timestamp,
  });

  factory RadioMessageModel.fromJson(Map<String, dynamic> json) {
    return RadioMessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderNickname: json['sender_nickname']?.toString() ?? 'Operador',
      factionId: json['faction_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'sender_nickname': senderNickname,
    'faction_id': factionId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };
}
