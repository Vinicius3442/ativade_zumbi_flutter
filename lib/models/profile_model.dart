import 'faction_model.dart';

class ProfileModel {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String? factionId;
  final FactionModel? faction;
  final int reputation;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.factionId,
    this.faction,
    required this.reputation,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasFaction => factionId != null && factionId!.isNotEmpty;

  /// Gamificação: nível tático baseado na reputação (a cada 50 pts sobe de patente)
  int get survivalLevel => (reputation ~/ 50) + 1;

  String get rankTitle {
    if (reputation >= 200) return 'COMANDANTE Z';
    if (reputation >= 120) return 'VETERANO DE ZONA';
    if (reputation >= 60) return 'RASTREADOR TÁTICO';
    if (reputation >= 25) return 'BATEDOR DE CAMPO';
    return 'RECRUTA DA RESISTÊNCIA';
  }

  double get levelProgress => (reputation % 50) / 50.0;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    FactionModel? parsedFaction;
    if (json['factions'] is Map<String, dynamic>) {
      parsedFaction = FactionModel.fromJson(
        json['factions'] as Map<String, dynamic>,
      );
    }

    return ProfileModel(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? 'Sobrevivente',
      avatarUrl: json['avatar_url']?.toString(),
      factionId: json['faction_id']?.toString(),
      faction: parsedFaction,
      reputation: (json['reputation'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'faction_id': factionId,
      'reputation': reputation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (faction != null) 'factions': faction!.toJson(),
    };
  }

  ProfileModel copyWith({
    String? nickname,
    String? avatarUrl,
    String? factionId,
    FactionModel? faction,
    int? reputation,
  }) {
    return ProfileModel(
      id: id,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      factionId: factionId ?? this.factionId,
      faction: faction ?? this.faction,
      reputation: reputation ?? this.reputation,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
