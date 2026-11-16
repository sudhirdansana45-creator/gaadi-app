import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleDraftService {
  VehicleDraftService._();
  static final VehicleDraftService instance = VehicleDraftService._();

  static const String _storageKey = 'gaadi_vehicle_drafts_v1';

  /// Fetches all saved vehicle drafts from local storage.
  Future<List<Map<String, dynamic>>> getDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[VehicleDraftService] Error loading drafts: $e');
      return [];
    }
  }

  /// Returns the current count of saved drafts.
  Future<int> getDraftsCount() async {
    final drafts = await getDrafts();
    return drafts.length;
  }

  /// Saves or updates a draft. If draftId already exists, it updates it.
  Future<void> saveDraft(Map<String, dynamic> draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final drafts = await getDrafts();

      final id = draft['id'] ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
      draft['id'] = id;
      draft['updated_at'] = DateTime.now().toIso8601String();

      final index = drafts.indexWhere((d) => d['id'] == id);
      if (index >= 0) {
        drafts[index] = draft;
      } else {
        drafts.insert(0, draft);
      }

      await prefs.setString(_storageKey, jsonEncode(drafts));
    } catch (e) {
      debugPrint('[VehicleDraftService] Error saving draft: $e');
    }
  }

  /// Deletes a specific draft by its ID.
  Future<void> deleteDraft(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final drafts = await getDrafts();
      drafts.removeWhere((d) => d['id'] == id);
      await prefs.setString(_storageKey, jsonEncode(drafts));
    } catch (e) {
      debugPrint('[VehicleDraftService] Error deleting draft: $e');
    }
  }

  /// Clears all stored drafts.
  Future<void> clearAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('[VehicleDraftService] Error clearing drafts: $e');
    }
  }
}
