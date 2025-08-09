import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageRegularUsersScreen extends StatefulWidget {
  @override
  _ManageRegularUsersScreenState createState() => _ManageRegularUsersScreenState();
}

class _ManageRegularUsersScreenState extends State<ManageRegularUsersScreen> {
  // Function to update the user account status.
  Future<void> _updateUserStatus(String userId, String currentStatus) async {
    // Toggle status: if active then set to inactive, otherwise set to active.
    final newStatus = (currentStatus.toLowerCase() == 'active') ? 'inactive' : 'active';
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': newStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User status updated to $newStatus.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating user status.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error loading users."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;
          if (users.isEmpty) {
            return Center(child: Text("No regular users found."));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final email = userData['email'] ?? 'No Email';
              final firstName = userData['firstName'] ?? '';
              final lastName = userData['lastName'] ?? '';
              final fullName = '$firstName $lastName'.trim();
              final profileImage = userData['profileImage'] ?? '';
              // Get the current status; default to "active" if not set.
              final status = (userData['status'] ?? 'active').toString();

              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    backgroundImage: (profileImage.isNotEmpty)
                        ? NetworkImage(profileImage)
                        : null,
                    child: (profileImage.isEmpty)
                        ? Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(email),
                  subtitle: Text("Name: ${fullName.isNotEmpty ? fullName : 'No Name'}\nStatus: ${status.toUpperCase()}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Button to update/toggle the user's status.
                      IconButton(
                        icon: Icon(
                          status.toLowerCase() == 'active' ? Icons.toggle_on : Icons.toggle_off,
                          color: status.toLowerCase() == 'active' ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        onPressed: () => _updateUserStatus(userDoc.id, status),
                      ),
                      // Button to delete the user.
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Delete User"),
                              content: Text("Are you sure you want to delete this user?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (shouldDelete == true) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userDoc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("User deleted.")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error deleting user.")),
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
