// feedback_screen.dart (Customer Side)

// feedback_screen.dart (Customer Side)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String vendorId;
  final String productImage; // ✅ Product image passed from Product Details

  const FeedbackScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.vendorId,
    required this.productImage,
  }) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitting = false;
  bool _showImage = false; // ✅ Toggle image visibility on button press

  void _submitFeedback() async {
    if (_feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback cannot be empty!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      User? user = _auth.currentUser;

      await _firestore.collection("feedback").add({
        "vendorId": widget.vendorId,
        "productId": widget.productId,
        "productName": widget.productName,
        "productImage": widget.productImage, // ✅ Store product image
        "userId": user?.uid ?? "Anonymous",
        "userEmail": user?.email ?? "Unknown",
        "feedback": _feedbackController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted successfully!")),
      );

      _feedbackController.clear();
      setState(() => _showImage = false); // ✅ Hide image after submission
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting feedback: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feedback for ${widget.productName}"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // ✅ Product Image (Always Visible)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: widget.productImage.isNotEmpty
                    ? Image.network(
                  widget.productImage,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, size: 100),
                )
                    : const Icon(Icons.image, size: 100),
              ),
              const SizedBox(height: 16),
          
              // ✅ Product Name
              Text(
                "Provide your feedback for ${widget.productName}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
          
              // ✅ Feedback Input Field
              TextField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Your Feedback",
                  hintText: "Type your feedback here...",
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 20),
          
              // ✅ Show Product Image Before Submitting
              if (_showImage)
                Column(
                  children: [
                    const Text(
                      "Review your product image before submitting:",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.productImage,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, size: 100),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
          
              // ✅ Submit Button
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () {
                  setState(() => _showImage = true); // ✅ Show image before submitting
                  _submitFeedback();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text("Submit Feedback", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
