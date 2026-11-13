import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/icon_mapper.dart';
import '../models/faction_model.dart';
import '../models/item_model.dart';
import '../providers/game_providers.dart';

class FactionSelectionScreen extends ConsumerStatefulWidget {
  const FactionSelectionScreen({super.key});

  @override
  ConsumerState<FactionSelectionScreen> createState() =>
      _FactionSelectionScreenState();
}

class _FactionSelectionScreenState
    extends ConsumerState<FactionSelectionScreen> {
  String? _selectedFactionId;

  Future<void> _confirmChoice(FactionModel faction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProtocoloZColors.cardGray,
        title: Row(
          children: [
            Icon(
              IconMapper.factionIcon(faction.symbol),
              color: faction.color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'JURAMENTO DEFINITIVO',
                style: TextStyle(
                  color: faction.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Você está prestes a se alistar na facção "${faction.name}".\n\n'
          'ATENÇÃO: Esta escolha é DEFINITIVA e garantida pelo servidor via RPC. '
          'Você receberá imediatamente seu Kit Inicial de Suprimentos.',
          style: const TextStyle(color: ProtocoloZColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('VOLTAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRMAR FACÇÃO'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(gameControllerProvider.notifier)
          .chooseFaction(faction.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bem-vindo à ${faction.name}! Kit inicial de suprimentos adicionado ao seu inventário.',
          ),
        ),
      );
      context.go('/home');
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
    final factions = gs.factions.isNotEmpty
        ? gs.factions
        : FactionModel.defaultFactions;
    final starterItems = ItemModel.defaultCatalog
        .where((i) => i.isStarterItem)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESCOLHA SUA FACÇÃO'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => ref.read(gameControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProtocoloZColors.bgBunker,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ProtocoloZColors.radarGreen),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOBREVIVENTE: ${gs.profile?.nickname.toUpperCase() ?? 'RECRUTA'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: ProtocoloZColors.radarGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No Protocolo Z, ninguém sobrevive sozinho. Escolha sua facção para liberar '
                    'acesso aos abrigos secretos, rádio tático e receber seu Kit Inicial concedido pelo servidor.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ProtocoloZColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'FACÇÕES DA RESISTÊNCIA (ESCOLHA DEFINITIVA)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: ProtocoloZColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            for (final faction in factions)
              _buildFactionCard(faction, _selectedFactionId == faction.id),
            const SizedBox(height: 16),
            // Preview do Kit Inicial de Suprimentos
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ProtocoloZColors.cardGray,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ProtocoloZColors.borderGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        color: ProtocoloZColors.radarGreen,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'KIT INICIAL DE SUPRIMENTOS (SERVIDOR RPC)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: ProtocoloZColors.radarGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in starterItems)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: ProtocoloZColors.bgDarkest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ProtocoloZColors.borderGray),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                IconMapper.itemIcon(item.iconName),
                                size: 15,
                                color: ProtocoloZColors.radarGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${item.name} x${item.starterQuantity}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_selectedFactionId == null || gs.isLoading)
                    ? null
                    : () {
                        final chosen = factions.firstWhere(
                          (f) => f.id == _selectedFactionId,
                        );
                        _confirmChoice(chosen);
                      },
                icon: gs.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_user_rounded),
                label: const Text(
                  'CONFIRMAR ALISTAMENTO E RECEBER KIT INICIAL',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactionCard(FactionModel faction, bool isSelected) {
    final color = faction.color;
    return GestureDetector(
      onTap: () => setState(() => _selectedFactionId = faction.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : ProtocoloZColors.cardGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : ProtocoloZColors.borderGray,
            width: isSelected ? 2.2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                IconMapper.factionIcon(faction.symbol),
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faction.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: ProtocoloZColors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    faction.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ProtocoloZColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? color : ProtocoloZColors.steelGray,
            ),
          ],
        ),
      ),
    );
  }
}
