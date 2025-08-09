import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:async/async.dart'; // Needed for StreamZip
import 'deal_card.dart';
import 'product_details.dart';
import 'gemini_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<QuerySnapshot>? _productsStream;
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  /// Fetch available products (where isAvailable = true).
  void _fetchProducts() {
    _productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .snapshots();
  }

  /// Category Filter UI
  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Categories",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('categories').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final categories = snapshot.data!.docs;
            return Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryItem(
                    context: context,
                    isSelected: _selectedCategoryId == null,
                    imageUrl: null,
                    name: 'Show All',
                    onTap: () => setState(() => _selectedCategoryId = null),
                  ),
                  ...categories.map((category) {
                    final data = category.data() as Map<String, dynamic>? ?? {};
                    return _buildCategoryItem(
                      context: context,
                      isSelected: _selectedCategoryId == category.id,
                      imageUrl: data['imageUrl'],
                      name: data['name'] ?? 'Unknown',
                      onTap: () => setState(() => _selectedCategoryId = category.id),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Single Category Item
  Widget _buildCategoryItem({
    required BuildContext context,
    required bool isSelected,
    required String? imageUrl,
    required String name,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl != null)
              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(imageUrl),
              )
            else
              const Icon(Icons.all_inclusive, size: 30, color: Colors.green),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------
  /// Modified _buildNotifications() Method
  /// -------------------------------------------
  Widget _buildNotifications() {
    return StreamBuilder<List<QuerySnapshot>>(
      // Combining both streams: regular notifications and order notifications.
      stream: StreamZip([
        FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user?.email)
            .snapshots(),
        FirebaseFirestore.instance
            .collection('order_notifications')
            .where('orderId', isNotEqualTo: '')
            .snapshots(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final allDocs = snapshot.data!
            .expand((querySnap) => querySnap.docs)
            .toList();
        if (allDocs.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allDocs.length,
            itemBuilder: (context, index) {
              final doc = allDocs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final collectionName = doc.reference.parent.id;
              String displayMessage;
              if (collectionName == 'order_notifications') {
                displayMessage = data['message'] ?? "Order ${data['status'] ?? 'Status Unknown'}";
              } else {
                displayMessage = data['message'] ?? 'New notification';
              }
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection(doc.reference.parent.id)
                        .doc(doc.id)
                        .delete();
                    setState(() {}); // Force rebuild to update UI
                    print("Deleted notification: ${doc.id}");
                  } catch (e) {
                    print("Error deleting notification: $e");
                  }
                },
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.green),
                    title: Text(
                      displayMessage,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  /// -------------------------------------------
  /// End of _buildNotifications()
  /// -------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NutriSelect"),
        backgroundColor: Colors.green,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search by name, calories, or dietary...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GeminiChatScreen(
                apiKey: 'AIzaSyCUqosioPJnRlLj_nXt1vgMYEEkuvFpank',
              ),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.smart_toy, color: Colors.white),
        tooltip: 'Chat with AI',
      ),
      body: Column(
        children: [
          _buildNotifications(),
          _buildCategoryFilter(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Products",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text("Error loading products"));
                }
                final products = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final productCategoryId = data['categoryId'];
                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final calories = data['calories']?.toString() ?? '';
                  // pull dietaryInfo and lowercase it
                  final dietaryInfo = (data['dietaryInfo']?.toString().toLowerCase()) ?? '';

                  if (_selectedCategoryId != null &&
                      productCategoryId != _selectedCategoryId) {
                    return false;
                  }
                  final isNumeric = int.tryParse(searchQuery) != null;
                  if (isNumeric) {
                    // numeric search matches name, calories or dietaryInfo
                    return name.contains(searchQuery) ||
                        calories == searchQuery ||
                        dietaryInfo.contains(searchQuery);
                  }
                  // text search matches name or dietaryInfo
                  return name.contains(searchQuery) ||
                      dietaryInfo.contains(searchQuery);
                }).toList();
                if (products.isEmpty) {
                  return const Center(child: Text("No products found"));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final data = product.data() as Map<String, dynamic>? ?? {};
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(
                            productId: product.id,
                            productName: data['name'] ?? 'Unknown',
                            productImage: data['imageUrl'] ?? '',
                            productPrice: data['price']?.toString() ?? '0',
                            vendorId: data['vendorId'] ?? '',
                          ),
                        ),
                      ),
                      child: DealCard(
                        productId: product.id,
                        title: data['name'] ?? 'Unknown',
                        price: (data['price'] as num?)?.toInt() ?? 0,
                        calories: int.tryParse(data['calories']?.toString() ?? '0') ?? 0,
                        dietaryInfo: data['dietaryInfo'] ?? 'Unknown',
                        imageUrl: data['imageUrl'] ?? '',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
