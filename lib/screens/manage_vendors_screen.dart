import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageVendorsScreen extends StatefulWidget {
  const ManageVendorsScreen({Key? key}) : super(key: key);

  @override
  _ManageVendorsScreenState createState() => _ManageVendorsScreenState();
}

class _ManageVendorsScreenState extends State<ManageVendorsScreen> {
  // Function to update vendor status.
  Future<void> _updateVendorStatus(String vendorId, String currentStatus) async {
    // Toggle status: if active then set to inactive, else set to active.
    final newStatus =
    (currentStatus.toLowerCase() == 'active') ? 'inactive' : 'active';
    try {
      await FirebaseFirestore.instance.collection('users').doc(vendorId).update({
        'status': newStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vendor status updated to $newStatus.")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating vendor status.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Vendors'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'vendor')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error loading vendors."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final vendorDocs = snapshot.data!.docs;
          if (vendorDocs.isEmpty) {
            return Center(child: Text("No vendors found."));
          }

          return ListView.builder(
            itemCount: vendorDocs.length,
            itemBuilder: (context, index) {
              final vendorDoc = vendorDocs[index];
              final vendorData = vendorDoc.data() as Map<String, dynamic>;
              final email = vendorData['email'] ?? 'No Email';
              final vendorName = vendorData['shopName'] ?? 'Vendor';
              final imageUrl = vendorData['imageUrl'] ?? '';
              // Get the current status; default to "active" if not set.
              final status = (vendorData['status'] ?? 'active').toString();

              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 30,
                    child: imageUrl.isNotEmpty
                        ? ClipOval(
                      child: Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.store,
                                size: 30, color: Colors.white),
                          );
                        },
                      ),
                    )
                        : Icon(Icons.store, color: Colors.white, size: 30),
                  ),
                  title: Text(email),
                  subtitle: Text("Shop: $vendorName\nStatus: ${status.toUpperCase()}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle status button.
                      IconButton(
                        icon: Icon(
                          status.toLowerCase() == 'active'
                              ? Icons.toggle_on
                              : Icons.toggle_off,
                          color: status.toLowerCase() == 'active'
                              ? Colors.green
                              : Colors.grey,
                          size: 32,
                        ),
                        onPressed: () =>
                            _updateVendorStatus(vendorDoc.id, status),
                      ),
                      // Delete vendor button.
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Delete Vendor"),
                              content: Text(
                                  "Are you sure you want to delete this vendor?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: Text("Delete",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (shouldDelete == true) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(vendorDoc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Vendor deleted.")),
                              );
                            } catch (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Error deleting vendor: $error")),
                              );
                            }
                          }
                        },
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
