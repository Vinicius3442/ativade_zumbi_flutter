import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/horde_alert_model.dart';

class HordeAlertBanner extends StatelessWidget {
  final HordeAlertModel alert;
  final String currentUserId;
  final VoidCallback? onConfirm;
  final VoidCallback? onDismiss;
  final VoidCallback? onTapMap;

  const HordeAlertBanner({
    super.key,
    required this.alert,
    required this.currentUserId,
    this.onConfirm,
    this.onDismiss,
    this.onTapMap,
  });

  @override
  Widget build(BuildContext context) {
    final isOwnAlert = alert.authorId == currentUserId;
    final alreadyConfirmed = alert.isConfirmedBy(currentUserId);
    final remainingMin = alert.remainingDuration.inMinutes;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ProtocoloZColors.darkRedSurface,
            ProtocoloZColors.cardGray,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProtocoloZColors.hordeRed, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: ProtocoloZColors.hordeRed.withValues(alpha: 0.25),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.crisis_alert_rounded,
                color: ProtocoloZColors.hordeRed,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ALERTA DE HORDA • INTENSIDADE ${alert.intensity.toUpperCase()}',
                  style: const TextStyle(
                    color: ProtocoloZColors.hordeRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: ProtocoloZColors.bgDarkest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Expira em ${remainingMin}m',
                  style: const TextStyle(
                    fontSize: 10,
                    color: ProtocoloZColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDismiss,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: ProtocoloZColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.description,
            style: const TextStyle(
              color: ProtocoloZColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Reportado por ${alert.authorNickname ?? 'Sobrevivente'} • '
                  'Confirmações: ${alert.confirmationsCount}/2 ${alert.reputationAwarded ? '(+25 REP CONCEDIDO)' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: alert.reputationAwarded
                        ? ProtocoloZColors.radarGreen
                        : ProtocoloZColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isOwnAlert && !alreadyConfirmed && onConfirm != null)
                ElevatedButton.icon(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProtocoloZColors.crimsonRed,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.verified_rounded, size: 15),
                  label: const Text(
                    'CONFIRMAR AVISTAMENTO',
                    style: TextStyle(fontSize: 11),
                  ),
                )
              else if (alreadyConfirmed)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: ProtocoloZColors.radarGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'CONFIRMADO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: ProtocoloZColors.radarGreen,
                      ),
                    ),
                  ],
                )
              else if (isOwnAlert)
                const Text(
                  'SEU ALERTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: ProtocoloZColors.steelGray,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
