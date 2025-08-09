import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String vendorId;

  const OrderDetailsScreen({Key? key, required this.vendorId}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final List<String> orderStatuses = ["Pending", "Shipped", "Delivered", "Cancelled"];

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Retrieve the order document to extract product names.
      DocumentSnapshot orderDoc =
      await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      List<dynamic> products = orderData['products'] ?? [];
      // Concatenate product names.
      String productNames = products.map((p) => p['productName'] ?? '').join(', ');

      // Update the order status.
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      // Build a message for the notification.
      String message = "Order updated to $newStatus for products: $productNames";

      // Save notification in Firestore with the message.
      await FirebaseFirestore.instance.collection('order_notifications').add({
        'orderId': orderId,
        'vendorId': widget.vendorId,
        'message': message,
        'status': newStatus,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated to $newStatus"), backgroundColor: Colors.green),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: $error"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order removed successfully"), backgroundColor: Colors.green),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error removing order: $error"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('vendorIds', arrayContains: widget.vendorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var order = snapshot.data!.docs[index];
              Map<String, dynamic> data = order.data() as Map<String, dynamic>;

              String orderId = order.id;
              String customerName = "${data['firstName'] ?? 'Unknown'} ${data['lastName'] ?? ''}".trim();
              double totalAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              String status = (data['status'] ?? 'Pending').trim();
              String address = "${data['address'] ?? 'No Address'}, ${data['city'] ?? ''}";
              String phone = data['phone'] ?? 'No Phone';
              List<dynamic> products = data['products'] ?? [];

              if (!orderStatuses.contains(status)) {
                status = "Pending";
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExpansionTile(
                  title: Text("Order ID: $orderId"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total: \$${totalAmount.toStringAsFixed(2)}"),
                      Text("Customer: $customerName"),
                      Text("Status: $status"),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📍 Address: $address", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("📞 Phone: $phone", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          // Display products with images
                          ...products.map((product) {
                            return ListTile(
                              leading: product['imageUrl'] != null && product['imageUrl'].isNotEmpty
                                  ? Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                                  : const Icon(Icons.image_not_supported),
                              title: Text(product['productName'] ?? 'Unknown Product'),
                              subtitle: Text("Quantity: ${product['quantity']}  |  Price: \$${(product['price'] * product['quantity']).toStringAsFixed(2)}"),
                            );
                          }).toList(),
                          const SizedBox(height: 10),
                          // Dropdown for updating status
                          Row(
                            children: [
                              const Text("Update Status:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: status,
                                items: orderStatuses
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    _updateOrderStatus(orderId, newStatus);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Remove order button
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Confirm Removal"),
                                    content: const Text("Are you sure you want to remove this order?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _removeOrder(orderId);
                                        },
                                        child: const Text("Remove", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete, color: Colors.white),
                              label: const Text("Remove Order"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
