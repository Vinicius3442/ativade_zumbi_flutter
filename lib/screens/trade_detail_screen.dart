import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/game_providers.dart';
import '../widgets/trade_card.dart';

class TradeDetailScreen extends ConsumerWidget {
  final String tradeId;

  const TradeDetailScreen({super.key, required this.tradeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameControllerProvider);
    final uid = gs.profile?.id ?? '';
    final trade = gs.trades.where((t) => t.id == tradeId).firstOrNull;

    if (trade == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('DETALHES DA TROCA')),
        body: const Center(child: Text('Proposta de troca não encontrada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DETALHES DA PROPOSTA'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ProtocoloZColors.bgBunker,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ProtocoloZColors.radarGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROTOCOLO DE TRANSAÇÃO ATÔMICA #${trade.id.substring(0, trade.id.length > 8 ? 8 : trade.id.length)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: ProtocoloZColors.radarGreen,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Expira em: ${trade.expiresAt.toString().substring(0, 16)} (24h servidor)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ProtocoloZColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TradeCard(
            trade: trade,
            currentUserId: uid,
            onAccept: () async {
              try {
                await ref
                    .read(gameControllerProvider.notifier)
                    .respondTrade(tradeId: trade.id, action: 'accept');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: ProtocoloZColors.crimsonRed,
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            },
            onReject: () async {
              await ref
                  .read(gameControllerProvider.notifier)
                  .respondTrade(tradeId: trade.id, action: 'reject');
            },
            onCancel: () async {
              await ref
                  .read(gameControllerProvider.notifier)
                  .respondTrade(tradeId: trade.id, action: 'cancel');
            },
          ),
        ],
      ),
    );
  }
}
