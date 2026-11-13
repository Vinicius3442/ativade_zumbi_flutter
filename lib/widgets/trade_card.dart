import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/icon_mapper.dart';
import '../models/trade_models.dart';

class TradeCard extends StatelessWidget {
  final TradeModel trade;
  final String currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const TradeCard({
    super.key,
    required this.trade,
    required this.currentUserId,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onCancel,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return ProtocoloZColors.radarGreen;
      case 'pending':
        return ProtocoloZColors.steelGray;
      case 'rejected':
      case 'cancelled':
      case 'expired':
        return ProtocoloZColors.hordeRed;
      default:
        return ProtocoloZColors.steelGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceived = trade.receiverId == currentUserId;
    final status = trade.effectiveStatus;
    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isReceived
                            ? Icons.call_received_rounded
                            : Icons.call_made_rounded,
                        size: 18,
                        color: isReceived
                            ? ProtocoloZColors.radarGreen
                            : ProtocoloZColors.steelGray,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isReceived
                            ? 'DE: ${trade.senderNickname ?? 'Sobrevivente'}'
                            : 'PARA: ${trade.receiverNickname ?? 'Sobrevivente'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ProtocoloZColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      trade.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildItemColumn(
                      title: isReceived ? 'ELE OFERECE' : 'VOCÊ OFERECE',
                      items: trade.offeredItems,
                      accent: ProtocoloZColors.radarGreen,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: ProtocoloZColors.steelGray,
                    ),
                  ),
                  Expanded(
                    child: _buildItemColumn(
                      title: isReceived ? 'ELE PEDE' : 'VOCÊ PEDE',
                      items: trade.requestedItems,
                      accent: ProtocoloZColors.crimsonRed,
                    ),
                  ),
                ],
              ),
              if (status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isReceived) ...[
                      OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('RECUSAR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ProtocoloZColors.hordeRed,
                          side: const BorderSide(
                            color: ProtocoloZColors.hordeRed,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('ACEITAR (+20 REP)'),
                      ),
                    ] else if (onCancel != null)
                      OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('CANCELAR PROPOSTA'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ProtocoloZColors.hordeRed,
                          side: const BorderSide(
                            color: ProtocoloZColors.hordeRed,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemColumn({
    required String title,
    required List<TradeItemModel> items,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ProtocoloZColors.bgDarkest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ProtocoloZColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: accent,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          for (final ti in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    IconMapper.itemIcon(ti.item.iconName),
                    size: 14,
                    color: accent,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ti.item.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ProtocoloZColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'x${ti.quantity}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
