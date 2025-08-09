import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackListScreen extends StatelessWidget {
  final String vendorId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FeedbackListScreen({super.key, required this.vendorId});

  void _deleteFeedback(String feedbackId, BuildContext context) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback deleted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting feedback: $e")),
      );
    }
  }

  void _respondToFeedback(
      String feedbackId, String existingResponse, BuildContext context) {
    TextEditingController responseController =
    TextEditingController(text: existingResponse);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Respond to Feedback"),
          content: TextField(
            controller: responseController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Vendor Response",
              hintText: "Write your response...",
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestore.collection('feedback').doc(feedbackId).update({
                    'vendorResponse': responseController.text.trim(),
                  });

                  // Add simple notification
                  DocumentSnapshot feedbackDoc =
                  await _firestore.collection('feedback').doc(feedbackId).get();
                  if (feedbackDoc.exists) {
                    var data = feedbackDoc.data() as Map<String, dynamic>;
                    await _firestore.collection('notifications').add({
                      'userId': data['userEmail'],
                      'message': 'Response received for ${data['productName']}',
                    });
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Response updated!")),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Submit Response"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Feedback'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('feedback')
            .where('vendorId', isEqualTo: vendorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var feedbackDocs = snapshot.data!.docs;
          if (feedbackDocs.isEmpty) return const Center(child: Text('No feedback available.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              var feedback = feedbackDocs[index];
              var data = feedback.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['productImage']?.isNotEmpty ?? false)
                        Image.network(
                          data['productImage'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Image.asset('assets/images/placeholder.png', height: 150),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        data['productName'] ?? 'Unknown Product',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(data['feedback'] ?? '', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16),
                          const SizedBox(width: 4),
                          Text(data['userEmail'] ?? 'Unknown User',
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                      if (data['vendorResponse']?.isNotEmpty ?? false)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.reply, size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(data['vendorResponse'],
                                    style: const TextStyle(color: Colors.green, fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _respondToFeedback(
                                feedback.id, data['vendorResponse'] ?? '', context),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("Respond"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _deleteFeedback(feedback.id, context),
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text("Delete"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
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