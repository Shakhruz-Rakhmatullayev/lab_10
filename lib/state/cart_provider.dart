import 'package:flutter/foundation.dart';

import '../data/sample_data.dart';

/// A product in the cart and how many pieces of it were picked.
class CartItem {
  CartItem(this.product);

  final Product product;
  int quantity = 1;

  double get subtotal => product.price * quantity;
}

/// Shopping cart shared by the Catalog and Cart screens via `provider`.
class CartProvider extends ChangeNotifier {
  // Keyed by product id; a LinkedHashMap keeps the order items were added.
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => List.unmodifiable(_items.values);
  bool get isEmpty => _items.isEmpty;

  /// Total pieces across all products (shown on the badge).
  int get count => _items.values.fold(0, (sum, i) => sum + i.quantity);
  double get total => _items.values.fold(0, (sum, i) => sum + i.subtotal);

  bool contains(Product p) => _items.containsKey(p.id);

  void toggle(Product p) {
    if (_items.remove(p.id) == null) _items[p.id] = CartItem(p);
    notifyListeners();
  }

  void increment(Product p) {
    final item = _items[p.id];
    if (item == null) return;
    item.quantity++;
    notifyListeners();
  }

  /// Never goes below one piece; use [remove] to drop the product.
  void decrement(Product p) {
    final item = _items[p.id];
    if (item == null || item.quantity <= 1) return;
    item.quantity--;
    notifyListeners();
  }

  void remove(Product p) {
    if (_items.remove(p.id) != null) notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
