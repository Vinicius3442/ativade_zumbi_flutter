import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class FactionModel {
  final String id;
  final String name;
  final String description;
  final String symbol;
  final String colorHex;
  final DateTime createdAt;

  const FactionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.symbol,
    required this.colorHex,
    required this.createdAt,
  });

  Color get color => ProtocoloZColors.parseHex(colorHex);

  factory FactionModel.fromJson(Map<String, dynamic> json) {
    return FactionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? 'shield',
      colorHex: json['color_hex']?.toString() ?? '#388E3C',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'symbol': symbol,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static List<FactionModel> get defaultFactions => [
    FactionModel(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Vanguarda de Ferro',
      description:
          'Engenheiros e combatentes focados em fortificação de abrigos, contenção de hordas e defesa pesada.',
      symbol: 'shield',
      colorHex: '#D32F2F',
      createdAt: DateTime(2026, 1, 1),
    ),
    FactionModel(
      id: '22222222-2222-2222-2222-222222222222',
      name: 'Nômades da Cinza',
      description:
          'Batedores rápidos especializados em exploração urbana, rastreamento e coleta tática.',
      symbol: 'compass',
      colorHex: '#388E3C',
      createdAt: DateTime(2026, 1, 1),
    ),
    FactionModel(
      id: '33333333-3333-3333-3333-333333333333',
      name: 'Ordem do Éter',
      description:
          'Médicos e cientistas dedicados à preservação biológica, curativos e tecnologia.',
      symbol: 'medical_services',
      colorHex: '#78909C',
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
}
