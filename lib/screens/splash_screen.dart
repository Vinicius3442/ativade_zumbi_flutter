import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/game_providers.dart';
import '../widgets/survival_2d_art.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(const Duration(milliseconds: 2200), _checkNavigation);
  }

  void _checkNavigation() {
    if (!mounted) return;
    final gs = ref.read(gameControllerProvider);
    if (!gs.isInitialized) {
      _navTimer = Timer(const Duration(milliseconds: 500), _checkNavigation);
      return;
    }

    switch (gs.authStage) {
      case PlayerAuthState.unauthenticated:
        context.go('/login');
        break;
      case PlayerAuthState.authenticatedNoFaction:
        context.go('/escolher-faccao');
        break;
      case PlayerAuthState.complete:
        context.go('/home');
        break;
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtocoloZColors.bgDarkest,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ProtocoloZLogo2D(size: 165),
              const SizedBox(height: 28),
              const Text(
                'PROTOCOLO Z',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  color: ProtocoloZColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ProtocoloZColors.cardGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ProtocoloZColors.radarGreen),
                ),
                child: const Text(
                  'SOBREVIVER É UM TRABALHO EM EQUIPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: ProtocoloZColors.radarGreen,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  color: ProtocoloZColors.radarGreen,
                  backgroundColor: ProtocoloZColors.cardGray,
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'SINCRONIZANDO REDE DE RESISTÊNCIA...',
                style: TextStyle(
                  fontSize: 11,
                  color: ProtocoloZColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
