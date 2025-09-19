import 'package:flutter/foundation.dart';
import 'models.dart';
import 'storage.dart';

class AppState extends ChangeNotifier {
  double budget = 0.0;
  final List<GroceryItem> _currentItems = [];
  final List<GroceryItem> _savedItems = [];
  final List<GroceryListSnapshot> _history = [];
  bool loading = true;

  AppState();

  // Expose immutable lists
  List<GroceryItem> get currentItems => List.unmodifiable(_currentItems);
  List<GroceryItem> get savedItems => List.unmodifiable(_savedItems);
  List<GroceryListSnapshot> get history => List.unmodifiable(_history);

  // Derived properties
  double get total => _currentItems.fold(0.0, (s, e) => s + e.price);
  double get remaining => (budget - total);
  bool get isOverBudget => budget > 0 && total > budget;
  double get progress => budget <= 0 ? 0.0 : (total / budget).clamp(0.0, 1.0);

  /// Load everything from storage
  Future<void> loadAll() async {
    loading = true;
    notifyListeners();
    budget = await Storage.getBudget();
    _currentItems
      ..clear()
      ..addAll(await Storage.getCurrentItems());
    _savedItems
      ..clear()
      ..addAll(await Storage.getSavedItems());
    _history
      ..clear()
      ..addAll(await Storage.getHistory());
    loading = false;
    notifyListeners();
  }

  Future<void> setBudget(double v) async {
    budget = v;
    await Storage.setBudget(v);
    notifyListeners();
  }

  Future<void> addItem(GroceryItem item, {bool persistSaved = true}) async {
    _currentItems.add(item);
    await Storage.setCurrentItems(_currentItems);
    if (persistSaved) await _upsertSaved(item);
    notifyListeners();
  }

  Future<void> _upsertSaved(GroceryItem item) async {
    final idx = _savedItems.indexWhere((s) =>
        s.name.toLowerCase() == item.name.toLowerCase() ||
        (s.barcode != null && s.barcode == item.barcode));
    if (idx >= 0) {
      _savedItems[idx] = _savedItems[idx].copyWith(price: item.price, barcode: item.barcode, imageUrl: item.imageUrl);
    } else {
      _savedItems.add(item);
    }
    await Storage.setSavedItems(_savedItems);
  }

  Future<void> addSavedItem(GroceryItem item) async {
    _savedItems.add(item);
    await Storage.setSavedItems(_savedItems);
    notifyListeners();
  }

  Future<void> deleteSaved(String id) async {
    _savedItems.removeWhere((e) => e.id == id);
    await Storage.setSavedItems(_savedItems);
    notifyListeners();
  }

  Future<void> removeCurrentItem(String id) async {
    _currentItems.removeWhere((e) => e.id == id);
    await Storage.setCurrentItems(_currentItems);
    notifyListeners();
  }

  Future<bool> checkout({bool force = false, String? title}) async {
    if (currentItems.isEmpty) {
      return false; // Prevent checkout if list is empty
    }
    if (isOverBudget && !force) return false;
    final snapshot = GroceryListSnapshot(
      id: makeId(),
      title: title?.trim().isEmpty ?? true ? 'Grocery ${DateTime.now().toLocal().toString().substring(0, 16)}' : title!.trim(),
      createdAt: DateTime.now(),
      items: List.from(_currentItems),
      budget: budget,
    );
    _history.insert(0, snapshot);
    await Storage.setHistory(_history);
    _currentItems.clear();
    await Storage.setCurrentItems(_currentItems);
    notifyListeners();
    return true;
  }

  Future<void> reAddHistory(String snapshotId) async {
    final s = _history.firstWhere((h) => h.id == snapshotId, orElse: () => throw Exception('History snapshot not found'));
    _currentItems.addAll(s.items.map((e) => e.copyWith(id: makeId())));
    await Storage.setCurrentItems(_currentItems);
    notifyListeners();
  }
}