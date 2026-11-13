import 'faction_model.dart';

class ShelterModel {
  final String id;
  final String authorId;
  final String factionId;
  final String name;
  final String description;
  final int capacity;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final String visibility; // 'public' or 'faction'
  final String status; // 'seguro' or 'comprometido'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorNickname;
  final FactionModel? faction;

  const ShelterModel({
    required this.id,
    required this.authorId,
    required this.factionId,
    required this.name,
    required this.description,
    required this.capacity,
    this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.visibility,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.authorNickname,
    this.faction,
  });

  bool get isPublic => visibility == 'public';
  bool get isSafe => status == 'seguro';

  factory ShelterModel.fromJson(Map<String, dynamic> json) {
    String? authorNick;
    if (json['profiles'] is Map<String, dynamic>) {
      authorNick = (json['profiles'] as Map<String, dynamic>)['nickname']
          ?.toString();
    } else if (json['author_nickname'] != null) {
      authorNick = json['author_nickname']?.toString();
    }

    FactionModel? parsedFaction;
    if (json['factions'] is Map<String, dynamic>) {
      parsedFaction = FactionModel.fromJson(
        json['factions'] as Map<String, dynamic>,
      );
    }

    return ShelterModel(
      id: json['id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      factionId: json['faction_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Abrigo sem nome',
      description: json['description']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 10,
      photoUrl: json['photo_url']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? -23.5505,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -46.6333,
      visibility: json['visibility']?.toString() ?? 'public',
      status: json['status']?.toString() ?? 'seguro',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      authorNickname: authorNick,
      faction: parsedFaction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'faction_id': factionId,
      'name': name,
      'description': description,
      'capacity': capacity,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'visibility': visibility,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (authorNickname != null) 'author_nickname': authorNickname,
      if (faction != null) 'factions': faction!.toJson(),
    };
  }
}
