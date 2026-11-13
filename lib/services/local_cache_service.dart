import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_entry_model.dart';
import '../models/profile_model.dart';
import '../models/shelter_model.dart';

class LocalCacheService {
  static const String _keyInventory = 'pz_cache_inventory';
  static const String _keyShelters = 'pz_cache_shelters';
  static const String _keyProfile = 'pz_cache_profile';
  static const String _keySurvivalStreak = 'pz_survival_streak_days';
  static const String _keyLastRationDate = 'pz_last_ration_date';

  Future<void> cacheProfile(ProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  Future<ProfileModel?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfile);
    if (raw == null) return null;
    try {
      return ProfileModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheInventory(List<InventoryEntryModel> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final list = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_keyInventory, jsonEncode(list));
  }

  Future<List<InventoryEntryModel>> getCachedInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyInventory);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(InventoryEntryModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheShelters(List<ShelterModel> shelters) async {
    final prefs = await SharedPreferences.getInstance();
    final list = shelters.map((e) => e.toJson()).toList();
    await prefs.setString(_keyShelters, jsonEncode(list));
  }

  Future<List<ShelterModel>> getCachedShelters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyShelters);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ShelterModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Diferencial Criativo (Seção 4): Consumo Diário / Sequência de Dias Sobrevividos
  Future<({int streakDays, bool checkedInToday})> getDailySurvivalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_keySurvivalStreak) ?? 1;
    final lastDate = prefs.getString(_keyLastRationDate);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return (streakDays: streak, checkedInToday: lastDate == today);
  }

  Future<int> registerDailyRationCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_keyLastRationDate);
    int streak = prefs.getInt(_keySurvivalStreak) ?? 0;
    if (lastDate != today) {
      streak += 1;
      await prefs.setInt(_keySurvivalStreak, streak);
      await prefs.setString(_keyLastRationDate, today);
    }
    return streak;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfile);
    await prefs.remove(_keyInventory);
    await prefs.remove(_keyShelters);
  }
}
