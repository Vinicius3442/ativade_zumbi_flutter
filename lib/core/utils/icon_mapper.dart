import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IconMapper {
  static IconData factionIcon(String symbol) {
    switch (symbol.toLowerCase().trim()) {
      case 'shield':
        return Icons.shield_rounded;
      case 'compass':
        return Icons.explore_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'skull':
        return Icons.dangerous_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  static IconData itemIcon(String iconName) {
    switch (iconName.toLowerCase().trim()) {
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'healing':
        return Icons.healing_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'build':
        return Icons.handyman_rounded;
      case 'hardware':
        return Icons.hardware_rounded;
      case 'local_gas_station':
        return Icons.local_gas_station_rounded;
      case 'battery_charging_full':
        return Icons.battery_charging_full_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  static String categoryLabel(String category) {
    switch (category.toLowerCase().trim()) {
      case 'agua':
        return 'Água';
      case 'comida':
        return 'Comida';
      case 'medicamentos':
        return 'Medicamentos';
      case 'ferramentas':
        return 'Ferramentas';
      case 'combustivel':
        return 'Combustível';
      default:
        return category;
    }
  }

  /// Retorna apenas cores dentro da paleta temática Verde, Cinza e Vermelho
  static Color categoryColor(String category) {
    switch (category.toLowerCase().trim()) {
      case 'agua':
        return ProtocoloZColors.radarGreen;
      case 'comida':
        return ProtocoloZColors.mossGreen;
      case 'medicamentos':
        return ProtocoloZColors.hordeRed;
      case 'ferramentas':
        return ProtocoloZColors.steelGray;
      case 'combustivel':
        return ProtocoloZColors.crimsonRed;
      default:
        return ProtocoloZColors.radarGreen;
    }
  }

  static Color riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase().trim()) {
      case 'baixo':
        return ProtocoloZColors.radarGreen;
      case 'medio':
        return ProtocoloZColors.steelGray;
      case 'alto':
        return ProtocoloZColors.hordeRed;
      default:
        return ProtocoloZColors.steelGray;
    }
  }
}
