import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'login_screen.dart';
import 'vendor_profile.dart'; // New import for vendor profile screen
import 'feedback_list_screen.dart';
import 'categories_screen.dart';
import 'order_details_screen.dart';

class VendorPanelScreen extends StatelessWidget {
  final String vendorId;

  const VendorPanelScreen({Key? key, required this.vendorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Panel'),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId)
            .collection('products')
            .snapshots(),
        builder: (context, productsSnapshot) {
          if (!productsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('categories').snapshots(),
            builder: (context, categoriesSnapshot) {
              if (!categoriesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final categoryMap = <String, String>{};
              for (var doc in categoriesSnapshot.data!.docs) {
                categoryMap[doc.id] = doc['name'];
              }
              return ListView.builder(
                itemCount: productsSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var product = productsSnapshot.data!.docs[index];
                  Map<String, dynamic>? data = product.data() as Map<String, dynamic>?;
                  return ListTile(
                    leading: data?['imageUrl']?.isNotEmpty == true
                        ? Image.network(data!['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image_not_supported, size: 50),
                    title: Text(data?['name'] ?? 'Unnamed Product'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Price: \$${data?['price']?.toString() ?? 'N/A'}"),
                        Text("Category: ${categoryMap[data?['categoryId'] ?? 'Uncategorized']}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProductScreen(
                                vendorId: vendorId,
                                productId: product.id,
                                productData: data ?? {},
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteProduct(vendorId, product.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("Vendor Panel", style: TextStyle(fontSize: 18)),
            accountEmail: Text("Manage your products and feedback"),
            decoration: BoxDecoration(color: Colors.green),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: const Text('Vendor Profile'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VendorProfileScreen(vendorId: vendorId)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_box, color: Colors.green),
            title: const Text('Add Product'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddProductScreen(vendorId: vendorId)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.green),
            title: const Text('Manage Categories'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CategoriesScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.feedback, color: Colors.green),
            title: const Text('View Feedback'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FeedbackListScreen(vendorId: vendorId)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt, color: Colors.green),
            title: const Text('Order Details'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrderDetailsScreen(vendorId: vendorId)),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.green),
            title: const Text('Logout'),
            onTap: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => LoginScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void deleteProduct(String vendorId, String productId) async {
    final firestore = FirebaseFirestore.instance;
    await Future.wait([
      firestore.collection('vendors').doc(vendorId).collection('products').doc(productId).delete(),
      firestore.collection('products').doc(productId).delete(),
    ]);
  }
}
