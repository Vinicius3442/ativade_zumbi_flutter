import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/icon_mapper.dart';
import '../models/ranking_models.dart';
import '../providers/game_providers.dart';
import '../widgets/faction_badge.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameControllerProvider);
    final uid = gs.profile?.id ?? '';
    final myRank = gs.survivorsRanking
        .where((s) => s.id == uid)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RANKING DA RESISTÊNCIA'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(gameControllerProvider.notifier).refreshAllData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: ProtocoloZColors.radarGreen,
          labelColor: ProtocoloZColors.radarGreen,
          unselectedLabelColor: ProtocoloZColors.textMuted,
          tabs: const [
            Tab(text: 'SOBREVIVENTES'),
            Tab(text: 'FACÇÕES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ABA 1: SOBREVIVENTES
          Column(
            children: [
              if (myRank != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ProtocoloZColors.tacticalGreen.withValues(
                      alpha: 0.22,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ProtocoloZColors.radarGreen,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SUA POSIÇÃO ATUAL: #${myRank.rankPosition} (${myRank.nickname})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: ProtocoloZColors.radarGreen,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${myRank.reputation} PTS',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: ProtocoloZColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gs.survivorsRanking.length,
                  itemBuilder: (_, idx) {
                    final s = gs.survivorsRanking[idx];
                    return _buildSurvivorRankTile(s, s.id == uid);
                  },
                ),
              ),
            ],
          ),
          // ABA 2: FACÇÕES
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gs.factionsRanking.length,
            itemBuilder: (_, idx) {
              final f = gs.factionsRanking[idx];
              return _buildFactionRankCard(f);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSurvivorRankTile(SurvivorRankModel s, bool isCurrentUser) {
    final isTop3 = s.rankPosition <= 3;
    final medalColor = s.rankPosition == 1
        ? ProtocoloZColors.radarGreen
        : s.rankPosition == 2
        ? ProtocoloZColors.textPrimary
        : s.rankPosition == 3
        ? ProtocoloZColors.crimsonRed
        : ProtocoloZColors.steelGray;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCurrentUser
              ? ProtocoloZColors.radarGreen
              : isTop3
              ? medalColor
              : ProtocoloZColors.borderGray,
          width: (isCurrentUser || isTop3) ? 1.8 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: medalColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '#${s.rankPosition}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: medalColor,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${s.nickname}${isCurrentUser ? ' (VOCÊ)' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isCurrentUser
                      ? ProtocoloZColors.radarGreen
                      : ProtocoloZColors.textPrimary,
                ),
              ),
            ),
            if (isTop3)
              Icon(
                Icons.workspace_premium_rounded,
                color: medalColor,
                size: 20,
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              FactionBadge(
                factionName: s.factionName,
                symbol: s.factionSymbol,
                colorHex: s.factionColor,
                compact: true,
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ProtocoloZColors.bgDarkest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: medalColor),
          ),
          child: Text(
            '${s.reputation} REP',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: medalColor,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFactionRankCard(FactionRankModel f) {
    final color = ProtocoloZColors.parseHex(f.colorHex);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color, width: 1.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                IconMapper.factionIcon(f.symbol),
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${f.rankPosition} • ${f.name.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Membros ativos: ${f.membersCount} sobrevivente(s)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: ProtocoloZColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${f.totalReputation}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const Text(
                  'REP TOTAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ProtocoloZColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
