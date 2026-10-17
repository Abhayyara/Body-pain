import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/records.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// On-device storage (SharedPreferences). Nothing is sent to any server.
class StorageService {
  StorageService(this._prefs);

  static Future<StorageService> create() async =>
      StorageService(await SharedPreferences.getInstance());

  static const String _prefix = 'bw_';
  static const String _kRecords = '${_prefix}records_v1';
  static const String _kPlan = '${_prefix}plan_v1';
  static const String _kCompletions = '${_prefix}completions_v1';
  static const String _kHydration = '${_prefix}hydration_v1';
  static const String _kPainLog = '${_prefix}painlog_v1';
  static const String _kPrefs = '${_prefix}prefs_v1';

  final SharedPreferences _prefs;

  // ---- helpers -----------------------------------------------------------
  Object? _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null; // corrupted entry: treat as empty rather than crash
    }
  }

  Future<void> _write(String key, Object value) =>
      _prefs.setString(key, jsonEncode(value));

  // ---- assessment records --------------------------------------------------
  List<AssessmentRecord> loadRecords() {
    final data = _read(_kRecords);
    if (data is! List) return <AssessmentRecord>[];
    final out = <AssessmentRecord>[];
    for (final item in data) {
      try {
        out.add(AssessmentRecord.fromJson(
            Map<String, Object?>.from(item as Map)));
      } catch (_) {
        // skip unreadable entries
      }
    }
    return out;
  }

  Future<void> addRecord(AssessmentRecord record) async {
    final all = loadRecords()..add(record);
    await _write(_kRecords, all.map((r) => r.toJson()).toList());
  }

  Future<void> deleteRecord(String id) async {
    final all = loadRecords()..removeWhere((r) => r.id == id);
    await _write(_kRecords, all.map((r) => r.toJson()).toList());
  }

  // ---- saved plan ---------------------------------------------------------
  SavedPlan? loadPlan() {
    final data = _read(_kPlan);
    if (data is! Map) return null;
    try {
      return SavedPlan.fromJson(Map<String, Object?>.from(data));
    } catch (_) {
      return null;
    }
  }

  Future<void> savePlan(SavedPlan plan) => _write(_kPlan, plan.toJson());

  Future<void> clearPlan() async {
    await _prefs.remove(_kPlan);
  }

  // ---- daily tracking -----------------------------------------------------
  /// date key -> completed exercise ids
  Map<String, Set<String>> loadCompletions() {
    final data = _read(_kCompletions);
    final out = <String, Set<String>>{};
    if (data is Map) {
      data.forEach((k, v) {
        if (v is List) out[k as String] = v.map((e) => e as String).toSet();
      });
    }
    return out;
  }

  Future<void> saveCompletions(Map<String, Set<String>> value) => _write(
        _kCompletions,
        value.map((k, v) => MapEntry<String, Object>(k, v.toList())),
      );

  /// date key -> glasses of water
  Map<String, int> loadHydration() {
    final data = _read(_kHydration);
    final out = <String, int>{};
    if (data is Map) {
      data.forEach((k, v) {
        if (v is int) out[k as String] = v;
      });
    }
    return out;
  }

  Future<void> saveHydration(Map<String, int> value) =>
      _write(_kHydration, value);

  // ---- pain log -----------------------------------------------------------
  List<PainLogEntry> loadPainLog() {
    final data = _read(_kPainLog);
    if (data is! List) return <PainLogEntry>[];
    final out = <PainLogEntry>[];
    for (final item in data) {
      try {
        out.add(PainLogEntry.fromJson(Map<String, Object?>.from(item as Map)));
      } catch (_) {}
    }
    return out;
  }

  Future<void> savePainLog(List<PainLogEntry> entries) =>
      _write(_kPainLog, entries.map((e) => e.toJson()).toList());

  // ---- preferences --------------------------------------------------------
  UserPreferences loadPreferences() {
    final data = _read(_kPrefs);
    if (data is! Map) return UserPreferences();
    try {
      return UserPreferences.fromJson(Map<String, Object?>.from(data));
    } catch (_) {
      return UserPreferences();
    }
  }

  Future<void> savePreferences(UserPreferences value) =>
      _write(_kPrefs, value.toJson());

  // ---- deletion -----------------------------------------------------------
  /// Removes every BodyWise key from this device.
  Future<void> deleteAllData() async {
    final keys =
        _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
