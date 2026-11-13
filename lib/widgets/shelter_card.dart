import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/shelter_model.dart';
import 'faction_badge.dart';

class ShelterCard extends StatelessWidget {
  final ShelterModel shelter;
  final VoidCallback? onTap;
  final bool isOwner;

  const ShelterCard({
    super.key,
    required this.shelter,
    this.onTap,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = shelter.isSafe
        ? ProtocoloZColors.radarGreen
        : ProtocoloZColors.hordeRed;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor),
                    ),
                    child: Icon(
                      shelter.isSafe
                          ? Icons.security_rounded
                          : Icons.warning_amber_rounded,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shelter.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ProtocoloZColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Autor: ${shelter.authorNickname ?? 'Sobrevivente'} • Cap: ${shelter.capacity} pessoas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ProtocoloZColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      shelter.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                shelter.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: ProtocoloZColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (shelter.faction != null)
                        FactionBadge(faction: shelter.faction, compact: true),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ProtocoloZColors.bgDarkest,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: ProtocoloZColors.borderGray),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              shelter.isPublic
                                  ? Icons.public_rounded
                                  : Icons.lock_rounded,
                              size: 12,
                              color: shelter.isPublic
                                  ? ProtocoloZColors.radarGreen
                                  : ProtocoloZColors.steelGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              shelter.isPublic ? 'PÚBLICO' : 'SÓ FACÇÃO',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: ProtocoloZColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isOwner)
                    const Text(
                      'SEU ABRIGO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: ProtocoloZColors.radarGreen,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
