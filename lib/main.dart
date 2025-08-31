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
