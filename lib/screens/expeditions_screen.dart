import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/icon_mapper.dart';
import '../models/expedition_models.dart';
import '../providers/game_providers.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/survival_2d_art.dart';

class ExpeditionsScreen extends ConsumerStatefulWidget {
  const ExpeditionsScreen({super.key});

  @override
  ConsumerState<ExpeditionsScreen> createState() => _ExpeditionsScreenState();
}

class _ExpeditionsScreenState extends ConsumerState<ExpeditionsScreen> {
  Future<void> _startExpedition(ExpeditionTypeModel expType) async {
    try {
      await ref
          .read(gameControllerProvider.notifier)
          .startExpedition(expType.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Expedição para "${expType.name}" iniciada! O servidor registrou o horário de término.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ProtocoloZColors.crimsonRed,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _claimRewards(ExpeditionModel activeExp) async {
    try {
      final rewards = await ref
          .read(gameControllerProvider.notifier)
          .claimExpedition(activeExp.id);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ProtocoloZColors.cardGray,
          title: const Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: ProtocoloZColors.radarGreen,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'EXPEDIÇÃO CONCLUÍDA (+10 REP)',
                  style: TextStyle(
                    color: ProtocoloZColors.radarGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suprimentos sorteados pelo servidor (PL/pgSQL) e adicionados ao seu inventário:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              for (final r in rewards)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ProtocoloZColors.bgDarkest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ProtocoloZColors.radarGreen),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        IconMapper.itemIcon(r.iconName),
                        color: ProtocoloZColors.radarGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '+${r.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: ProtocoloZColors.radarGreen,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('GUARDAR NA MOCHILA'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ProtocoloZColors.crimsonRed,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameControllerProvider);
    final activeExp = gs.activeExpedition;
    final expTypes = gs.expeditionTypes.isNotEmpty
        ? gs.expeditionTypes
        : ExpeditionTypeModel.defaultTypes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EXPEDIÇÕES DE COLETA'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeExp != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProtocoloZColors.cardGray,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ProtocoloZColors.radarGreen,
                  width: 1.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.directions_run_rounded,
                        color: ProtocoloZColors.radarGreen,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'MISSÃO EM ANDAMENTO (PERSISTIDA NO SERVIDOR)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: ProtocoloZColors.radarGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ExpeditionScene2D(
                    riskLevel: activeExp.expeditionType?.riskLevel ?? 'medio',
                    placeName:
                        activeExp.expeditionType?.name ?? 'Zona de Coleta',
                    isActive: true,
                    progress: activeExp.progressFraction,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CountdownTimer(
                        endsAt: activeExp.endsAt,
                        onFinished: () => setState(() {}),
                      ),
                      ElevatedButton.icon(
                        onPressed: gs.isLoading
                            ? null
                            : () => _claimRewards(activeExp),
                        icon: const Icon(Icons.redeem_rounded),
                        label: const Text('COLETAR (+10 REP)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            'ZONAS DE EXPLORAÇÃO DISPONÍVEIS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: ProtocoloZColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          for (final expType in expTypes)
            _buildExpeditionTypeCard(expType, activeExp != null, gs.isLoading),
          if (gs.completedExpeditions.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'HISTÓRICO DE EXPEDIÇÕES CONCLUÍDAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: ProtocoloZColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            for (final done in gs.completedExpeditions.take(5))
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle_rounded,
                    color: ProtocoloZColors.radarGreen,
                  ),
                  title: Text(
                    done.expeditionType?.name ?? 'Expedição Concluída',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Itens coletados: ${done.rewards.map((r) => '${r.name} x${r.quantity}').join(', ')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Text(
                    '+10 REP',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: ProtocoloZColors.radarGreen,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpeditionTypeCard(
    ExpeditionTypeModel expType,
    bool hasActive,
    bool isLoading,
  ) {
    final riskColor = IconMapper.riskColor(expType.riskLevel);
    final minutes = (expType.durationSeconds / 60).ceil();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpeditionScene2D(
              riskLevel: expType.riskLevel,
              placeName: expType.name,
              isActive: false,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    expType.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ProtocoloZColors.bgDarkest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: riskColor),
                  ),
                  child: Text(
                    'DURAÇÃO: ${minutes}M (${expType.durationSeconds}S)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: riskColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              expType.description,
              style: const TextStyle(
                fontSize: 13,
                color: ProtocoloZColors.textMuted,
              ),
            ),
            if (expType.lootTable.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'POSSÍVEIS RECOMPENSAS SORTEADAS PELO SERVIDOR:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: ProtocoloZColors.radarGreen,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final loot in expType.lootTable)
                    if (loot.item != null)
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
                        child: Text(
                          '${loot.item!.name} (${loot.minQuantity}-${loot.maxQuantity}x)',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (hasActive || isLoading)
                    ? null
                    : () => _startExpedition(expType),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  hasActive
                      ? 'AGUARDE A EXPEDIÇÃO ATUAL TERMINAR'
                      : 'ENVIAR SOBREVIVENTE (+10 REP AO CONCLUIR)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
