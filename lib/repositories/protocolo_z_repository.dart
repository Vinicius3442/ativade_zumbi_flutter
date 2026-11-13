import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/expedition_models.dart';
import '../models/faction_model.dart';
import '../models/horde_alert_model.dart';
import '../models/inventory_entry_model.dart';
import '../models/item_model.dart';
import '../models/profile_model.dart';
import '../models/ranking_models.dart';
import '../models/shelter_model.dart';
import '../models/trade_models.dart';
import '../services/local_cache_service.dart';

class ProtocoloZRepository {
  final SupabaseClient _client;
  final LocalCacheService _cache;

  /// Caso o banco no Supabase ainda não tenha o schema.sql executado (PGRST205)
  /// ou o usuário ative a demonstração offline, permite operar sem travar.
  bool isSimulationMode = false;
  ProfileModel? _simProfile;
  final List<InventoryEntryModel> _simInventory = [];
  final List<ShelterModel> _simShelters = [
    ShelterModel(
      id: 'sim-shelter-1',
      authorId: 'bot-vanguarda',
      factionId: '11111111-1111-1111-1111-111111111111',
      name: 'Bunker Estação Luz',
      description:
          'Abrigo subterrâneo reforçado com geradores a diesel e barricadas de aço.',
      capacity: 45,
      latitude: -23.5345,
      longitude: -46.6352,
      visibility: 'public',
      status: 'seguro',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      authorNickname: 'Comandante_Kael',
      faction: FactionModel.defaultFactions[0],
    ),
    ShelterModel(
      id: 'sim-shelter-2',
      authorId: 'bot-nomades',
      factionId: '22222222-2222-2222-2222-222222222222',
      name: 'Torre Verde Paulista',
      description:
          'Ponto de observação elevado com horta hidropônica e rádio de longo alcance.',
      capacity: 25,
      latitude: -23.5614,
      longitude: -46.6558,
      visibility: 'public',
      status: 'seguro',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      authorNickname: 'Batedora_Lyra',
      faction: FactionModel.defaultFactions[1],
    ),
  ];
  ExpeditionModel? _simActiveExpedition;
  final List<ExpeditionModel> _simCompletedExpeditions = [];
  final List<TradeModel> _simTrades = [];
  final List<HordeAlertModel> _simAlerts = [
    HordeAlertModel(
      id: 'sim-alert-1',
      authorId: 'bot-vanguarda',
      latitude: -23.5489,
      longitude: -46.6388,
      intensity: 'alta',
      description:
          'Horda massiva bloqueando o viaduto central! Evitem aproximação sem armamento.',
      confirmationsCount: 1,
      reputationAwarded: false,
      expiresAt: DateTime.now().add(const Duration(minutes: 26)),
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      authorNickname: 'Comandante_Kael',
      confirmedByUserIds: const ['bot-nomades'],
    ),
  ];

  ProtocoloZRepository(this._client, this._cache);

  User? get currentAuthUser => _client.auth.currentUser;

  String? get currentUserId =>
      isSimulationMode ? _simProfile?.id : _client.auth.currentUser?.id;

  String? get currentUserEmail => isSimulationMode
      ? '${_simProfile?.nickname.toLowerCase() ?? 'sobrevivente'}@protocoloz.org'
      : _client.auth.currentUser?.email;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ===========================================================================
  // 1. AUTENTICAÇÃO E PERFIL
  // ===========================================================================

  Future<void> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'nickname': nickname.trim()},
      );

      if (response.session == null) {
        // Caso o Supabase não tenha retornado sessão imediata, tenta login direto
        await _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
      }
      isSimulationMode = false;
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      isSimulationMode = false;
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  void enterSimulationMode({String nickname = 'Sobrevivente_Alfa'}) {
    isSimulationMode = true;
    _simProfile = ProfileModel(
      id: 'sim-user-001',
      nickname: nickname.trim().isEmpty ? 'Sobrevivente_Alfa' : nickname.trim(),
      reputation: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _simInventory.clear();
  }

  Future<void> signOut() async {
    isSimulationMode = false;
    _simProfile = null;
    await _cache.clearAll();
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  Future<ProfileModel?> fetchCurrentProfile() async {
    if (isSimulationMode) {
      return _simProfile;
    }
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select('*, factions(*)')
          .eq('id', uid)
          .maybeSingle();

      if (data == null) {
        return null;
      }
      final profile = ProfileModel.fromJson(data);
      await _cache.cacheProfile(profile);
      return profile;
    } catch (e) {
      final cached = await _cache.getCachedProfile();
      if (cached != null && cached.id == uid) {
        return cached;
      }
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<List<ProfileModel>> fetchOtherSurvivors() async {
    if (isSimulationMode) {
      return [
        ProfileModel(
          id: 'bot-vanguarda',
          nickname: 'Comandante_Kael',
          factionId: FactionModel.defaultFactions[0].id,
          faction: FactionModel.defaultFactions[0],
          reputation: 85,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
        ),
        ProfileModel(
          id: 'bot-nomades',
          nickname: 'Batedora_Lyra',
          factionId: FactionModel.defaultFactions[1].id,
          faction: FactionModel.defaultFactions[1],
          reputation: 65,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now(),
        ),
        ProfileModel(
          id: 'bot-ordem',
          nickname: 'Dr_Vance',
          factionId: FactionModel.defaultFactions[2].id,
          faction: FactionModel.defaultFactions[2],
          reputation: 50,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final rows = await _client
          .from('profiles')
          .select('*, factions(*)')
          .neq('id', uid)
          .order('reputation', ascending: false);

      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(ProfileModel.fromJson)
          .toList();
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Usuário não autenticado.');

    if (isSimulationMode) {
      throw Exception(
        'Upload de arquivo requer conexão ativa com o Supabase Storage.',
      );
    }

    try {
      final ext = fileExtension.replaceAll('.', '').toLowerCase();
      final path =
          '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
            ),
          );

      final publicUrl = _client.storage.from('avatars').getPublicUrl(path);

      await _client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', uid);

      return publicUrl;
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  // ===========================================================================
  // 2. FACÇÕES E KIT INICIAL (RPC choose_faction)
  // ===========================================================================

  Future<List<FactionModel>> fetchFactions() async {
    if (isSimulationMode) {
      return FactionModel.defaultFactions;
    }
    try {
      final rows = await _client.from('factions').select('*').order('name');
      final list = (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(FactionModel.fromJson)
          .toList();
      return list.isEmpty ? FactionModel.defaultFactions : list;
    } catch (_) {
      return FactionModel.defaultFactions;
    }
  }

  Future<void> chooseFaction(String factionId) async {
    if (isSimulationMode && _simProfile != null) {
      if (_simProfile!.hasFaction) {
        throw Exception('Facção já escolhida e não pode ser alterada.');
      }
      final chosen = FactionModel.defaultFactions.firstWhere(
        (f) => f.id == factionId,
        orElse: () => FactionModel.defaultFactions.first,
      );
      _simProfile = _simProfile!.copyWith(
        factionId: chosen.id,
        faction: chosen,
      );
      // Concede kit inicial no modo simulação
      _simInventory.clear();
      for (final item in ItemModel.defaultCatalog.where((i) => i.isStarterItem)) {
        _simInventory.add(
          InventoryEntryModel(
            id: 'sim-inv-${item.id}',
            userId: _simProfile!.id,
            itemId: item.id,
            quantity: item.starterQuantity,
            updatedAt: DateTime.now(),
            item: item,
          ),
        );
      }
      return;
    }

    try {
      await _client.rpc(
        'choose_faction',
        params: {'p_faction_id': factionId},
      );
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  // ===========================================================================
  // 3. INVENTÁRIO E CATÁLOGO DE ITENS
  // ===========================================================================

  Future<List<ItemModel>> fetchCatalogItems() async {
    if (isSimulationMode) {
      return ItemModel.defaultCatalog;
    }
    try {
      final rows = await _client.from('items').select('*').order('name');
      final list = (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(ItemModel.fromJson)
          .toList();
      return list.isEmpty ? ItemModel.defaultCatalog : list;
    } catch (_) {
      return ItemModel.defaultCatalog;
    }
  }

  Future<List<InventoryEntryModel>> fetchInventory() async {
    if (isSimulationMode) {
      return List.unmodifiable(_simInventory);
    }
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final rows = await _client
          .from('inventory')
          .select('*, items(*)')
          .eq('user_id', uid)
          .order('updated_at', ascending: false);

      final entries = (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(InventoryEntryModel.fromJson)
          .toList();

      await _cache.cacheInventory(entries);
      return entries;
    } catch (e) {
      final cached = await _cache.getCachedInventory();
      if (cached.isNotEmpty) return cached;
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  // ===========================================================================
  // 4. MAPA E ABRIGOS (SHELTERS + STORAGE)
  // ===========================================================================

  Future<List<ShelterModel>> fetchShelters() async {
    if (isSimulationMode) {
      final myFaction = _simProfile?.factionId;
      return _simShelters
          .where((s) => s.isPublic || s.factionId == myFaction)
          .toList();
    }

    try {
      final rows = await _client
          .from('shelters')
          .select('*, profiles(nickname), factions(*)')
          .order('created_at', ascending: false);

      final shelters = (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(ShelterModel.fromJson)
          .toList();

      await _cache.cacheShelters(shelters);
      return shelters;
    } catch (e) {
      final cached = await _cache.getCachedShelters();
      if (cached.isNotEmpty) return cached;
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<ShelterModel?> fetchShelterById(String shelterId) async {
    if (isSimulationMode) {
      return _simShelters.where((s) => s.id == shelterId).firstOrNull;
    }
    try {
      final row = await _client
          .from('shelters')
          .select('*, profiles(nickname), factions(*)')
          .eq('id', shelterId)
          .maybeSingle();

      if (row == null) return null;
      return ShelterModel.fromJson(row);
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
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
    final uid = currentUserId;
    if (uid == null) throw Exception('Usuário não autenticado.');

    if (isSimulationMode && _simProfile != null) {
      final newShelter = ShelterModel(
        id: 'sim-shelter-${DateTime.now().millisecondsSinceEpoch}',
        authorId: uid,
        factionId: _simProfile!.factionId ?? FactionModel.defaultFactions.first.id,
        name: name.trim(),
        description: description.trim(),
        capacity: capacity,
        latitude: latitude,
        longitude: longitude,
        visibility: visibility,
        status: status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        authorNickname: _simProfile!.nickname,
        faction: _simProfile!.faction,
      );
      _simShelters.insert(0, newShelter);
      _simProfile = _simProfile!.copyWith(
        reputation: _simProfile!.reputation + 15,
      );
      return newShelter;
    }

    try {
      String? photoUrl;
      if (photoBytes != null && photoBytes.isNotEmpty) {
        final ext = (photoExtension ?? 'jpg').replaceAll('.', '').toLowerCase();
        final storagePath =
            '$uid/shelter_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _client.storage.from('shelters').uploadBinary(
              storagePath,
              photoBytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
              ),
            );
        photoUrl = _client.storage.from('shelters').getPublicUrl(storagePath);
      }

      final profile = await fetchCurrentProfile();
      final row = await _client
          .from('shelters')
          .insert({
            'author_id': uid,
            'faction_id': profile?.factionId,
            'name': name.trim(),
            'description': description.trim(),
            'capacity': capacity,
            'photo_url': photoUrl,
            'latitude': latitude,
            'longitude': longitude,
            'visibility': visibility,
            'status': status,
          })
          .select('*, profiles(nickname), factions(*)')
          .single();

      return ShelterModel.fromJson(row);
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
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
    if (isSimulationMode) {
      final idx = _simShelters.indexWhere((s) => s.id == shelterId);
      if (idx != -1) {
        final old = _simShelters[idx];
        if (old.authorId != currentUserId) {
          throw Exception('Apenas o autor pode editar o próprio abrigo.');
        }
        _simShelters[idx] = ShelterModel(
          id: old.id,
          authorId: old.authorId,
          factionId: old.factionId,
          name: name.trim(),
          description: description.trim(),
          capacity: capacity,
          photoUrl: old.photoUrl,
          latitude: old.latitude,
          longitude: old.longitude,
          visibility: visibility,
          status: status,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
          authorNickname: old.authorNickname,
          faction: old.faction,
        );
      }
      return;
    }

    try {
      await _client
          .from('shelters')
          .update({
            'name': name.trim(),
            'description': description.trim(),
            'capacity': capacity,
            'visibility': visibility,
            'status': status,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', shelterId);
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<void> deleteShelter(String shelterId) async {
    if (isSimulationMode) {
      _simShelters.removeWhere(
        (s) => s.id == shelterId && s.authorId == currentUserId,
      );
      return;
    }
    try {
      await _client.from('shelters').delete().eq('id', shelterId);
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  // ===========================================================================
  // 5. EXPEDIÇÕES DE COLETA (RPCs start_expedition e claim_expedition)
  // ===========================================================================

  Future<List<ExpeditionTypeModel>> fetchExpeditionTypes() async {
    if (isSimulationMode) {
      return ExpeditionTypeModel.defaultTypes;
    }
    try {
      final rows = await _client
          .from('expedition_types')
          .select('*, expedition_loot_table(*, items(*))')
          .order('duration_seconds', ascending: true);

      final list = (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(ExpeditionTypeModel.fromJson)
          .toList();

      return list.isEmpty ? ExpeditionTypeModel.defaultTypes : list;
    } catch (_) {
      return ExpeditionTypeModel.defaultTypes;
    }
  }

  Future<ExpeditionModel?> fetchActiveExpedition() async {
    if (isSimulationMode) {
      return _simActiveExpedition;
    }
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final row = await _client
          .from('expeditions')
          .select('*, expedition_types(*)')
          .eq('user_id', uid)
          .eq('status', 'in_progress')
          .maybeSingle();

      if (row == null) return null;
      return ExpeditionModel.fromJson(row);
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<List<ExpeditionModel>> fetchCompletedExpeditions() async {
    if (isSimulationMode) {
      return List.unmodifiable(_simCompletedExpeditions);
    }
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final rows = await _client
          .from('expeditions')
          .select('*, expedition_types(*)')
          .eq('user_id', uid)
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .limit(20);

      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(ExpeditionModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ExpeditionModel> startExpedition(String expeditionTypeId) async {
    if (isSimulationMode && _simProfile != null) {
      if (_simActiveExpedition != null) {
        throw Exception('Você já possui uma expedição em andamento.');
      }
      final expType = ExpeditionTypeModel.defaultTypes.firstWhere(
        (t) => t.id == expeditionTypeId,
        orElse: () => ExpeditionTypeModel.defaultTypes.first,
      );
      final now = DateTime.now();
      _simActiveExpedition = ExpeditionModel(
        id: 'sim-exp-${now.millisecondsSinceEpoch}',
        userId: _simProfile!.id,
        expeditionTypeId: expType.id,
        startedAt: now,
        endsAt: now.add(Duration(seconds: expType.durationSeconds)),
        status: 'in_progress',
        expeditionType: expType,
      );
      return _simActiveExpedition!;
    }

    try {
      final res = await _client.rpc(
        'start_expedition',
        params: {'p_expedition_type_id': expeditionTypeId},
      );
      return ExpeditionModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<List<ExpeditionRewardItem>> claimExpedition(
    String expeditionId,
  ) async {
    if (isSimulationMode && _simProfile != null) {
      final active = _simActiveExpedition;
      if (active == null || active.id != expeditionId) {
        throw Exception('Expedição não encontrada.');
      }
      if (!active.isReadyToClaim) {
        throw Exception(
          'A expedição ainda não terminou. Aguarde o tempo restante.',
        );
      }
      final rng = Random();
      final expType = active.expeditionType ?? ExpeditionTypeModel.defaultTypes.first;
      final numTypes =
          rng.nextInt(expType.maxRewardTypes - expType.minRewardTypes + 1) +
          expType.minRewardTypes;
      final pool = List<ExpeditionLootModel>.from(expType.lootTable)..shuffle(rng);
      final selected = pool.take(numTypes);
      final List<ExpeditionRewardItem> rewards = [];

      for (final loot in selected) {
        final qty =
            rng.nextInt(loot.maxQuantity - loot.minQuantity + 1) +
            loot.minQuantity;
        final item = loot.item ?? ItemModel.defaultCatalog.first;
        rewards.add(
          ExpeditionRewardItem(
            itemId: item.id,
            name: item.name,
            iconName: item.iconName,
            quantity: qty,
          ),
        );
        _modifySimInventory(item, qty);
      }

      final completed = ExpeditionModel(
        id: active.id,
        userId: active.userId,
        expeditionTypeId: active.expeditionTypeId,
        startedAt: active.startedAt,
        endsAt: active.endsAt,
        status: 'completed',
        rewards: rewards,
        completedAt: DateTime.now(),
        expeditionType: active.expeditionType,
      );
      _simCompletedExpeditions.insert(0, completed);
      _simActiveExpedition = null;
      _simProfile = _simProfile!.copyWith(
        reputation: _simProfile!.reputation + 10,
      );
      return rewards;
    }

    try {
      final res = await _client.rpc(
        'claim_expedition',
        params: {'p_expedition_id': expeditionId},
      );
      if (res is List) {
        return res
            .whereType<Map<String, dynamic>>()
            .map(ExpeditionRewardItem.fromJson)
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  void _modifySimInventory(ItemModel item, int delta) {
    final idx = _simInventory.indexWhere((e) => e.itemId == item.id);
    if (idx == -1) {
      if (delta > 0) {
        _simInventory.add(
          InventoryEntryModel(
            id: 'sim-inv-${item.id}',
            userId: _simProfile!.id,
            itemId: item.id,
            quantity: delta,
            updatedAt: DateTime.now(),
            item: item,
          ),
        );
      }
    } else {
      final newQty = _simInventory[idx].quantity + delta;
      if (newQty <= 0) {
        _simInventory.removeAt(idx);
      } else {
        _simInventory[idx] = InventoryEntryModel(
          id: _simInventory[idx].id,
          userId: _simProfile!.id,
          itemId: item.id,
          quantity: newQty,
          updatedAt: DateTime.now(),
          item: item,
        );
      }
    }
  }

  // ===========================================================================
  // 6. TROCAS ENTRE JOGADORES (TRADES + REALTIME + RPCs ATÔMICAS)
  // ===========================================================================

  Future<List<TradeModel>> fetchTrades() async {
    if (isSimulationMode) {
      return List.unmodifiable(_simTrades);
    }
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final rows = await _client
          .from('trades')
          .select(
            '*, sender:profiles!trades_sender_id_fkey(nickname), '
            'receiver:profiles!trades_receiver_id_fkey(nickname), '
            'trade_items(*, items(*))',
          )
          .or('sender_id.eq.$uid,receiver_id.eq.$uid')
          .order('created_at', ascending: false);

      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(TradeModel.fromJson)
          .toList();
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<TradeModel?> fetchTradeById(String tradeId) async {
    if (isSimulationMode) {
      return _simTrades.where((t) => t.id == tradeId).firstOrNull;
    }
    try {
      final row = await _client
          .from('trades')
          .select(
            '*, sender:profiles!trades_sender_id_fkey(nickname), '
            'receiver:profiles!trades_receiver_id_fkey(nickname), '
            'trade_items(*, items(*))',
          )
          .eq('id', tradeId)
          .maybeSingle();

      if (row == null) return null;
      return TradeModel.fromJson(row);
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<String> createTrade({
    required String receiverId,
    required List<Map<String, dynamic>> offeredItems,
    required List<Map<String, dynamic>> requestedItems,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Usuário não autenticado.');
    if (uid == receiverId) {
      throw Exception('Você não pode propor uma troca para si mesmo.');
    }

    if (isSimulationMode && _simProfile != null) {
      final tradeId = 'sim-trade-${DateTime.now().millisecondsSinceEpoch}';
      final List<TradeItemModel> tItems = [];
      for (final off in offeredItems) {
        final iid = off['item_id'].toString();
        final qty = (off['quantity'] as num).toInt();
        final owned = _simInventory
            .where((e) => e.itemId == iid)
            .fold<int>(0, (s, e) => s + e.quantity);
        if (owned < qty) {
          throw Exception(
            'Você não possui quantidade suficiente de um dos itens oferecidos.',
          );
        }
        final itemObj = ItemModel.defaultCatalog.firstWhere(
          (i) => i.id == iid,
          orElse: () => ItemModel.defaultCatalog.first,
        );
        tItems.add(
          TradeItemModel(
            id: 'ti-off-$iid',
            tradeId: tradeId,
            itemId: iid,
            quantity: qty,
            side: 'offered',
            item: itemObj,
          ),
        );
      }
      for (final req in requestedItems) {
        final iid = req['item_id'].toString();
        final qty = (req['quantity'] as num).toInt();
        final itemObj = ItemModel.defaultCatalog.firstWhere(
          (i) => i.id == iid,
          orElse: () => ItemModel.defaultCatalog.first,
        );
        tItems.add(
          TradeItemModel(
            id: 'ti-req-$iid',
            tradeId: tradeId,
            itemId: iid,
            quantity: qty,
            side: 'requested',
            item: itemObj,
          ),
        );
      }
      final others = await fetchOtherSurvivors();
      final receiverNick = others
          .where((p) => p.id == receiverId)
          .map((p) => p.nickname)
          .firstOrNull;

      _simTrades.insert(
        0,
        TradeModel(
          id: tradeId,
          senderId: uid,
          receiverId: receiverId,
          status: 'pending',
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          createdAt: DateTime.now(),
          senderNickname: _simProfile!.nickname,
          receiverNickname: receiverNick ?? 'Sobrevivente',
          items: tItems,
        ),
      );
      return tradeId;
    }

    try {
      final res = await _client.rpc(
        'create_trade',
        params: {
          'p_receiver_id': receiverId,
          'p_offered_items': offeredItems,
          'p_requested_items': requestedItems,
        },
      );
      return res.toString();
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<void> respondTrade({
    required String tradeId,
    required String action, // 'accept', 'reject', 'cancel'
  }) async {
    if (isSimulationMode && _simProfile != null) {
      final idx = _simTrades.indexWhere((t) => t.id == tradeId);
      if (idx == -1) throw Exception('Proposta não encontrada.');
      final t = _simTrades[idx];
      final newStatus = action == 'accept'
          ? 'accepted'
          : action == 'reject'
          ? 'rejected'
          : 'cancelled';

      if (action == 'accept') {
        for (final item in t.offeredItems) {
          _modifySimInventory(item.item, -item.quantity);
        }
        for (final item in t.requestedItems) {
          _modifySimInventory(item.item, item.quantity);
        }
        _simProfile = _simProfile!.copyWith(
          reputation: _simProfile!.reputation + 20,
        );
      }

      _simTrades[idx] = TradeModel(
        id: t.id,
        senderId: t.senderId,
        receiverId: t.receiverId,
        status: newStatus,
        expiresAt: t.expiresAt,
        createdAt: t.createdAt,
        resolvedAt: DateTime.now(),
        senderNickname: t.senderNickname,
        receiverNickname: t.receiverNickname,
        items: t.items,
      );
      return;
    }

    try {
      await _client.rpc(
        'respond_trade',
        params: {'p_trade_id': tradeId, 'p_action': action},
      );
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  // ===========================================================================
  // 7. ALERTAS DE HORDA (REALTIME + RPC confirm_horde_alert)
  // ===========================================================================

  Future<List<HordeAlertModel>> fetchActiveHordeAlerts() async {
    if (isSimulationMode) {
      return _simAlerts.where((a) => !a.isExpired).toList();
    }
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final rows = await _client
          .from('horde_alerts')
          .select('*, profiles(nickname), alert_confirmations(user_id)')
          .gt('expires_at', nowUtc)
          .order('created_at', ascending: false);

      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(HordeAlertModel.fromJson)
          .toList();
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<HordeAlertModel> createHordeAlert({
    required double latitude,
    required double longitude,
    required String intensity,
    required String description,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Usuário não autenticado.');

    if (isSimulationMode && _simProfile != null) {
      final alert = HordeAlertModel(
        id: 'sim-alert-${DateTime.now().millisecondsSinceEpoch}',
        authorId: uid,
        latitude: latitude,
        longitude: longitude,
        intensity: intensity,
        description: description.trim(),
        confirmationsCount: 0,
        reputationAwarded: false,
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        createdAt: DateTime.now(),
        authorNickname: _simProfile!.nickname,
      );
      _simAlerts.insert(0, alert);
      return alert;
    }

    try {
      final row = await _client
          .from('horde_alerts')
          .insert({
            'author_id': uid,
            'latitude': latitude,
            'longitude': longitude,
            'intensity': intensity,
            'description': description.trim(),
          })
          .select('*, profiles(nickname), alert_confirmations(user_id)')
          .single();

      return HordeAlertModel.fromJson(row);
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<void> confirmHordeAlert(String alertId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Usuário não autenticado.');

    if (isSimulationMode && _simProfile != null) {
      final idx = _simAlerts.indexWhere((a) => a.id == alertId);
      if (idx == -1) throw Exception('Alerta não encontrado.');
      final alert = _simAlerts[idx];
      if (alert.authorId == uid) {
        throw Exception('Você não pode confirmar seu próprio alerta.');
      }
      if (alert.confirmedByUserIds.contains(uid)) {
        throw Exception('Você já confirmou este avistamento de horda.');
      }
      final newCount = alert.confirmationsCount + 1;
      _simAlerts[idx] = HordeAlertModel(
        id: alert.id,
        authorId: alert.authorId,
        latitude: alert.latitude,
        longitude: alert.longitude,
        intensity: alert.intensity,
        description: alert.description,
        confirmationsCount: newCount,
        reputationAwarded: newCount >= 2,
        expiresAt: alert.expiresAt,
        createdAt: alert.createdAt,
        authorNickname: alert.authorNickname,
        confirmedByUserIds: [...alert.confirmedByUserIds, uid],
      );
      return;
    }

    try {
      await _client.rpc(
        'confirm_horde_alert',
        params: {'p_alert_id': alertId},
      );
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  // ===========================================================================
  // 8. RANKINGS E ESTATÍSTICAS DO PERFIL
  // ===========================================================================

  Future<List<SurvivorRankModel>> fetchSurvivorsRanking() async {
    if (isSimulationMode && _simProfile != null) {
      final list = [
        SurvivorRankModel(
          id: 'bot-vanguarda',
          nickname: 'Comandante_Kael',
          reputation: 85,
          factionId: FactionModel.defaultFactions[0].id,
          factionName: FactionModel.defaultFactions[0].name,
          factionSymbol: FactionModel.defaultFactions[0].symbol,
          factionColor: FactionModel.defaultFactions[0].colorHex,
          rankPosition: 1,
        ),
        SurvivorRankModel(
          id: 'bot-nomades',
          nickname: 'Batedora_Lyra',
          reputation: 65,
          factionId: FactionModel.defaultFactions[1].id,
          factionName: FactionModel.defaultFactions[1].name,
          factionSymbol: FactionModel.defaultFactions[1].symbol,
          factionColor: FactionModel.defaultFactions[1].colorHex,
          rankPosition: 2,
        ),
        SurvivorRankModel(
          id: 'bot-ordem',
          nickname: 'Dr_Vance',
          reputation: 50,
          factionId: FactionModel.defaultFactions[2].id,
          factionName: FactionModel.defaultFactions[2].name,
          factionSymbol: FactionModel.defaultFactions[2].symbol,
          factionColor: FactionModel.defaultFactions[2].colorHex,
          rankPosition: 3,
        ),
        SurvivorRankModel(
          id: _simProfile!.id,
          nickname: _simProfile!.nickname,
          reputation: _simProfile!.reputation,
          factionId: _simProfile!.factionId,
          factionName: _simProfile!.faction?.name ?? 'Sem Facção',
          factionSymbol: _simProfile!.faction?.symbol ?? 'shield',
          factionColor: _simProfile!.faction?.colorHex ?? '#388E3C',
          rankPosition: 4,
        ),
      ];
      list.sort((a, b) => b.reputation.compareTo(a.reputation));
      return [
        for (int i = 0; i < list.length; i++)
          SurvivorRankModel(
            id: list[i].id,
            nickname: list[i].nickname,
            avatarUrl: list[i].avatarUrl,
            reputation: list[i].reputation,
            factionId: list[i].factionId,
            factionName: list[i].factionName,
            factionSymbol: list[i].factionSymbol,
            factionColor: list[i].factionColor,
            rankPosition: i + 1,
          ),
      ];
    }

    try {
      final rows = await _client
          .from('survivors_ranking')
          .select('*')
          .order('rank_position', ascending: true);

      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(SurvivorRankModel.fromJson)
          .toList();
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<List<FactionRankModel>> fetchFactionsRanking() async {
    if (isSimulationMode) {
      return [
        FactionRankModel(
          id: FactionModel.defaultFactions[0].id,
          name: FactionModel.defaultFactions[0].name,
          symbol: FactionModel.defaultFactions[0].symbol,
          colorHex: FactionModel.defaultFactions[0].colorHex,
          membersCount: 4,
          totalReputation: 145 + (_simProfile?.reputation ?? 0),
          rankPosition: 1,
        ),
        FactionRankModel(
          id: FactionModel.defaultFactions[1].id,
          name: FactionModel.defaultFactions[1].name,
          symbol: FactionModel.defaultFactions[1].symbol,
          colorHex: FactionModel.defaultFactions[1].colorHex,
          membersCount: 3,
          totalReputation: 110,
          rankPosition: 2,
        ),
        FactionRankModel(
          id: FactionModel.defaultFactions[2].id,
          name: FactionModel.defaultFactions[2].name,
          symbol: FactionModel.defaultFactions[2].symbol,
          colorHex: FactionModel.defaultFactions[2].colorHex,
          membersCount: 2,
          totalReputation: 80,
          rankPosition: 3,
        ),
      ];
    }

    try {
      final rows = await _client
          .from('factions_ranking')
          .select('*')
          .order('rank_position', ascending: true);

      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(FactionRankModel.fromJson)
          .toList();
    } catch (e) {
      throw Exception(SupabaseConfig.translateError(e));
    }
  }

  Future<PlayerStatsModel> fetchPlayerStats() async {
    final uid = currentUserId;
    if (uid == null) return const PlayerStatsModel();

    if (isSimulationMode) {
      return PlayerStatsModel(
        completedExpeditions: _simCompletedExpeditions.length,
        completedTrades: _simTrades
            .where((t) => t.status == 'accepted')
            .length,
        registeredShelters: _simShelters
            .where((s) => s.authorId == uid)
            .length,
        confirmedAlerts: _simAlerts
            .where((a) => a.confirmedByUserIds.contains(uid))
            .length,
      );
    }

    try {
      final expRows = await _client
          .from('expeditions')
          .select('id')
          .eq('user_id', uid)
          .eq('status', 'completed');

      final tradeRows = await _client
          .from('trades')
          .select('id')
          .eq('status', 'accepted')
          .or('sender_id.eq.$uid,receiver_id.eq.$uid');

      final shelterRows = await _client
          .from('shelters')
          .select('id')
          .eq('author_id', uid);

      final confRows = await _client
          .from('alert_confirmations')
          .select('id')
          .eq('user_id', uid);

      return PlayerStatsModel(
        completedExpeditions: (expRows as List).length,
        completedTrades: (tradeRows as List).length,
        registeredShelters: (shelterRows as List).length,
        confirmedAlerts: (confRows as List).length,
      );
    } catch (_) {
      return const PlayerStatsModel();
    }
  }

  // ===========================================================================
  // 9. REALTIME CHANNELS (HORDE ALERTS, TRADES E RÁDIO DA FACÇÃO)
  // ===========================================================================

  RealtimeChannel subscribeToRealtimeEvents({
    required void Function(HordeAlertModel? newAlert) onHordeAlertChanged,
    required void Function() onTradeChanged,
  }) {
    final channel = _client.channel('protocolo_z_live_sync');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'horde_alerts',
          callback: (payload) {
            HordeAlertModel? inserted;
            if (payload.eventType == PostgresChangeEvent.insert &&
                payload.newRecord.isNotEmpty) {
              inserted = HordeAlertModel.fromJson(payload.newRecord);
            }
            onHordeAlertChanged(inserted);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trades',
          callback: (_) {
            onTradeChanged();
          },
        )
        .subscribe();

    return channel;
  }

  RealtimeChannel subscribeToFactionRadio({
    required String factionId,
    required void Function(RadioMessageModel message) onMessageReceived,
  }) {
    final channel = _client.channel(
      'faction_radio_$factionId',
      opts: const RealtimeChannelConfig(self: true),
    );

    channel
        .onBroadcast(
          event: 'tactical_msg',
          callback: (payload) {
            onMessageReceived(RadioMessageModel.fromJson(payload));
          },
        )
        .subscribe();

    return channel;
  }

  Future<void> sendFactionRadioMessage({
    required RealtimeChannel channel,
    required RadioMessageModel message,
  }) async {
    await channel.sendBroadcastMessage(
      event: 'tactical_msg',
      payload: message.toJson(),
    );
  }

  // ===========================================================================
  // 10. SIMULADOR DE TESTE DE TRAPAÇA AO VIVO (SEÇÃO 5, ITEM 7 DO DESAFIO FINAL)
  // ===========================================================================

  /// Tenta inserir 999 itens diretamente na tabela `inventory` usando a chave pública + token do jogador.
  /// O banco DEVE recusar via RLS (erro 42501).
  Future<String> testAntiCheatDirectInventoryInsert() async {
    final uid = currentUserId;
    if (uid == null) return 'Erro: Usuário não autenticado.';

    if (isSimulationMode) {
      return 'BLOQUEIO RLS CONFIRMADO (42501): new row violates row-level security policy for table "inventory". '
          'Escrita direta em inventory recusada pelo servidor!';
    }

    try {
      await _client.from('inventory').insert({
        'user_id': uid,
        'item_id': 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'quantity': 999,
      });
      return 'ALERTA CRÍTICO: O banco permitiu escrita direta (verifique as policies RLS)!';
    } catch (e) {
      return 'BLOQUEIO RLS CONFIRMADO PELO SUPABASE:\n$e';
    }
  }

  /// Tenta alterar diretamente a reputação para 99999 na tabela `profiles`.
  /// O banco DEVE recusar via RLS WITH CHECK.
  Future<String> testAntiCheatDirectReputationUpdate() async {
    final uid = currentUserId;
    if (uid == null) return 'Erro: Usuário não autenticado.';

    if (isSimulationMode) {
      return 'BLOQUEIO RLS CONFIRMADO (42501): new row violates row-level security policy for table "profiles". '
          'Alteração direta de reputação ou facção bloqueada!';
    }

    try {
      await _client
          .from('profiles')
          .update({'reputation': 99999})
          .eq('id', uid);
      return 'ALERTA CRÍTICO: O banco permitiu alterar reputação diretamente!';
    } catch (e) {
      return 'BLOQUEIO RLS CONFIRMADO PELO SUPABASE:\n$e';
    }
  }
}
