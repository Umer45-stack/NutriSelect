import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DealCard extends StatefulWidget {
  final String productId;
  final String title;
  final int price;
  final int calories;
  final String imageUrl;
  // Added new property for dietary information.
  final String dietaryInfo;

  DealCard({
    required this.productId,
    required this.title,
    required this.price,
    required this.calories,
    required this.imageUrl,
    required this.dietaryInfo,
  });

  @override
  _DealCardState createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  bool isFavorite = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  void _checkIfFavorite() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .doc(widget.productId)
          .get();

      if (doc.exists) {
        setState(() {
          isFavorite = true;
        });
      }
    }
  }

  void _toggleFavorite() async {
    if (user == null) return;

    DocumentReference favoriteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(widget.productId);

    if (isFavorite) {
      await favoriteRef.delete();
      setState(() {
        isFavorite = false;
      });
    } else {
      await favoriteRef.set({
        'productId': widget.productId,
        'title': widget.title,
        'price': widget.price,
        'calories': widget.calories,
        'imageUrl': widget.imageUrl,
        'dietaryInfo':  widget.dietaryInfo,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        isFavorite = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    height: 100, // Reduced image height
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.error, size: 50),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 4, 8, 4), // Adjusted padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14), // Smaller font size
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${widget.price}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.green), // Smaller font
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.calories} kcal',
                        style: TextStyle(
                            fontSize: 12, color: Colors.red), // Smaller font
                      ),
                    ],
                  ),
                  // Display the dietary information below calories.
                  const SizedBox(height: 4),
                  Text(
                    widget.dietaryInfo,
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
