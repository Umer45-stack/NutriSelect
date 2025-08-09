import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({Key? key}) : super(key: key);

  @override
  _AdminFeedbackScreenState createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  // A set to keep track of feedback document IDs removed optimistically.
  final Set<String> _removedDocIds = {};

  // Function to delete a feedback document by its id with optimistic UI update.
  Future<void> _deleteFeedback(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('feedback').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback removed successfully!')),
      );
    } catch (e) {
      // If deletion fails, remove the docId from our removed set to restore it.
      setState(() {
        _removedDocIds.remove(docId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing feedback: $e')),
      );
    }
  }

  // Show a confirmation dialog before deletion.
  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Feedback'),
        content: Text('Are you sure you want to remove this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              // Optimistically remove the item from the UI.
              setState(() {
                _removedDocIds.add(docId);
              });
              _deleteFeedback(docId);
            },
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference feedbackCollection =
    FirebaseFirestore.instance.collection('feedback');

    return Scaffold(
      appBar: AppBar(
        title: Text('User Feedback'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: feedbackCollection.orderBy('timestamp', descending: true).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // Handle errors.
          if (snapshot.hasError) {
            return Center(child: Text("Error loading feedback."));
          }

          // Loading indicator while waiting for data.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Get all feedback documents.
          final allDocs = snapshot.data!.docs;
          // Filter out any docs that have been removed optimistically.
          final feedbackDocs =
          allDocs.where((doc) => !_removedDocIds.contains(doc.id)).toList();

          if (feedbackDocs.isEmpty) {
            return Center(child: Text("No feedback available."));
          }

          // Display each feedback item in a ListView.
          return ListView.separated(
            separatorBuilder: (context, index) => Divider(height: 1),
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              final doc = feedbackDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  // Leading product image with fallback icon.
                  leading: (data['productImage'] != null &&
                      data['productImage'].toString().isNotEmpty)
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['productImage'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, size: 50),
                    ),
                  )
                      : Icon(Icons.image, size: 50),
                  title: Text(
                    data['productName'] ?? 'No Product Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Vendor: ${data['vendorId'] ?? 'Unknown'}",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          "User: ${data['userEmail'] ?? 'Anonymous'}",
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 6),
                        Text(
                          data['feedback'] ?? '',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // Delete button for removing feedback.
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(doc.id),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
