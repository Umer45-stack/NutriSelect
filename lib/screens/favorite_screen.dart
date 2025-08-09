import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'deal_card.dart';
import 'product_details.dart';  // ← make sure this import is here

class FavoriteScreen extends StatefulWidget {
  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Stream<QuerySnapshot>? _favoritesStream;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _favoritesStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favorites"),
        backgroundColor: Colors.green,
      ),
      body: _favoritesStream == null
          ? Center(child: Text("Sign in to see favorites"))
          : StreamBuilder<QuerySnapshot>(
        stream: _favoritesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No favorite products yet"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(
                        productId:   data['productId']   ?? '',
                        productName: data['title']       ?? '',
                        productImage:data['imageUrl']    ?? '',
                        productPrice:data['price']?.toString() ?? '0',
                        vendorId:    data['vendorId']    ?? '',  // default empty
                      ),
                    ),
                  );
                },
                child: DealCard(
                  productId:   data['productId']   ?? '',
                  title:       data['title']       ?? '',
                  price:       data['price']       ?? 0,
                  calories:    data['calories']    ?? 0,
                  imageUrl:    data['imageUrl']    ?? '',
                  dietaryInfo: data['dietaryInfo'] ?? 'Unknown',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
