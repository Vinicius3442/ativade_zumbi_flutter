import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/shelter_model.dart';
import '../providers/game_providers.dart';
import '../widgets/faction_badge.dart';

class ShelterDetailScreen extends ConsumerStatefulWidget {
  final String shelterId;

  const ShelterDetailScreen({super.key, required this.shelterId});

  @override
  ConsumerState<ShelterDetailScreen> createState() =>
      _ShelterDetailScreenState();
}

class _ShelterDetailScreenState extends ConsumerState<ShelterDetailScreen> {
  Future<void> _showEditDialog(ShelterModel shelter) async {
    final nameCtrl = TextEditingController(text: shelter.name);
    final descCtrl = TextEditingController(text: shelter.description);
    final capCtrl = TextEditingController(text: '${shelter.capacity}');
    String visibility = shelter.visibility;
    String status = shelter.status;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: ProtocoloZColors.cardGray,
          title: const Text('EDITAR ABRIGO'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacidade'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'public', label: Text('PÚBLICO')),
                    ButtonSegment(value: 'faction', label: Text('SÓ FACÇÃO')),
                  ],
                  selected: {visibility},
                  onSelectionChanged: (s) =>
                      setModalState(() => visibility = s.first),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'seguro', label: Text('SEGURO')),
                    ButtonSegment(
                      value: 'comprometido',
                      label: Text('COMPROMETIDO'),
                    ),
                  ],
                  selected: {status},
                  onSelectionChanged: (s) =>
                      setModalState(() => status = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(gameControllerProvider.notifier)
                      .updateShelter(
                        shelterId: shelter.id,
                        name: nameCtrl.text,
                        description: descCtrl.text,
                        capacity: int.tryParse(capCtrl.text) ?? shelter.capacity,
                        visibility: visibility,
                        status: status,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Abrigo atualizado!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
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
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ShelterModel shelter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProtocoloZColors.cardGray,
        title: const Text('EXCLUIR ABRIGO?'),
        content: Text(
          'Deseja realmente remover o abrigo "${shelter.name}" do mapa da resistência?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ProtocoloZColors.crimsonRed,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('EXCLUIR DEFINITIVAMENTE'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    try {
      await ref
          .read(gameControllerProvider.notifier)
          .deleteShelter(shelter.id);
      if (!mounted) return;
      context.pop();
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
    final shelter = gs.shelters
        .where((s) => s.id == widget.shelterId)
        .firstOrNull;

    if (shelter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('DETALHES DO ABRIGO')),
        body: const Center(
          child: Text('Abrigo não encontrado ou restrito a outra facção.'),
        ),
      );
    }

    final isOwner = shelter.authorId == gs.profile?.id;
    final statusColor = shelter.isSafe
        ? ProtocoloZColors.radarGreen
        : ProtocoloZColors.hordeRed;

    return Scaffold(
      appBar: AppBar(
        title: Text(shelter.name.toUpperCase()),
        actions: [
          if (isOwner) ...[
            IconButton(
              tooltip: 'Editar Abrigo',
              onPressed: () => _showEditDialog(shelter),
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              tooltip: 'Excluir Abrigo',
              onPressed: () => _confirmDelete(shelter),
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: ProtocoloZColors.hordeRed,
              ),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Foto do abrigo (Supabase Storage) ou Ilustração 2D de Bunker
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: shelter.photoUrl != null && shelter.photoUrl!.isNotEmpty
                ? Image.network(
                    shelter.photoUrl!,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildFallbackBanner(statusColor),
                  )
                : _buildFallbackBanner(statusColor),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (shelter.faction != null)
                        FactionBadge(faction: shelter.faction),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          'STATUS: ${shelter.status.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    shelter.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shelter.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ProtocoloZColors.textPrimary,
                    ),
                  ),
                  const Divider(height: 28),
                  _buildInfoRow(
                    Icons.person_rounded,
                    'Autor Responsável',
                    shelter.authorNickname ?? 'Sobrevivente',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.groups_rounded,
                    'Capacidade Máxima',
                    '${shelter.capacity} sobreviventes',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    shelter.isPublic
                        ? Icons.public_rounded
                        : Icons.lock_rounded,
                    'Visibilidade RLS',
                    shelter.isPublic
                        ? 'Público (Visível para todas as facções)'
                        : 'Exclusivo da Facção (Oculto para rivais via RLS)',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on_rounded,
                    'Coordenadas Táticas',
                    '${shelter.latitude.toStringAsFixed(5)}, ${shelter.longitude.toStringAsFixed(5)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner(Color statusColor) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: ProtocoloZColors.cardGray,
        border: Border.all(color: statusColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fort_rounded, size: 56, color: statusColor),
            const SizedBox(height: 8),
            const Text(
              'FORTIFICAÇÃO TÁTICA 2D REGISTRADA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: ProtocoloZColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ProtocoloZColors.radarGreen),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: ProtocoloZColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ProtocoloZColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
