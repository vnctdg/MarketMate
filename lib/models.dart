import 'dart:convert';

String makeId() => DateTime.now().microsecondsSinceEpoch.toString();

String peso(num v) {
  final s = v.toStringAsFixed(2);
  final parts = s.split('.');
  final intPart = parts[0];
  final dec = parts[1];
  final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
  final withComma = intPart.replaceAllMapped(reg, (m) => ',');
  return '₱$withComma.$dec';
}

class GroceryItem {
  final String id;
  final String name;
  final double price;
  final String? barcode;
  final String? imageUrl;

  GroceryItem({
    required this.id,
    required this.name,
    required this.price,
    this.barcode,
    this.imageUrl,
  });

  GroceryItem copyWith({
    String? id,
    String? name,
    double? price,
    String? barcode,
    String? imageUrl,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'barcode': barcode,
        'imageUrl': imageUrl,
      };

  static GroceryItem fromJson(Map<String, dynamic> j) => GroceryItem(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0.0,
        barcode: j['barcode'],
        imageUrl: j['imageUrl'],
      );

  static List<GroceryItem> listFromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => GroceryItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

class GroceryListSnapshot {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<GroceryItem> items;
  final double budget;
  final double total;

  GroceryListSnapshot({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.items,
    required this.budget,
  }) : total = items.fold(0.0, (s, e) => s + e.price);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'budget': budget,
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
      };

  static GroceryListSnapshot fromJson(Map<String, dynamic> j) => GroceryListSnapshot(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        budget: (j['budget'] as num?)?.toDouble() ?? 0.0,
        items: ((j['items'] as List?) ?? []).map((e) => GroceryItem.fromJson(Map<String, dynamic>.from(e))).toList(),
      );

  static List<GroceryListSnapshot> listFromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => GroceryListSnapshot.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}