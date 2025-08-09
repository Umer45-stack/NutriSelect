import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  final String vendorId;

  const AddProductScreen({super.key, required this.vendorId});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  // Added new controller for dietary info text field
  final TextEditingController _dietaryInfoController = TextEditingController();

  File? _imageFile;
  bool _isUploading = false;
  String? _selectedCategoryId;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image upload error: $e")),
      );
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a product image")));
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }

    try {
      final imageUrl = await _uploadImageToFirebase(_imageFile!);
      if (imageUrl == null) return;

      final price = double.tryParse(_priceController.text) ?? 0.0;
      final calories = int.tryParse(_caloriesController.text) ?? 0;

      final productData = {
        'name': _nameController.text.trim(),
        'price': price,
        'calories': calories,
        // You can also include dietary info in your product data if needed:
        'dietaryInfo': _dietaryInfoController.text.trim(),
        'imageUrl': imageUrl,
        'isAvailable': true,
        'vendorId': widget.vendorId,
        'categoryId': _selectedCategoryId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final firestore = FirebaseFirestore.instance;
      final newProductRef = firestore
          .collection('vendors')
          .doc(widget.vendorId)
          .collection('products')
          .doc();

      await newProductRef.set(productData);
      await firestore.collection('products').doc(newProductRef.id).set(productData);

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving product: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Product name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Price is required';
                  if (double.tryParse(value!) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  labelText: "Calories",
                  border: OutlineInputBorder(),
                  suffixText: 'kcal',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Calories are required';
                  if (int.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
              // Added new text field below calories
              const SizedBox(height: 16),
              TextFormField(
                controller: _dietaryInfoController,
                decoration: const InputDecoration(
                  labelText: "Dietary Info",
                  hintText: "Sugar Free or Gluten Free",
                  border: OutlineInputBorder(),
                ),
                // Optionally, add a validator if this field should be required:
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Dietary info is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _CategoryDropdown(
                selectedCategoryId: _selectedCategoryId,
                onChanged: (value) => setState(() => _selectedCategoryId = value),
              ),
              const SizedBox(height: 20),
              _ImageSection(
                imageFile: _imageFile,
                onPressed: _pickImage,
              ),
              const SizedBox(height: 24),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _addProduct,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('ADD PRODUCT', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No categories available');
        }

        return DropdownButtonFormField<String>(
          value: selectedCategoryId,
          hint: const Text('Select Category'),
          isExpanded: true,
          itemHeight: 70,
          items: snapshot.data!.docs.map((DocumentSnapshot category) {
            final data = category.data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl'] as String?;
            final name = data['name'] as String? ?? 'Unnamed Category';

            return DropdownMenuItem<String>(
              value: category.id,
              child: Row(
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                    )
                  else
                    const Icon(Icons.category, size: 50),
                  const SizedBox(width: 16),
                  Expanded(child: Text(name)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
          validator: (value) => value == null ? 'Category is required' : null,
        );
      },
    );
  }
}

class _ImageSection extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onPressed;

  const _ImageSection({required this.imageFile, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Image', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPressed,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageFile != null
                ? Image.file(imageFile!, fit: BoxFit.cover)
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_a_photo, size: 50),
                SizedBox(height: 8),
                Text('Tap to add product image'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
