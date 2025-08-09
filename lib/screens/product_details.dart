// product_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'feedback_screen.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String productId;
  final String productName;
  final String productImage;
  final String productPrice;
  final String vendorId;

  const ProductDetailsScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.vendorId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("ProductDetailsScreen: vendorId = $vendorId");

    // ✅ Fix: Correct price parsing (handle decimal cases properly)
    double parsedPrice = double.tryParse(productPrice.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(productName, style: const TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.green),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            productImage.startsWith('http')
                ? Image.network(
              productImage,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported, size: 200),
            )
                : Image.asset(
              productImage,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),

            Text(
              productName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text(
              'Price: \$ ${parsedPrice.toStringAsFixed(0)}', // ✅ Ensure correct price format
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 20),

            // 🔹 Add to Cart Button (Firestore Implementation)
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please log in to add items to cart.")),
                  );
                  return;
                }

                CollectionReference cartRef = FirebaseFirestore.instance.collection('cart');

                // Check if item already exists in the cart
                QuerySnapshot existingCart = await cartRef
                    .where('userId', isEqualTo: user.uid)
                    .where('productId', isEqualTo: productId)
                    .get();

                if (existingCart.docs.isNotEmpty) {
                  DocumentSnapshot existingDoc = existingCart.docs.first;
                  int currentQuantity = existingDoc['quantity'] ?? 1;
                  await cartRef.doc(existingDoc.id).update({'quantity': currentQuantity + 1});
                } else {
                  await cartRef.add({
                    'userId': user.uid,
                    'productId': productId,
                    'productName': productName,
                    'productImage': productImage,
                    'price': parsedPrice, // ✅ Ensure price is correctly stored
                    'quantity': 1,
                    'vendorId': vendorId
                  });
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$productName added to cart')),
                );

                Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Add to Cart', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedbackScreen(
                      productId: productId,
                      productName: productName,
                      vendorId: vendorId,
                      productImage: productImage,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Give Feedback', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('feedback')
                    .where('productId', isEqualTo: productId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No vendor response yet.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  var feedbackDocs = snapshot.data!.docs;
                  List<String> vendorResponses = feedbackDocs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .where((feedback) => feedback.containsKey('vendorResponse'))
                      .map((feedback) => feedback['vendorResponse'] as String)
                      .toList();

                  if (vendorResponses.isEmpty) {
                    return const Center(
                      child: Text(
                        "No vendor response yet.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: vendorResponses.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Vendor Response:",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vendorResponses[index],
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
