class HordeAlertModel {
  final String id;
  final String authorId;
  final double latitude;
  final double longitude;
  final String intensity; // 'baixa', 'media', 'alta'
  final String description;
  final int confirmationsCount;
  final bool reputationAwarded;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? authorNickname;
  final List<String> confirmedByUserIds;

  const HordeAlertModel({
    required this.id,
    required this.authorId,
    required this.latitude,
    required this.longitude,
    required this.intensity,
    required this.description,
    required this.confirmationsCount,
    required this.reputationAwarded,
    required this.expiresAt,
    required this.createdAt,
    this.authorNickname,
    this.confirmedByUserIds = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingDuration {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool isConfirmedBy(String userId) => confirmedByUserIds.contains(userId);

  factory HordeAlertModel.fromJson(Map<String, dynamic> json) {
    String? authorNick = json['author_nickname']?.toString();
    if (json['profiles'] is Map<String, dynamic>) {
      authorNick = (json['profiles'] as Map<String, dynamic>)['nickname']
          ?.toString();
    }

    final List<String> confirmers = [];
    if (json['alert_confirmations'] is List) {
      for (final c in json['alert_confirmations'] as List) {
        if (c is Map<String, dynamic> && c['user_id'] != null) {
          confirmers.add(c['user_id'].toString());
        }
      }
    } else if (json['confirmed_by_user_ids'] is List) {
      for (final id in json['confirmed_by_user_ids'] as List) {
        confirmers.add(id.toString());
      }
    }

    return HordeAlertModel(
      id: json['id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -23.5505,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -46.6333,
      intensity: json['intensity']?.toString() ?? 'alta',
      description: json['description']?.toString() ?? 'Movimentação hostil detectada!',
      confirmationsCount: (json['confirmations_count'] as num?)?.toInt() ?? 0,
      reputationAwarded: json['reputation_awarded'] == true,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())?.toLocal() ??
                DateTime.now().add(const Duration(minutes: 30))
          : DateTime.now().add(const Duration(minutes: 30)),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      authorNickname: authorNick,
      confirmedByUserIds: confirmers,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author_id': authorId,
    'latitude': latitude,
    'longitude': longitude,
    'intensity': intensity,
    'description': description,
    'confirmations_count': confirmationsCount,
    'reputation_awarded': reputationAwarded,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'author_nickname': authorNickname,
    'confirmed_by_user_ids': confirmedByUserIds,
  };
}
