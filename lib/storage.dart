import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class Storage {
  static const _kBudget = 'mm_budget_v2';
  static const _kCurrent = 'mm_current_v2';
  static const _kSaved = 'mm_saved_v2';
  static const _kHistory = 'mm_history_v2';

  static Future<double> getBudget() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_kBudget) ?? 0.0;
  }

  static Future<void> setBudget(double v) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kBudget, v);
  }

  static Future<List<GroceryItem>> getCurrentItems() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kCurrent);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => GroceryItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setCurrentItems(List<GroceryItem> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCurrent, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<List<GroceryItem>> getSavedItems() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSaved);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => GroceryItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setSavedItems(List<GroceryItem> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSaved, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<List<GroceryListSnapshot>> getHistory() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kHistory);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => GroceryListSnapshot.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setHistory(List<GroceryListSnapshot> lists) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kHistory, jsonEncode(lists.map((e) => e.toJson()).toList()));
  }
}