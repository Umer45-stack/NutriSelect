import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  User? currentUser;
  Map<String, dynamic>? adminData;
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    if (currentUser != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          adminData = doc.data() as Map<String, dynamic>;
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  // Function to pick a new profile image from the gallery,
  // upload it to Firebase Storage and update Firestore.
  Future<void> _changeProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
      isLoading = true;
    });

    try {
      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${currentUser!.uid}.jpg');

      // Upload the file
      await storageRef.putFile(_imageFile!);

      // Get the download URL
      final downloadURL = await storageRef.getDownloadURL();

      // Update Firestore for this user with the new profile image URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'profileImage': downloadURL});

      // Refresh the admin data to show the new image
      await fetchAdminData();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Profile image updated.")));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error updating image: $error")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to change password using a dialog
  Future<void> _changePassword() async {
    TextEditingController newPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Password"),
        content: TextField(
          controller: newPasswordController,
          obscureText: true,
          decoration: InputDecoration(labelText: "New Password"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cancel
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final newPassword = newPasswordController.text.trim();
              if (newPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Password cannot be empty.")),
                );
                return;
              }
              try {
                // Update password for current user
                await currentUser!.updatePassword(newPassword);
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Password changed successfully.")),
                );
              } on FirebaseAuthException catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: ${e.message}")),
                );
              }
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Firestore data if available; fallback to Firebase Auth info
    final email = currentUser?.email ?? '';
    final displayName = adminData != null
        ? '${adminData?['firstName'] ?? ''} ${adminData?['lastName'] ?? ''}'.trim()
        : (currentUser?.displayName ?? 'Admin');
    final profileImage = adminData?['profileImage'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Profile"),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Picture (tappable to change image)
            GestureDetector(
              onTap: _changeProfileImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green,
                backgroundImage: (profileImage.isNotEmpty)
                    ? NetworkImage(profileImage)
                    : null,
                child: (profileImage.isEmpty)
                    ? Icon(Icons.admin_panel_settings,
                    size: 50, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 16),
            // Admin Name
            Text(
              displayName.isNotEmpty ? displayName : "Admin",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            // Admin Email
            Text(
              email,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 16),
            Divider(),
            // Change Password Option
            ListTile(
              leading: Icon(Icons.lock, color: Colors.green),
              title: Text("Change Password"),
              onTap: _changePassword,
            ),
          ],
        ),
      ),
    );
  }
}
