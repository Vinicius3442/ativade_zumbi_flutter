import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/game_providers.dart';
import '../screens/auth_screen.dart';
import '../screens/expeditions_screen.dart';
import '../screens/faction_selection_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/map_shelters_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/ranking_screen.dart';
import '../screens/shelter_detail_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/trade_detail_screen.dart';
import '../screens/trades_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final gs = ref.read(gameControllerProvider);
      final loc = state.matchedLocation;

      if (!gs.isInitialized) {
        return loc == '/splash' ? null : '/splash';
      }

      switch (gs.authStage) {
        case PlayerAuthState.unauthenticated:
          // Não autenticado: protege todas as rotas internas
          if (loc == '/login' || loc == '/splash') return null;
          return '/login';

        case PlayerAuthState.authenticatedNoFaction:
          // Autenticado sem facção: obriga escolher facção antes de acessar qualquer tela interna
          if (loc == '/escolher-faccao') return null;
          return '/escolher-faccao';

        case PlayerAuthState.complete:
          // Cadastro completo: redireciona de splash/login/escolher-faccao para a Central
          if (loc == '/splash' ||
              loc == '/login' ||
              loc == '/escolher-faccao') {
            return '/home';
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/escolher-faccao',
        builder: (context, state) => const FactionSelectionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShellScreen(
            currentLocation: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/mapa',
            builder: (context, state) => const MapSheltersScreen(),
          ),
          GoRoute(
            path: '/abrigos/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ShelterDetailScreen(shelterId: id);
            },
          ),
          GoRoute(
            path: '/expedicoes',
            builder: (context, state) => const ExpeditionsScreen(),
          ),
          GoRoute(
            path: '/inventario',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/trocas',
            builder: (context, state) => const TradesScreen(),
          ),
          GoRoute(
            path: '/trocas/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return TradeDetailScreen(tradeId: id);
            },
          ),
          GoRoute(
            path: '/ranking',
            builder: (context, state) => const RankingScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
