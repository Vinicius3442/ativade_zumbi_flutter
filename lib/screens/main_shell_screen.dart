import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/game_providers.dart';
import '../widgets/horde_alert_banner.dart';

class MainShellScreen extends ConsumerWidget {
  final Widget child;
  final String currentLocation;

  const MainShellScreen({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  int _locationToIndex(String loc) {
    if (loc.startsWith('/mapa') || loc.startsWith('/abrigos')) return 1;
    if (loc.startsWith('/expedicoes')) return 2;
    if (loc.startsWith('/inventario')) return 3;
    if (loc.startsWith('/trocas')) return 4;
    if (loc.startsWith('/ranking')) return 5;
    if (loc.startsWith('/perfil')) return 6;
    return 0;
  }

  void _onTapIndex(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/mapa');
        break;
      case 2:
        context.go('/expedicoes');
        break;
      case 3:
        context.go('/inventario');
        break;
      case 4:
        context.go('/trocas');
        break;
      case 5:
        context.go('/ranking');
        break;
      case 6:
        context.go('/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameControllerProvider);
    final selectedIdx = _locationToIndex(currentLocation);
    final flashAlert = gs.liveFlashAlert;
    final pendingTrades = gs.pendingReceivedTradesCount;
    final hasActiveExp = gs.activeExpedition != null;

    return Scaffold(
      body: Column(
        children: [
          // Banner Global Realtime de Alerta de Horda (visível em qualquer tela!)
          if (flashAlert != null && !flashAlert.isExpired)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: HordeAlertBanner(
                  alert: flashAlert,
                  currentUserId: gs.profile?.id ?? '',
                  onDismiss: () => ref
                      .read(gameControllerProvider.notifier)
                      .dismissLiveFlashAlert(),
                  onConfirm: () async {
                    try {
                      await ref
                          .read(gameControllerProvider.notifier)
                          .confirmHordeAlert(flashAlert.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Avistamento de horda confirmado!'),
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
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: ProtocoloZColors.borderGray, width: 1.2),
          ),
        ),
        child: NavigationBar(
          height: 66,
          backgroundColor: ProtocoloZColors.bgBunker,
          indicatorColor: ProtocoloZColors.tacticalGreen.withValues(alpha: 0.35),
          selectedIndex: selectedIdx,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => _onTapIndex(context, i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.radar_outlined),
              selectedIcon: Icon(
                Icons.radar_rounded,
                color: ProtocoloZColors.radarGreen,
              ),
              label: 'Central',
            ),
            const NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(
                Icons.map_rounded,
                color: ProtocoloZColors.radarGreen,
              ),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: hasActiveExp,
                backgroundColor: ProtocoloZColors.radarGreen,
                child: const Icon(Icons.explore_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: hasActiveExp,
                backgroundColor: ProtocoloZColors.radarGreen,
                child: const Icon(
                  Icons.explore_rounded,
                  color: ProtocoloZColors.radarGreen,
                ),
              ),
              label: 'Missões',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(
                Icons.inventory_2_rounded,
                color: ProtocoloZColors.radarGreen,
              ),
              label: 'Mochila',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pendingTrades > 0,
                label: Text('$pendingTrades'),
                backgroundColor: ProtocoloZColors.hordeRed,
                child: const Icon(Icons.swap_horiz_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pendingTrades > 0,
                label: Text('$pendingTrades'),
                backgroundColor: ProtocoloZColors.hordeRed,
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: ProtocoloZColors.radarGreen,
                ),
              ),
              label: 'Trocas',
            ),
            const NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(
                Icons.emoji_events_rounded,
                color: ProtocoloZColors.radarGreen,
              ),
              label: 'Ranking',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: ProtocoloZColors.radarGreen,
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
