import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _keyWorkers = 'cached_active_workers';
  static const _keyLastSync = 'cache_last_sync';

  // ─── Save workers to local cache ─────────────────────────────────────────

  Future<void> cacheActiveWorkers(
      List<Map<String, dynamic>> workers) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(workers);
    await prefs.setString(_keyWorkers, encoded);
    await prefs.setString(
        _keyLastSync, DateTime.now().toIso8601String());
  }

  // ─── Read workers from local cache ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCachedWorkers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyWorkers);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ─── Last sync timestamp ─────────────────────────────────────────────────

  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastSync);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<String> getLastSyncLabel() async {
    final lastSync = await getLastSync();
    if (lastSync == null) return 'Never synced';
    final diff = DateTime.now().difference(lastSync);
    if (diff.inMinutes < 1) return 'Synced just now';
    if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
    return 'Synced ${diff.inHours}h ago';
  }

  // ─── Worker lookup from cache (for offline QR/manual scan) ───────────────

  Future<Map<String, dynamic>?> findWorkerByCardNumber(
      String cardNumber) async {
    final workers = await getCachedWorkers();
    try {
      return workers.firstWhere(
          (w) => w['card_number'] == cardNumber);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> findWorkerByQr(String qrValue) async {
    final workers = await getCachedWorkers();
    try {
      return workers.firstWhere(
          (w) => w['qr_code_value'] == qrValue);
    } catch (_) {
      return null;
    }
  }

  // ─── Clear cache ─────────────────────────────────────────────────────────

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWorkers);
    await prefs.remove(_keyLastSync);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

