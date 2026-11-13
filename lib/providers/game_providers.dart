import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expedition_models.dart';
import '../models/faction_model.dart';
import '../models/horde_alert_model.dart';
import '../models/inventory_entry_model.dart';
import '../models/item_model.dart';
import '../models/profile_model.dart';
import '../models/ranking_models.dart';
import '../models/shelter_model.dart';
import '../models/trade_models.dart';
import '../repositories/protocolo_z_repository.dart';
import '../services/local_cache_service.dart';

enum PlayerAuthState {
  unauthenticated,
  authenticatedNoFaction,
  complete,
}

class GameState {
  final bool isInitialized;
  final bool isLoading;
  final bool isAuthenticated;
  final bool isSimulationMode;
  final ProfileModel? profile;
  final List<FactionModel> factions;
  final List<ItemModel> catalogItems;
  final List<InventoryEntryModel> inventory;
  final List<ShelterModel> shelters;
  final List<ExpeditionTypeModel> expeditionTypes;
  final ExpeditionModel? activeExpedition;
  final List<ExpeditionModel> completedExpeditions;
  final List<TradeModel> trades;
  final List<ProfileModel> otherSurvivors;
  final List<HordeAlertModel> activeAlerts;
  final HordeAlertModel? liveFlashAlert;
  final List<SurvivorRankModel> survivorsRanking;
  final List<FactionRankModel> factionsRanking;
  final PlayerStatsModel playerStats;
  final List<RadioMessageModel> radioMessages;
  final int survivalStreakDays;
  final bool checkedInToday;
  final String? lastError;

  const GameState({
    this.isInitialized = false,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.isSimulationMode = false,
    this.profile,
    this.factions = const [],
    this.catalogItems = const [],
    this.inventory = const [],
    this.shelters = const [],
    this.expeditionTypes = const [],
    this.activeExpedition,
    this.completedExpeditions = const [],
    this.trades = const [],
    this.otherSurvivors = const [],
    this.activeAlerts = const [],
    this.liveFlashAlert,
    this.survivorsRanking = const [],
    this.factionsRanking = const [],
    this.playerStats = const PlayerStatsModel(),
    this.radioMessages = const [],
    this.survivalStreakDays = 1,
    this.checkedInToday = false,
    this.lastError,
  });

  PlayerAuthState get authStage {
    if (!isAuthenticated || profile == null) {
      return PlayerAuthState.unauthenticated;
    }
    if (!profile!.hasFaction) {
      return PlayerAuthState.authenticatedNoFaction;
    }
    return PlayerAuthState.complete;
  }

  int get pendingReceivedTradesCount {
    final uid = profile?.id;
    if (uid == null) return 0;
    return trades
        .where((t) => t.receiverId == uid && t.effectiveStatus == 'pending')
        .length;
  }

  int get totalInventoryUnits =>
      inventory.fold<int>(0, (sum, entry) => sum + entry.quantity);

  List<AchievementModel> get achievements {
    final rep = profile?.reputation ?? 0;
    return [
      AchievementModel(
        id: 'ach_starter',
        title: 'Juramento de Facção',
        description: 'Escolheu sua facção definitiva e recebeu o kit inicial.',
        iconName: 'shield',
        unlocked: profile?.hasFaction == true,
        progress: profile?.hasFaction == true ? 1.0 : 0.0,
      ),
      AchievementModel(
        id: 'ach_scavenger',
        title: 'Batedor da Zona Cinza',
        description: 'Concluiu pelo menos 1 expedição de coleta (+10 rep).',
        iconName: 'explore',
        unlocked: playerStats.completedExpeditions >= 1,
        progress: (playerStats.completedExpeditions / 1).clamp(0.0, 1.0),
      ),
      AchievementModel(
        id: 'ach_architect',
        title: 'Arquiteto de Bunker',
        description: 'Cadastrou um abrigo tático no mapa (+15 rep).',
        iconName: 'home_work',
        unlocked: playerStats.registeredShelters >= 1,
        progress: (playerStats.registeredShelters / 1).clamp(0.0, 1.0),
      ),
      AchievementModel(
        id: 'ach_trader',
        title: 'Mercador do Apocalipse',
        description: 'Concluiu uma troca atômica entre sobreviventes (+20 rep).',
        iconName: 'swap_horiz',
        unlocked: playerStats.completedTrades >= 1,
        progress: (playerStats.completedTrades / 1).clamp(0.0, 1.0),
      ),
      AchievementModel(
        id: 'ach_sentinel',
        title: 'Sentinela da Horda',
        description: 'Confirmou avistamento de horda em tempo real.',
        iconName: 'warning',
        unlocked: playerStats.confirmedAlerts >= 1,
        progress: (playerStats.confirmedAlerts / 1).clamp(0.0, 1.0),
      ),
      AchievementModel(
        id: 'ach_legend',
        title: 'Lenda do Protocolo Z',
        description: 'Alcançou 100 pontos de reputação na resistência.',
        iconName: 'military_tech',
        unlocked: rep >= 100,
        progress: (rep / 100.0).clamp(0.0, 1.0),
      ),
    ];
  }

  GameState copyWith({
    bool? isInitialized,
    bool? isLoading,
    bool? isAuthenticated,
    bool? isSimulationMode,
    ProfileModel? profile,
    bool clearProfile = false,
    List<FactionModel>? factions,
    List<ItemModel>? catalogItems,
    List<InventoryEntryModel>? inventory,
    List<ShelterModel>? shelters,
    List<ExpeditionTypeModel>? expeditionTypes,
    ExpeditionModel? activeExpedition,
    bool clearActiveExpedition = false,
    List<ExpeditionModel>? completedExpeditions,
    List<TradeModel>? trades,
    List<ProfileModel>? otherSurvivors,
    List<HordeAlertModel>? activeAlerts,
    HordeAlertModel? liveFlashAlert,
    bool clearLiveFlashAlert = false,
    List<SurvivorRankModel>? survivorsRanking,
    List<FactionRankModel>? factionsRanking,
    PlayerStatsModel? playerStats,
    List<RadioMessageModel>? radioMessages,
    int? survivalStreakDays,
    bool? checkedInToday,
    String? lastError,
    bool clearError = false,
  }) {
    return GameState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSimulationMode: isSimulationMode ?? this.isSimulationMode,
      profile: clearProfile ? null : (profile ?? this.profile),
      factions: factions ?? this.factions,
      catalogItems: catalogItems ?? this.catalogItems,
      inventory: inventory ?? this.inventory,
      shelters: shelters ?? this.shelters,
      expeditionTypes: expeditionTypes ?? this.expeditionTypes,
      activeExpedition: clearActiveExpedition
          ? null
          : (activeExpedition ?? this.activeExpedition),
      completedExpeditions: completedExpeditions ?? this.completedExpeditions,
      trades: trades ?? this.trades,
      otherSurvivors: otherSurvivors ?? this.otherSurvivors,
      activeAlerts: activeAlerts ?? this.activeAlerts,
      liveFlashAlert: clearLiveFlashAlert
          ? null
          : (liveFlashAlert ?? this.liveFlashAlert),
      survivorsRanking: survivorsRanking ?? this.survivorsRanking,
      factionsRanking: factionsRanking ?? this.factionsRanking,
      playerStats: playerStats ?? this.playerStats,
      radioMessages: radioMessages ?? this.radioMessages,
      survivalStreakDays: survivalStreakDays ?? this.survivalStreakDays,
      checkedInToday: checkedInToday ?? this.checkedInToday,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

final protocoloZRepositoryProvider = Provider<ProtocoloZRepository>((ref) {
  final cache = ref.watch(localCacheServiceProvider);
  return ProtocoloZRepository(Supabase.instance.client, cache);
});

class RouterRefreshListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefreshListenable>((ref) {
  return RouterRefreshListenable();
});

class GameController extends StateNotifier<GameState> {
  final ProtocoloZRepository _repo;
  final LocalCacheService _cache;
  final RouterRefreshListenable _routerRefresh;

  StreamSubscription<AuthState>? _authSub;
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _radioChannel;
  Timer? _alertCleanupTimer;

  GameController(this._repo, this._cache, this._routerRefresh)
      : super(
          GameState(
            factions: FactionModel.defaultFactions,
            catalogItems: ItemModel.defaultCatalog,
            expeditionTypes: ExpeditionTypeModel.defaultTypes,
          ),
        ) {
    _init();
  }

  Future<void> _init() async {
    final streakInfo = await _cache.getDailySurvivalStatus();
    state = state.copyWith(
      survivalStreakDays: streakInfo.streakDays,
      checkedInToday: streakInfo.checkedInToday,
    );

    _authSub = _repo.authStateChanges.listen((authState) async {
      if (_repo.isSimulationMode) return;
      final session = authState.session;
      if (session != null) {
        await refreshAllData(silent: true);
      } else {
        _teardownChannels();
        state = GameState(
          isInitialized: true,
          isAuthenticated: false,
          factions: FactionModel.defaultFactions,
          catalogItems: ItemModel.defaultCatalog,
          expeditionTypes: ExpeditionTypeModel.defaultTypes,
        );
        _routerRefresh.notify();
      }
    });

    // Limpa alertas expirados (> 30 min) a cada 20 segundos
    _alertCleanupTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      final valid = state.activeAlerts.where((a) => !a.isExpired).toList();
      if (valid.length != state.activeAlerts.length) {
        state = state.copyWith(activeAlerts: valid);
      }
    });

    if (_repo.currentAuthUser != null) {
      await refreshAllData(silent: false);
    } else {
      final factions = await _repo.fetchFactions();
      state = state.copyWith(
        isInitialized: true,
        isAuthenticated: false,
        factions: factions,
      );
      _routerRefresh.notify();
    }
  }

  void _setupRealtimeChannels(ProfileModel profile) {
    if (_repo.isSimulationMode) return;

    _realtimeChannel ??= _repo.subscribeToRealtimeEvents(
      onHordeAlertChanged: (newAlert) async {
        final alerts = await _repo.fetchActiveHordeAlerts();
        state = state.copyWith(
          activeAlerts: alerts,
          liveFlashAlert: newAlert ?? alerts.firstOrNull,
        );
      },
      onTradeChanged: () async {
        final trades = await _repo.fetchTrades();
        final inv = await _repo.fetchInventory();
        final updatedProfile = await _repo.fetchCurrentProfile();
        state = state.copyWith(
          trades: trades,
          inventory: inv,
          profile: updatedProfile,
        );
      },
    );

    if (profile.hasFaction && _radioChannel == null) {
      _radioChannel = _repo.subscribeToFactionRadio(
        factionId: profile.factionId!,
        onMessageReceived: (msg) {
          final exists = state.radioMessages.any((m) => m.id == msg.id);
          if (!exists) {
            state = state.copyWith(
              radioMessages: [msg, ...state.radioMessages],
            );
          }
        },
      );
    }
  }

  void _teardownChannels() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _radioChannel?.unsubscribe();
    _radioChannel = null;
  }

  Future<void> refreshAllData({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final factions = await _repo.fetchFactions();
      final profile = await _repo.fetchCurrentProfile();

      if (profile == null) {
        state = state.copyWith(
          isInitialized: true,
          isLoading: false,
          isAuthenticated: false,
          clearProfile: true,
          factions: factions,
        );
        _routerRefresh.notify();
        return;
      }

      if (!profile.hasFaction) {
        state = state.copyWith(
          isInitialized: true,
          isLoading: false,
          isAuthenticated: true,
          isSimulationMode: _repo.isSimulationMode,
          profile: profile,
          factions: factions,
        );
        _routerRefresh.notify();
        return;
      }

      _setupRealtimeChannels(profile);

      final results = await Future.wait([
        _repo.fetchCatalogItems(),
        _repo.fetchInventory(),
        _repo.fetchShelters(),
        _repo.fetchExpeditionTypes(),
        _repo.fetchActiveExpedition(),
        _repo.fetchCompletedExpeditions(),
        _repo.fetchTrades(),
        _repo.fetchOtherSurvivors(),
        _repo.fetchActiveHordeAlerts(),
        _repo.fetchSurvivorsRanking(),
        _repo.fetchFactionsRanking(),
        _repo.fetchPlayerStats(),
      ]);

      final activeExp = results[4] as ExpeditionModel?;

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        isAuthenticated: true,
        isSimulationMode: _repo.isSimulationMode,
        profile: profile,
        factions: factions,
        catalogItems: results[0] as List<ItemModel>,
        inventory: results[1] as List<InventoryEntryModel>,
        shelters: results[2] as List<ShelterModel>,
        expeditionTypes: results[3] as List<ExpeditionTypeModel>,
        activeExpedition: activeExp,
        clearActiveExpedition: activeExp == null,
        completedExpeditions: results[5] as List<ExpeditionModel>,
        trades: results[6] as List<TradeModel>,
        otherSurvivors: results[7] as List<ProfileModel>,
        activeAlerts: results[8] as List<HordeAlertModel>,
        survivorsRanking: results[9] as List<SurvivorRankModel>,
        factionsRanking: results[10] as List<FactionRankModel>,
        playerStats: results[11] as PlayerStatsModel,
      );
      _routerRefresh.notify();
    } catch (e) {
      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      _routerRefresh.notify();
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.signIn(email: email, password: password);
      await refreshAllData(silent: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> signUp(String nickname, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.signUp(nickname: nickname, email: email, password: password);
      await refreshAllData(silent: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> enterSimulationMode(String nickname) async {
    _repo.enterSimulationMode(nickname: nickname);
    await refreshAllData(silent: false);
  }

  Future<void> signOut() async {
    _teardownChannels();
    await _repo.signOut();
    state = GameState(
      isInitialized: true,
      isAuthenticated: false,
      factions: FactionModel.defaultFactions,
      catalogItems: ItemModel.defaultCatalog,
      expeditionTypes: ExpeditionTypeModel.defaultTypes,
    );
    _routerRefresh.notify();
  }

  Future<void> chooseFaction(String factionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.chooseFaction(factionId);
      await refreshAllData(silent: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> startExpedition(String expeditionTypeId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final exp = await _repo.startExpedition(expeditionTypeId);
      state = state.copyWith(
        isLoading: false,
        activeExpedition: exp,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<List<ExpeditionRewardItem>> claimExpedition(
    String expeditionId,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rewards = await _repo.claimExpedition(expeditionId);
      await refreshAllData(silent: true);
      state = state.copyWith(isLoading: false);
      return rewards;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<ShelterModel> createShelter({
    required String name,
    required String description,
    required int capacity,
    required double latitude,
    required double longitude,
    required String visibility,
    required String status,
    Uint8List? photoBytes,
    String? photoExtension,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repo.createShelter(
        name: name,
        description: description,
        capacity: capacity,
        latitude: latitude,
        longitude: longitude,
        visibility: visibility,
        status: status,
        photoBytes: photoBytes,
        photoExtension: photoExtension,
      );
      await refreshAllData(silent: true);
      state = state.copyWith(isLoading: false);
      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> updateShelter({
    required String shelterId,
    required String name,
    required String description,
    required int capacity,
    required String visibility,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.updateShelter(
        shelterId: shelterId,
        name: name,
        description: description,
        capacity: capacity,
        visibility: visibility,
        status: status,
      );
      await refreshAllData(silent: true);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> deleteShelter(String shelterId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.deleteShelter(shelterId);
      await refreshAllData(silent: true);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> createTrade({
    required String receiverId,
    required List<Map<String, dynamic>> offeredItems,
    required List<Map<String, dynamic>> requestedItems,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.createTrade(
        receiverId: receiverId,
        offeredItems: offeredItems,
        requestedItems: requestedItems,
      );
      await refreshAllData(silent: true);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> respondTrade({
    required String tradeId,
    required String action,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.respondTrade(tradeId: tradeId, action: action);
      await refreshAllData(silent: true);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> createHordeAlert({
    required double latitude,
    required double longitude,
    required String intensity,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repo.createHordeAlert(
        latitude: latitude,
        longitude: longitude,
        intensity: intensity,
        description: description,
      );
      await refreshAllData(silent: true);
      state = state.copyWith(isLoading: false, liveFlashAlert: created);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> confirmHordeAlert(String alertId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.confirmHordeAlert(alertId);
      await refreshAllData(silent: true);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String ext) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.uploadAvatar(bytes: bytes, fileExtension: ext);
      await refreshAllData(silent: true);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> sendRadioMessage(String text) async {
    final profile = state.profile;
    if (profile == null || text.trim().isEmpty) return;

    final msg = RadioMessageModel(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: profile.id,
      senderNickname: profile.nickname,
      factionId: profile.factionId ?? '',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      radioMessages: [msg, ...state.radioMessages],
    );

    if (_radioChannel != null && !_repo.isSimulationMode) {
      await _repo.sendFactionRadioMessage(
        channel: _radioChannel!,
        message: msg,
      );
    }
  }

  Future<void> checkInDailyRation() async {
    final newStreak = await _cache.registerDailyRationCheckIn();
    state = state.copyWith(
      survivalStreakDays: newStreak,
      checkedInToday: true,
    );
  }

  void dismissLiveFlashAlert() {
    state = state.copyWith(clearLiveFlashAlert: true);
  }

  Future<String> testCheatInventory() =>
      _repo.testAntiCheatDirectInventoryInsert();

  Future<String> testCheatReputation() =>
      _repo.testAntiCheatDirectReputationUpdate();

  @override
  void dispose() {
    _authSub?.cancel();
    _alertCleanupTimer?.cancel();
    _teardownChannels();
    super.dispose();
  }
}

final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>((ref) {
      final repo = ref.watch(protocoloZRepositoryProvider);
      final cache = ref.watch(localCacheServiceProvider);
      final routerRefresh = ref.watch(routerRefreshProvider);
      return GameController(repo, cache, routerRefresh);
    });
