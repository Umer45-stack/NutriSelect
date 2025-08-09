import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProductScreen extends StatefulWidget {
  final String vendorId;
  final String productId;
  final Map<String, dynamic> productData;

  const EditProductScreen({
    super.key,
    required this.vendorId,
    required this.productId,
    required this.productData,
  });

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  // New controller for dietary info field
  final TextEditingController _dietaryInfoController = TextEditingController();

  File? _imageFile;
  bool _isUploading = false;
  String? _imageUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.productData['name'];
    _priceController.text = widget.productData['price'].toString();
    _caloriesController.text = widget.productData['calories'].toString();
    _imageUrl = widget.productData['image'];
    // Initialize dietary info from product data if available
    _dietaryInfoController.text = widget.productData['dietaryInfo'] ?? '';
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImageToFirebase(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Image upload error: $e");
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Update product in Firestore
  void _updateProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _caloriesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields must be filled")));
      return;
    }

    String? imageUrl = _imageFile != null
        ? await _uploadImageToFirebase(_imageFile!)
        : _imageUrl;

    var firestore = FirebaseFirestore.instance;
    Map<String, dynamic> updatedData = {
      'name': _nameController.text,
      'price': double.parse(_priceController.text),
      'calories': int.parse(_caloriesController.text),
      'image': imageUrl, // ✅ Firebase Storage image URL
      // Update the product with dietary info as well.
      'dietaryInfo': _dietaryInfoController.text,
      'isAvailable': true,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Update vendor-specific collection
    await firestore
        .collection('vendors')
        .doc(widget.vendorId)
        .collection('products')
        .doc(widget.productId)
        .update(updatedData);

    // Update global products collection
    await firestore.collection('products').doc(widget.productId).update(updatedData);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product'), backgroundColor: Colors.green,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration:
                const InputDecoration(labelText: "Product Name")),
            TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number),
            TextField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: "Calories"),
                keyboardType: TextInputType.number),
            // Added new TextField for dietary info below calories
            TextField(
              controller: _dietaryInfoController,
              decoration: const InputDecoration(
                labelText: "Dietary Info",
                hintText: "Sugar Free or Gluten Free",
              ),
            ),
            const SizedBox(height: 10),
            _imageFile != null
                ? Image.file(_imageFile!, height: 100)
                : (_imageUrl != null
                ? Image.network(_imageUrl!, height: 100)
                : const Text("No image selected")),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _pickImage, child: const Text("Select Image")),
            const SizedBox(height: 20),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                onPressed: _updateProduct,
                child: const Text("Update Product")),
          ],
        ),
      ),
    );
  }
}
