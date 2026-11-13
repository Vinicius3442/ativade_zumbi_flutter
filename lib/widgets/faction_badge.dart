import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/icon_mapper.dart';
import '../models/faction_model.dart';

class FactionBadge extends StatelessWidget {
  final FactionModel? faction;
  final String? factionName;
  final String? symbol;
  final String? colorHex;
  final bool compact;
  final double iconSize;

  const FactionBadge({
    super.key,
    this.faction,
    this.factionName,
    this.symbol,
    this.colorHex,
    this.compact = false,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final name = faction?.name ?? factionName ?? 'Sem Facção';
    final sym = faction?.symbol ?? symbol ?? 'shield';
    final hex = faction?.colorHex ?? colorHex ?? '#388E3C';
    final color = ProtocoloZColors.parseHex(hex);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconMapper.factionIcon(sym),
            size: iconSize,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ProtocoloZColors.textPrimary,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
