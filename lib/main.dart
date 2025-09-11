import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MarketMateApp());
}

class MarketMateApp extends StatefulWidget {
  const MarketMateApp({super.key});

  @override
  State<MarketMateApp> createState() => _MarketMateAppState();
}

class _MarketMateAppState extends State<MarketMateApp> {
  int _index = 0;

  final _groceryKey = GlobalKey<GroceryListPageState>();
  final _historyKey = GlobalKey<HistoryPageState>();
  final _itemsKey = GlobalKey<ItemsPageState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MarketMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            GroceryListPage(key: _groceryKey),
            HistoryPage(key: _historyKey),
            ItemsPage(key: _itemsKey),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Grocery'),
            NavigationDestination(icon: Icon(Icons.history), label: 'History'),
            NavigationDestination(icon: Icon(Icons.list_alt), label: 'Items'),
          ],
        ),
      ),
    );
  }
}

// ======================= MODELS & STORAGE =======================
class GroceryItem {
  final String id; // uuid-ish simple
  final String name;
  final double price;
  final String? barcode;
  final bool checked;

  GroceryItem({
    required this.id,
    required this.name,
    required this.price,
    this.barcode,
    this.checked = false,
  });

  GroceryItem copyWith({String? id, String? name, double? price, String? barcode, bool? checked}) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      barcode: barcode ?? this.barcode,
      checked: checked ?? this.checked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'barcode': barcode,
        'checked': checked,
      };

  static GroceryItem fromJson(Map<String, dynamic> m) => GroceryItem(
        id: m['id'],
        name: m['name'],
        price: (m['price'] as num).toDouble(),
        barcode: m['barcode'],
        checked: m['checked'] ?? false,
      );
}

class GroceryListSnapshot {
  final String id;
  final String title; // e.g., date or custom label
  final DateTime createdAt;
  final List<GroceryItem> items;
  final double budget;

  GroceryListSnapshot({required this.id, required this.title, required this.createdAt, required this.items, required this.budget});

  double get total => items.fold(0.0, (s, e) => s + e.price);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'budget': budget,
        'items': items.map((e) => e.toJson()).toList(),
      };

  static GroceryListSnapshot fromJson(Map<String, dynamic> m) => GroceryListSnapshot(
        id: m['id'],
        title: m['title'],
        createdAt: DateTime.parse(m['createdAt']),
        budget: (m['budget'] as num).toDouble(),
        items: (m['items'] as List).map((e) => GroceryItem.fromJson(e)).toList(),
      );
}

class Storage {
  static const _kBudget = 'mm_budget';
  static const _kCurrentItems = 'mm_current_items';
  static const _kSavedItems = 'mm_saved_items';
  static const _kHistory = 'mm_history';

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
    final raw = p.getString(_kCurrentItems);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).map((e) => GroceryItem.fromJson(e)).toList();
    return list;
  }

  static Future<void> setCurrentItems(List<GroceryItem> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCurrentItems, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<List<GroceryItem>> getSavedItems() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSavedItems);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => GroceryItem.fromJson(e)).toList();
  }

  static Future<void> setSavedItems(List<GroceryItem> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSavedItems, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<List<GroceryListSnapshot>> getHistory() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kHistory);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => GroceryListSnapshot.fromJson(e)).toList();
  }

  static Future<void> setHistory(List<GroceryListSnapshot> lists) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kHistory, jsonEncode(lists.map((e) => e.toJson()).toList()));
  }
}

String peso(num v) => '₱' + v.toStringAsFixed(2);
String makeId() => DateTime.now().microsecondsSinceEpoch.toString();

// ======================= GROCERY PAGE =======================
class GroceryListPage extends StatefulWidget {
  const GroceryListPage({super.key});
  @override
  State<GroceryListPage> createState() => GroceryListPageState();
}

class GroceryListPageState extends State<GroceryListPage> {
  double _budget = 0.0;
  List<GroceryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await Storage.getBudget();
    final items = await Storage.getCurrentItems();
    setState(() {
      _budget = b;
      _items = items;
    });
  }

  double get _total => _items.fold(0.0, (s, e) => s + e.price);
  double get _remaining => (_budget - _total).clamp(-999999.0, 999999.0);
  double get _progress => _budget <= 0 ? 0 : (_total / _budget).clamp(0.0, 1.0);

  Future<void> _setBudgetDialog() async {
    final ctrl = TextEditingController(text: _budget > 0 ? _budget.toStringAsFixed(2) : '');
    final v = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Budget'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₱ ', hintText: 'e.g. 1500.00'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                final parsed = double.tryParse(ctrl.text.replaceAll(',', ''));
                if (parsed != null) Navigator.pop(context, parsed);
              },
              child: const Text('Save')),
        ],
      ),
    );
    if (v != null) {
      setState(() => _budget = v);
      await Storage.setBudget(v);
    }
  }

  Future<void> _addItemDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();

    final item = await showDialog<GroceryItem>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameCtrl),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Price', prefixText: '₱ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: priceCtrl,
            ),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Barcode (optional)'), controller: barcodeCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.replaceAll(',', ''));
                if (name.isEmpty || price == null) return;
                Navigator.pop(
                  context,
                  GroceryItem(id: makeId(), name: name, price: price, barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim()),
                );
              },
              child: const Text('Add')),
        ],
      ),
    );

    if (item != null) {
      setState(() => _items.add(item));
      await Storage.setCurrentItems(_items);
      // also add/update saved items catalog for future
      final saved = await Storage.getSavedItems();
      final idx = saved.indexWhere((e) => e.name.toLowerCase() == item.name.toLowerCase() || (e.barcode != null && e.barcode == item.barcode));
      if (idx >= 0) {
        saved[idx] = saved[idx].copyWith(price: item.price, barcode: item.barcode);
      } else {
        saved.add(item);
      }
      await Storage.setSavedItems(saved);
    }
  }

  Future<void> _addByBarcodeDialog() async {
    final ctrl = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add via Barcode'),
        content: TextField(decoration: const InputDecoration(labelText: 'Enter / Scan barcode'), controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Use')),
        ],
      ),
    );
    if (barcode == null || barcode.isEmpty) return;

    final saved = await Storage.getSavedItems();
    final found = saved.where((e) => e.barcode == barcode).toList();
    if (found.isNotEmpty) {
      setState(() => _items.add(found.first));
      await Storage.setCurrentItems(_items);
      return;
    }

    // If not found, offer to create a new item with that barcode
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final newItem = await showDialog<GroceryItem>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New item for this barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Barcode: $barcode'),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameCtrl),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Price', prefixText: '₱ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: priceCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text);
                if (name.isEmpty || price == null) return;
                Navigator.pop(context, GroceryItem(id: makeId(), name: name, price: price, barcode: barcode));
              },
              child: const Text('Save')),
        ],
      ),
    );

    if (newItem != null) {
      setState(() => _items.add(newItem));
      await Storage.setCurrentItems(_items);
      final savedAll = await Storage.getSavedItems();
      savedAll.add(newItem);
      await Storage.setSavedItems(savedAll);
    }
  }

  Future<void> _checkout() async {
    if (_items.isEmpty) return;
    final titleCtrl = TextEditingController(text: 'Grocery ${DateTime.now().toString().substring(0, 16)}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${peso(_total)}'),
            const SizedBox(height: 4),
            Text('Budget: ${peso(_budget)}'),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Title (optional)'), controller: titleCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save to History')),
        ],
      ),
    );

    if (ok != true) return;

    final snapshot = GroceryListSnapshot(
      id: makeId(),
      title: titleCtrl.text.trim().isEmpty ? 'Grocery ${DateTime.now().toLocal().toString().substring(0, 16)}' : titleCtrl.text.trim(),
      createdAt: DateTime.now(),
      items: List.from(_items),
      budget: _budget,
    );

    final history = await Storage.getHistory();
    history.insert(0, snapshot);
    await Storage.setHistory(history);

    setState(() => _items.clear());
    await Storage.setCurrentItems(_items);
  }

  Future<void> _removeItem(GroceryItem item) async {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    await Storage.setCurrentItems(_items);
  }

  @override
  Widget build(BuildContext context) {
    final pct = _progress;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketMate – Grocery'),
        actions: [
          IconButton(onPressed: _setBudgetDialog, tooltip: 'Set Budget', icon: const Icon(Icons.account_balance_wallet)),
          IconButton(onPressed: _checkout, tooltip: 'Checkout (save to history)', icon: const Icon(Icons.check_circle)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(onPressed: _addItemDialog, label: const Text('Add Item'), icon: const Icon(Icons.add)),
          const SizedBox(height: 8),
          FloatingActionButton.extended(onPressed: _addByBarcodeDialog, label: const Text('Add via Barcode'), icon: const Icon(Icons.qr_code_scanner)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Progress Circle with child (wireframe style)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(pct >= 1 ? Colors.red : Colors.green),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(_budget <= 0 ? 0 : (pct * 100)).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('used', style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('Budget', peso(_budget)),
                  _kv('Total', peso(_total)),
                  _kv('Remaining', peso(_remaining)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('Current List', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No items yet. Tap "Add Item" to start.'),
            ),
          ..._items.map((e) => Dismissible(
                key: ValueKey(e.id),
                background: Container(color: Colors.redAccent),
                onDismissed: (_) => _removeItem(e),
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text(e.name),
                  subtitle: e.barcode != null ? Text('Barcode: ${e.barcode}') : null,
                  trailing: Text(peso(e.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
          const SizedBox(height: 100), // space for FABs
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(v),
          ],
        ),
      );
}

// ======================= HISTORY PAGE =======================
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<GroceryListSnapshot> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await Storage.getHistory();
    setState(() => _history = h);
  }

  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This will remove all past lists.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      await Storage.setHistory([]);
      setState(() => _history.clear());
    }
  }

  void _showDetails(GroceryListSnapshot s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.title),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Budget'), Text(peso(s.budget))]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total'), Text(peso(s.total))]),
              const Divider(),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  itemCount: s.items.length,
                  itemBuilder: (_, i) {
                    final e = s.items[i];
                    return ListTile(
                      dense: true,
                      title: Text(e.name),
                      trailing: Text(peso(e.price)),
                      subtitle: e.barcode != null ? Text('Barcode: ${e.barcode}') : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketMate – History'),
        actions: [
          IconButton(onPressed: _clearHistory, icon: const Icon(Icons.delete_sweep)),
        ],
      ),
      body: _history.isEmpty
          ? const Center(child: Text('No history yet. Complete a list from the Grocery page.'))
          : ListView.separated(
              itemCount: _history.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = _history[i];
                return ListTile(
                  title: Text(s.title),
                  subtitle: Text(s.createdAt.toLocal().toString().substring(0, 16)),
                  leading: const Icon(Icons.receipt_long),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(peso(s.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Budget: ${peso(s.budget)}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                    ],
                  ),
                  onTap: () => _showDetails(s),
                );
              },
            ),
    );
  }
}

// ======================= ITEMS PAGE =======================
class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});
  @override
  State<ItemsPage> createState() => ItemsPageState();
}

class ItemsPageState extends State<ItemsPage> {
  List<GroceryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await Storage.getSavedItems();
    setState(() => _items = items);
  }

  Future<void> _addItem() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();

    final item = await showDialog<GroceryItem>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Item for Future'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameCtrl),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Default Price', prefixText: '₱ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: priceCtrl,
            ),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Barcode (optional)'), controller: barcodeCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text);
                if (name.isEmpty || price == null) return;
                Navigator.pop(context, GroceryItem(id: makeId(), name: name, price: price, barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim()));
              },
              child: const Text('Save')),
        ],
      ),
    );

    if (item != null) {
      setState(() => _items.add(item));
      await Storage.setSavedItems(_items);
    }
  }

  Future<void> _mockScan() async {
    // NOTE: This is a demo stub so you can run without camera.
    // For real scanning, add `mobile_scanner` or `barcode_scan2` and replace this dialog with camera flow.
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mock Scan (enter barcode)'),
        content: TextField(decoration: const InputDecoration(labelText: 'Barcode value'), controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('OK')),
        ],
      ),
    );

    if (code == null || code.isEmpty) return;

    // If the code exists, highlight it; if not, offer to create
    final existingIdx = _items.indexWhere((e) => e.barcode == code);
    if (existingIdx >= 0) {
      final e = _items[existingIdx];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found saved item: ${e.name} (${peso(e.price)})')));
      return;
    }

    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final newItem = await showDialog<GroceryItem>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save new item for this barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Barcode: $code'),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameCtrl),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Default Price', prefixText: '₱ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: priceCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text);
                if (name.isEmpty || price == null) return;
                Navigator.pop(context, GroceryItem(id: makeId(), name: name, price: price, barcode: code));
              },
              child: const Text('Save')),
        ],
      ),
    );

    if (newItem != null) {
      setState(() => _items.add(newItem));
      await Storage.setSavedItems(_items);
    }
  }

  Future<void> _deleteItem(GroceryItem e) async {
    setState(() => _items.removeWhere((x) => x.id == e.id));
    await Storage.setSavedItems(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketMate – Items'),
        actions: [
          IconButton(onPressed: _mockScan, tooltip: 'Mock Scan / Enter Barcode', icon: const Icon(Icons.qr_code_scanner)),
          IconButton(onPressed: _addItem, tooltip: 'Add Item', icon: const Icon(Icons.add_circle)),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No saved items yet. Add some or use Mock Scan.'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = _items[i];
                return ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: Text(e.name),
                  subtitle: Text('${peso(e.price)}${e.barcode != null ? ' • ${e.barcode}' : ''}'),
                  trailing: IconButton(onPressed: () => _deleteItem(e), icon: const Icon(Icons.delete_outline)),
                );
              },
            ),
    );
  }
}
