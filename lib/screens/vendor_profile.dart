import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VendorProfileScreen extends StatefulWidget {
  final String vendorId;

  const VendorProfileScreen({Key? key, required this.vendorId}) : super(key: key);

  @override
  _VendorProfileScreenState createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  File? _newImage;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery and update profile image in Firestore
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File image = File(pickedFile.path);
        await _uploadAndUpdateImage(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  // Upload image to Firebase Storage and update Firestore with its URL
  Future<void> _uploadAndUpdateImage(File image) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref =
      FirebaseStorage.instance.ref().child('vendor_pictures/$fileName');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.vendorId)
          .update({'imageUrl': downloadUrl});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Profile image updated"),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error uploading image: $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  // Opens a dialog that allows editing shop name and phone number.
  Future<void> _editProfileInfo(Map<String, dynamic> data) async {
    TextEditingController shopNameController =
    TextEditingController(text: data['shopName'] ?? '');
    TextEditingController phoneController =
    TextEditingController(text: data['phone'] ?? '');
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile Info"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: shopNameController,
                decoration: const InputDecoration(
                  labelText: "Shop Name",
                ),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String newShopName = shopNameController.text.trim();
                String newPhone = phoneController.text.trim();
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.vendorId)
                    .update({
                  'shopName': newShopName,
                  'phone': newPhone,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: const Text("Profile Updated Successfully!"),
                      backgroundColor: Colors.green),
                );
              },
              child: const Text("Update"),
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
        title: const Text("Vendor Profile"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.vendorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No profile data found"));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  data['imageUrl'] != null && data['imageUrl'] != ''
                      ? CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(data['imageUrl']),
                  )
                      : const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text("Change Profile Image"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  Text("Shop Name: ${data['shopName'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text("Email: ${data['email'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text("Phone: ${data['phone'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _editProfileInfo(data),
                    child: const Text("Edit Profile Info"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
