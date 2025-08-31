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
