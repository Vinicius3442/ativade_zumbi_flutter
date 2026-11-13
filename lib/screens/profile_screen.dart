import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../providers/game_providers.dart';
import '../widgets/faction_badge.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _antiCheatLog;
  bool _testingCheat = false;

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null || !mounted) return;

    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      await ref
          .read(gameControllerProvider.notifier)
          .uploadAvatar(bytes, ext);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar enviado para o Supabase Storage com sucesso!'),
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

  Future<void> _runAntiCheatTest(bool testInventory) async {
    setState(() {
      _testingCheat = true;
      _antiCheatLog = 'Executando tentativa de escrita direta no Supabase...';
    });
    final notifier = ref.read(gameControllerProvider.notifier);
    final res = testInventory
        ? await notifier.testCheatInventory()
        : await notifier.testCheatReputation();

    if (!mounted) return;
    setState(() {
      _testingCheat = false;
      _antiCheatLog = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameControllerProvider);
    final profile = gs.profile;
    final repo = ref.watch(protocoloZRepositoryProvider);
    final stats = gs.playerStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DOSSIÊ DO SOBREVIVENTE'),
        actions: [
          IconButton(
            tooltip: 'Encerrar Sessão (Logout)',
            onPressed: () async {
              await ref.read(gameControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: ProtocoloZColors.hordeRed,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Cabeçalho com Avatar (Supabase Storage), Apelido, E-mail, Facção e Reputação
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: ProtocoloZColors.bgDarkest,
                        backgroundImage:
                            (profile?.avatarUrl != null &&
                                profile!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child:
                            (profile?.avatarUrl == null ||
                                profile!.avatarUrl!.isEmpty)
                            ? const Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: ProtocoloZColors.radarGreen,
                              )
                            : null,
                      ),
                      InkWell(
                        onTap: _pickAndUploadAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: ProtocoloZColors.tacticalGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ProtocoloZColors.radarGreen,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.nickname ?? 'Sobrevivente',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    repo.currentUserEmail ?? 'sessao@protocoloz.org',
                    style: const TextStyle(
                      fontSize: 13,
                      color: ProtocoloZColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (profile?.faction != null)
                    FactionBadge(faction: profile!.faction),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ProtocoloZColors.bgDarkest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ProtocoloZColors.radarGreen),
                    ),
                    child: Text(
                      'REPUTAÇÃO: ${profile?.reputation ?? 0} PTS • ${profile?.rankTitle ?? 'RECRUTA'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: ProtocoloZColors.radarGreen,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Estatísticas do Sobrevivente
          const Text(
            'HISTÓRICO OPERACIONAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: ProtocoloZColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _buildStatBox(
                Icons.explore_rounded,
                'Expedições Concluídas',
                '${stats.completedExpeditions}',
                ProtocoloZColors.radarGreen,
              ),
              _buildStatBox(
                Icons.swap_horiz_rounded,
                'Trocas Realizadas',
                '${stats.completedTrades}',
                ProtocoloZColors.radarGreen,
              ),
              _buildStatBox(
                Icons.security_rounded,
                'Abrigos Cadastrados',
                '${stats.registeredShelters}',
                ProtocoloZColors.steelGray,
              ),
              _buildStatBox(
                Icons.crisis_alert_rounded,
                'Alertas Confirmados',
                '${stats.confirmedAlerts}',
                ProtocoloZColors.hordeRed,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Conquistas / Medalhas (Diferencial Seção 4)
          const Text(
            'CONQUISTAS E MEDALHAS DE CAMPO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: ProtocoloZColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          for (final ach in gs.achievements)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  ach.unlocked
                      ? Icons.military_tech_rounded
                      : Icons.lock_outline_rounded,
                  color: ach.unlocked
                      ? ProtocoloZColors.radarGreen
                      : ProtocoloZColors.steelGray,
                  size: 28,
                ),
                title: Text(
                  ach.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ach.unlocked
                        ? ProtocoloZColors.textPrimary
                        : ProtocoloZColors.textMuted,
                  ),
                ),
                subtitle: Text(
                  ach.description,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: ach.unlocked
                    ? const Text(
                        'DESBLOQUEADA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: ProtocoloZColors.radarGreen,
                        ),
                      )
                    : const Text(
                        'PENDENTE',
                        style: TextStyle(
                          fontSize: 10,
                          color: ProtocoloZColors.steelGray,
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 20),

          // 4. Simulador de Teste de Trapaça (Item 5.7 do Desafio Final!)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProtocoloZColors.darkRedSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ProtocoloZColors.hordeRed, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.gpp_bad_rounded,
                      color: ProtocoloZColors.hordeRed,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'LABORATÓRIO ANTI-CHEAT (DESAFIO FINAL ITEM 7)',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: ProtocoloZColors.hordeRed,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Demonstre na apresentação que uma tentativa de alterar `inventory` ou `reputation` '
                  'diretamente com a chave pública e o token do jogador é recusada pelo banco via RLS:',
                  style: TextStyle(
                    fontSize: 12,
                    color: ProtocoloZColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testingCheat
                            ? null
                            : () => _runAntiCheatTest(true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ProtocoloZColors.hordeRed,
                          side: const BorderSide(
                            color: ProtocoloZColors.hordeRed,
                          ),
                        ),
                        icon: const Icon(Icons.bug_report_rounded, size: 16),
                        label: const Text(
                          'FORÇAR INSERT INVENTORY',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testingCheat
                            ? null
                            : () => _runAntiCheatTest(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ProtocoloZColors.hordeRed,
                          side: const BorderSide(
                            color: ProtocoloZColors.hordeRed,
                          ),
                        ),
                        icon: const Icon(Icons.security_rounded, size: 16),
                        label: const Text(
                          'FORÇAR 99999 REPUTAÇÃO',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_antiCheatLog != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ProtocoloZColors.bgDarkest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ProtocoloZColors.radarGreen),
                    ),
                    child: Text(
                      _antiCheatLog!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: ProtocoloZColors.radarGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: ProtocoloZColors.hordeRed,
                side: const BorderSide(color: ProtocoloZColors.hordeRed),
              ),
              onPressed: () async {
                await ref.read(gameControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'ENCERRAR SESSÃO (LOGOUT)',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    IconData icon,
    String label,
    String value,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProtocoloZColors.cardGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProtocoloZColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: accent, size: 20),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ProtocoloZColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
