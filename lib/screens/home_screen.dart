import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/game_providers.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/faction_badge.dart';
import '../widgets/horde_alert_banner.dart';
import '../widgets/item_tile.dart';
import '../widgets/survival_2d_art.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _showReportHordeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final descCtrl = TextEditingController();
    String intensity = 'alta';
    double lat = -23.5505;
    double lng = -46.6333;
    bool usingGps = false;

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
        usingGps = true;
      }
    } catch (_) {}

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: ProtocoloZColors.cardGray,
          title: const Row(
            children: [
              Icon(Icons.crisis_alert_rounded, color: ProtocoloZColors.hordeRed),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'EMITIR ALERTA DE HORDA',
                  style: TextStyle(
                    color: ProtocoloZColors.hordeRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usingGps
                      ? 'Coordenadas capturadas via GPS: (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})'
                      : 'Coordenadas padrão da Zona Central: (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ProtocoloZColors.radarGreen,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'INTENSIDADE DA HORDA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ProtocoloZColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'baixa', label: Text('BAIXA')),
                    ButtonSegment(value: 'media', label: Text('MÉDIA')),
                    ButtonSegment(value: 'alta', label: Text('ALTA')),
                  ],
                  selected: {intensity},
                  onSelectionChanged: (s) =>
                      setModalState(() => intensity = s.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descrição curta do avistamento',
                    hintText: 'Ex: Dezenas de infectados bloqueando a ponte Sul!',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ProtocoloZColors.crimsonRed,
              ),
              onPressed: () async {
                final text = descCtrl.text.trim();
                if (text.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Descreva o avistamento (mín. 4 letras).'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(gameControllerProvider.notifier)
                      .createHordeAlert(
                        latitude: lat,
                        longitude: lng,
                        intensity: intensity,
                        description: text,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Alerta de horda transmitido em tempo real para todos os sobreviventes!',
                        ),
                      ),
                    );
                  }
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
              icon: const Icon(Icons.cell_tower_rounded, size: 16),
              label: const Text('TRANSMITIR AGORA'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFactionRadioModal(BuildContext context, WidgetRef ref) {
    final msgCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProtocoloZColors.bgBunker,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, modalRef, _) {
          final gs = modalRef.watch(gameControllerProvider);
          final msgs = gs.radioMessages;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SizedBox(
              height: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.radio_rounded,
                        color: ProtocoloZColors.radarGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'RÁDIO DA FACÇÃO: ${gs.profile?.faction?.name.toUpperCase() ?? 'CANAL CRIPTOGRAFADO'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: ProtocoloZColors.radarGreen,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: msgs.isEmpty
                        ? const Center(
                            child: Text(
                              'Frequência silenciosa. Envie um comunicado em tempo real para sua facção!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: ProtocoloZColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            reverse: true,
                            itemCount: msgs.length,
                            itemBuilder: (_, i) {
                              final m = msgs[i];
                              final isMe = m.senderId == gs.profile?.id;
                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? ProtocoloZColors.tacticalGreen
                                              .withValues(alpha: 0.35)
                                        : ProtocoloZColors.cardGray,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isMe
                                          ? ProtocoloZColors.radarGreen
                                          : ProtocoloZColors.borderGray,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.senderNickname,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: ProtocoloZColors.radarGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        m.content,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: ProtocoloZColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: msgCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Transmitir mensagem na frequência...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          final txt = msgCtrl.text.trim();
                          if (txt.isEmpty) return;
                          modalRef
                              .read(gameControllerProvider.notifier)
                              .sendRadioMessage(txt);
                          msgCtrl.clear();
                        },
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameControllerProvider);
    final profile = gs.profile;
    final activeExp = gs.activeExpedition;
    final pendingTrades = gs.pendingReceivedTradesCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CENTRAL DE SOBREVIVÊNCIA'),
        actions: [
          IconButton(
            tooltip: 'Rádio da Facção (Tempo Real)',
            onPressed: () => _showFactionRadioModal(context, ref),
            icon: const Icon(
              Icons.radio_rounded,
              color: ProtocoloZColors.radarGreen,
            ),
          ),
          IconButton(
            tooltip: 'Emitir Alerta de Horda',
            onPressed: () => _showReportHordeDialog(context, ref),
            icon: const Icon(
              Icons.crisis_alert_rounded,
              color: ProtocoloZColors.hordeRed,
            ),
          ),
          IconButton(
            tooltip: 'Atualizar Dados',
            onPressed: () =>
                ref.read(gameControllerProvider.notifier).refreshAllData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: ProtocoloZColors.radarGreen,
        onRefresh: () =>
            ref.read(gameControllerProvider.notifier).refreshAllData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Painel Principal do Sobrevivente + Radar 2D + Reputação
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    ProtocoloZColors.cardGray,
                    ProtocoloZColors.bgBunker,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ProtocoloZColors.radarGreen,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OLÁ, ${profile?.nickname.toUpperCase() ?? 'SOBREVIVENTE'}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: ProtocoloZColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${profile?.rankTitle ?? 'RECRUTA'} • NÍVEL ${profile?.survivalLevel ?? 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: ProtocoloZColors.radarGreen,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (profile?.faction != null)
                              FactionBadge(faction: profile!.faction),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      TacticalRadar2D(
                        shelters: gs.shelters,
                        alerts: gs.activeAlerts,
                        onTap: () => context.go('/mapa'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Barra de Reputação e XP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.military_tech_rounded,
                            color: ProtocoloZColors.radarGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'REPUTAÇÃO ACUMULADA: ${profile?.reputation ?? 0} PTS',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: ProtocoloZColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Próx. patente: ${((profile?.survivalLevel ?? 1) * 50)} pts',
                        style: const TextStyle(
                          fontSize: 11,
                          color: ProtocoloZColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: profile?.levelProgress ?? 0.1,
                    backgroundColor: ProtocoloZColors.bgDarkest,
                    color: ProtocoloZColors.radarGreen,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Diferencial Gamificado: Consumo Diário / Sequência de Dias Sobrevividos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ProtocoloZColors.bgBunker,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ProtocoloZColors.borderGray),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: ProtocoloZColors.radarGreen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SEQUÊNCIA DE SOBREVIVÊNCIA: ${gs.survivalStreakDays} DIA(S)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: ProtocoloZColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Registre seu consumo diário de ração para manter o sinal ativo',
                          style: TextStyle(
                            fontSize: 11,
                            color: ProtocoloZColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!gs.checkedInToday)
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(gameControllerProvider.notifier)
                            .checkInDailyRation();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Check-in diário confirmado! Mais um dia sobrevivendo à horda.',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'CHECK-IN',
                        style: TextStyle(fontSize: 11),
                      ),
                    )
                  else
                    const Icon(
                      Icons.check_circle_rounded,
                      color: ProtocoloZColors.radarGreen,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Expedição em andamento ou atalho para iniciar nova
            _buildSectionHeader(
              title: 'STATUS DE EXPEDIÇÃO',
              actionLabel: 'VER MISSÕES',
              onAction: () => context.go('/expedicoes'),
            ),
            const SizedBox(height: 8),
            if (activeExp != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExpeditionScene2D(
                        riskLevel: activeExp.expeditionType?.riskLevel ?? 'medio',
                        placeName:
                            activeExp.expeditionType?.name ?? 'Zona Infectada',
                        isActive: true,
                        progress: activeExp.progressFraction,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CountdownTimer(
                            endsAt: activeExp.endsAt,
                            onFinished: () => ref
                                .read(gameControllerProvider.notifier)
                                .refreshAllData(silent: true),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/expedicoes'),
                            icon: const Icon(
                              Icons.inventory_rounded,
                              size: 16,
                            ),
                            label: Text(
                              activeExp.isReadyToClaim
                                  ? 'COLETAR LOOT!'
                                  : 'ACOMPANHAR',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ProtocoloZColors.tacticalGreen.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ProtocoloZColors.radarGreen),
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      color: ProtocoloZColors.radarGreen,
                    ),
                  ),
                  title: const Text(
                    'Nenhuma expedição em andamento',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Envie seu sobrevivente para coletar água, comida, remédios e gasolina (+10 rep).',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => context.go('/expedicoes'),
                    child: const Text('INICIAR'),
                  ),
                ),
              ),
            const SizedBox(height: 18),

            // 3. Propostas de Troca Pendentes + Atalhos Rápidos
            Row(
              children: [
                Expanded(
                  child: _buildStatShortcutCard(
                    icon: Icons.swap_horiz_rounded,
                    title: 'TROCAS PENDENTES',
                    value: '$pendingTrades',
                    subtitle: pendingTrades > 0
                        ? 'Aguardando sua resposta!'
                        : 'Propor troca (+20 rep)',
                    accent: pendingTrades > 0
                        ? ProtocoloZColors.hordeRed
                        : ProtocoloZColors.radarGreen,
                    onTap: () => context.go('/trocas'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatShortcutCard(
                    icon: Icons.security_rounded,
                    title: 'ABRIGOS NO MAPA',
                    value: '${gs.shelters.length}',
                    subtitle: 'Ver ou cadastrar (+15 rep)',
                    accent: ProtocoloZColors.radarGreen,
                    onTap: () => context.go('/mapa'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4. Resumo dos Suprimentos Principais do Inventário
            _buildSectionHeader(
              title: 'SUPRIMENTOS NA MOCHILA (${gs.totalInventoryUnits} ITENS)',
              actionLabel: 'ABRIR INVENTÁRIO',
              onAction: () => context.go('/inventario'),
            ),
            const SizedBox(height: 8),
            if (gs.inventory.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProtocoloZColors.cardGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ProtocoloZColors.borderGray),
                ),
                child: const Text(
                  'Mochila vazia. Inicie uma expedição para coletar suprimentos.',
                  style: TextStyle(color: ProtocoloZColors.textMuted),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in gs.inventory.take(6))
                    ItemTile(
                      item: entry.item,
                      quantity: entry.quantity,
                      compact: true,
                      onTap: () => context.go('/inventario'),
                    ),
                ],
              ),
            const SizedBox(height: 20),

            // 5. Alertas de Horda Ativos
            _buildSectionHeader(
              title: 'ALERTAS DE HORDA ATIVOS (${gs.activeAlerts.length})',
              actionLabel: 'REPORTAR HORDA',
              onAction: () => _showReportHordeDialog(context, ref),
            ),
            const SizedBox(height: 8),
            if (gs.activeAlerts.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProtocoloZColors.cardGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ProtocoloZColors.borderGray),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: ProtocoloZColors.radarGreen,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nenhum alerta de horda ativo nos últimos 30 minutos. Perímetro seguro.',
                        style: TextStyle(color: ProtocoloZColors.textMuted),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final alert in gs.activeAlerts)
                HordeAlertBanner(
                  alert: alert,
                  currentUserId: profile?.id ?? '',
                  onConfirm: () async {
                    try {
                      await ref
                          .read(gameControllerProvider.notifier)
                          .confirmHordeAlert(alert.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Avistamento confirmado! Ao atingir 2 confirmações o autor recebe +25 reputação.',
                            ),
                          ),
                        );
                      }
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
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: ProtocoloZColors.textMuted,
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: ProtocoloZColors.radarGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatShortcutCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ProtocoloZColors.cardGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: accent, size: 22),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: ProtocoloZColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: ProtocoloZColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
