import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  // List to store cart items
  final List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  // Add item to the cart
  void addItem(String productId, String title, int price) {
    int index = _cartItems.indexWhere((item) => item['productId'] == productId);

    if (index != -1) {
      _cartItems[index]['quantity'] += 1; // Increment quantity if item exists
    } else {
      _cartItems.add({
        'productId': productId, // 🔹 Store productId
        'title': title,
        'price': price,
        'quantity': 1,
      });
    }
    notifyListeners();
  }

  // Remove item from the cart
  void removeItem(String productId) {
    _cartItems.removeWhere((item) => item['productId'] == productId);
    notifyListeners();
  }

  // Clear all items from the cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Calculate total price
  int get totalPrice {
    int total = 0;
    for (var item in _cartItems) {
      int price = item['price'] as int? ?? 0;
      int quantity = item['quantity'] as int? ?? 0;

      total += price * quantity;
    }
    return total;
  }

  // Total items in the cart
  int get totalItems {
    int total = 0;
    for (var item in _cartItems) {
      total += item['quantity'] as int? ?? 0;
    }
    return total;
  }
}
