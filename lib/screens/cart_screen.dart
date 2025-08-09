import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_screen.dart'; // Import the CheckoutScreen

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Get Cart Items for the Logged-in User
  Stream<QuerySnapshot> _getCartItems() {
    return _firestore
        .collection('cart')
        .where('userId', isEqualTo: currentUser?.uid)
        .snapshots();
  }

  // Update Item Quantity
  void _updateQuantity(String cartItemId, int newQuantity) {
    if (newQuantity > 0) {
      _firestore.collection('cart').doc(cartItemId).update({'quantity': newQuantity});
    } else {
      _firestore.collection('cart').doc(cartItemId).delete();
    }
  }

  // Remove Item from Cart
  void _removeItem(String cartItemId) {
    _firestore.collection('cart').doc(cartItemId).delete();
  }

  // Clear Entire Cart
  void _clearCart() async {
    QuerySnapshot cartSnapshot = await _firestore
        .collection('cart')
        .where('userId', isEqualTo: currentUser?.uid)
        .get();

    for (var doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Calculate Total Price Correctly
  int _calculateTotal(List<QueryDocumentSnapshot> cartItems) {
    int total = 0;
    for (var item in cartItems) {
      int price = (item['price'] as num).toInt(); // ✅ Ensuring Correct Type
      int quantity = item['quantity'];
      total += price * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart', style: TextStyle(color: Colors.green)),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _clearCart,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getCartItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Your cart is empty!"));
          }

          List<QueryDocumentSnapshot> cartItems = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var cartItem = cartItems[index];
                    String cartItemId = cartItem.id;
                    String productName = cartItem['productName'];
                    String productImage = cartItem['productImage'];
                    int productPrice = (cartItem['price'] as num).toInt(); // ✅ Ensuring Correct Type
                    int quantity = cartItem['quantity'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Image.network(
                              productImage,
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 50),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),

                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _updateQuantity(cartItemId, quantity - 1),
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.green),
                                ),
                                Text('$quantity', style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  onPressed: () => _updateQuantity(cartItemId, quantity + 1),
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '\$ ${productPrice * quantity}', // ✅ Correct Price Display
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeItem(cartItemId),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Total: \$ ${_calculateTotal(cartItems)}', // ✅ Correct Total Price
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CheckoutScreen()), // ✅ Navigate to CheckoutScreen
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('CheckOut', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
