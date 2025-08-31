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

class GroceryItem {
  final String id;
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