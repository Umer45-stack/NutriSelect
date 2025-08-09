import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details.dart';

class ProductSearchDelegate extends SearchDelegate {
  final Stream<QuerySnapshot>? productsStream;

  ProductSearchDelegate(this.productsStream);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Start typing to search products'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        final products = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final name = data['name']?.toString().toLowerCase() ?? '';
          final calories = data['calories']?.toString() ?? '';
          return name.contains(query.toLowerCase()) ||
              calories.contains(query);
        }).toList();

        if (products.isEmpty) {
          return const Center(child: Text('No matching products found'));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final data = product.data() as Map<String, dynamic>? ?? {};
            return ListTile(
              leading: data['imageUrl']?.isNotEmpty == true
                  ? Image.network(
                      data['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported),
                    )
                  : const Icon(Icons.image_not_supported),
              title: Text(data['name'] ?? 'Unknown Product'),
              subtitle: Text(
                  'Price: \$${data['price']?.toString() ?? 'N/A'} | Calories: ${data['calories']?.toString() ?? 'N/A'}'),
              onTap: () {
                Navigator.push(
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
                );
              },
            );
          },
        );
      },
    );
  }
} 