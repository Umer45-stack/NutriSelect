// vendor_feedback_screen.dart (Vendor Side)

// vendor_feedback_screen.dart (Vendor Side)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorFeedbackScreen extends StatelessWidget {
  final String vendorId;

  const VendorFeedbackScreen({Key? key, required this.vendorId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug: Print vendorId on Vendor side
    print("VendorFeedbackScreen: Displaying feedback for vendorId: $vendorId");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Feedback'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedback')
            .where('vendorId', isEqualTo: vendorId) // Ensure vendorId is used in the query
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var feedbackDocs = snapshot.data!.docs;

          if (feedbackDocs.isEmpty) {
            return const Center(child: Text("No feedback available"));
          }

          return ListView.builder(
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              var feedback = feedbackDocs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(feedback['productName'] ?? 'Unknown Product'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feedback['feedback'] ?? 'No Feedback'),
                      Text("By: ${feedback['userEmail'] ?? 'Anonymous'}",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}