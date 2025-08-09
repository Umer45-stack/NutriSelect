import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController countryController =
  TextEditingController(text: "United States");
  final TextEditingController zipController = TextEditingController();

  bool isLoading = false;
  bool saveCardForFuture = false;
  double totalAmount = 0.0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> orderedProducts = [];
  Set<String> vendorIds = {};

  @override
  void initState() {
    super.initState();
    _calculateTotalAmount();
  }

  Future<void> _calculateTotalAmount() async {
    try {
      QuerySnapshot cartSnapshot = await _firestore
          .collection('cart')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .get();

      double total = 0.0;
      List<Map<String, dynamic>> products = [];
      Set<String> vendorSet = {};

      for (var doc in cartSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data == null ||
            !data.containsKey('price') ||
            !data.containsKey('quantity') ||
            !data.containsKey('productId')) continue;

        double price = (data['price'] as num).toDouble();
        int quantity = (data['quantity'] as num).toInt();
        total += price * quantity;

        DocumentSnapshot productDoc =
        await _firestore.collection('products').doc(data['productId']).get();
        if (productDoc.exists) {
          var productData =
              productDoc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
          String vendorId = productData['vendorId'] ?? '';
          if (vendorId.isNotEmpty) vendorSet.add(vendorId);
          products.add({
            'productId': data['productId'],
            'productName': productData['name'] ?? 'Unknown',
            'price': price,
            'quantity': quantity,
            'imageUrl': productData['imageUrl'] ?? '',
            'vendorId': vendorId,
          });
        }
      }
      setState(() {
        totalAmount = total;
        orderedProducts = products;
        vendorIds = vendorSet;
      });
    } catch (error) {
      _showError("Error calculating total: $error");
    }
  }

  Future<void> processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (totalAmount == 0) {
      _showError("Cart is empty!");
      return;
    }
    setState(() => isLoading = true);
    try {
      await saveOrderDetails();
      _showSuccess("Order placed successfully!");
      Navigator.pop(context);
    } catch (error) {
      _showError("Error processing payment: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveOrderDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (totalAmount == 0) {
      _showError("Cart is empty!");
      return;
    }
    setState(() => isLoading = true);
    try {
      String orderId = _firestore.collection('orders').doc().id;
      await _firestore.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': _auth.currentUser?.uid,
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'phone': phoneController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'amount': totalAmount,
        'products': orderedProducts,
        'vendorIds': vendorIds.toList(),
      });
    } catch (error) {
      _showError("Error saving order: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: _paymentFormKey,
                child: Wrap(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Pay \$${totalAmount.toStringAsFixed(2)} using",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Card information",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: cardNumberController,
                      decoration: InputDecoration(
                        labelText: "Card number",
                        hintText: "1234 5678 9012 3456",
                        border: const OutlineInputBorder(),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/visa.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 50,
                          minHeight: 50,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter card number';
                        }
                        String digitsOnly = value.replaceAll(RegExp(r'\s+'), '');
                        if (digitsOnly.length != 16) {
                          return 'Card number must be 16 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expiryDateController,
                            decoration: const InputDecoration(
                              labelText: "Expiry Date (MM/YY)",
                              hintText: "MM/YY",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.datetime,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter expiry date';
                              }
                              if (!RegExp(r'^(0[1-9]|1[0-2])\/\d\d$')
                                  .hasMatch(value.trim())) {
                                return 'Invalid expiry date';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextFormField(
                            controller: cvvController,
                            decoration: const InputDecoration(
                              labelText: "CVV",
                              hintText: "123",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter CVV';
                              }
                              if (value.trim().length != 3) {
                                return 'CVV must be 3 digits';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Country or region",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: countryController,
                      decoration: const InputDecoration(
                        hintText: "United States",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: zipController,
                      decoration: const InputDecoration(
                        labelText: "ZIP",
                        hintText: "XXXXX",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Checkbox(
                          value: saveCardForFuture,
                          onChanged: (bool? value) {
                            setStateSheet(() {
                              saveCardForFuture = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text("Save card for future payments"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: () async {
                        if (!_paymentFormKey.currentState!.validate()) return;
                        Navigator.pop(context);
                        await processPayment();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        "Pay \$${totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout"),backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
                validator: (value) =>
                value!.isEmpty ? "Enter first name" : null,
              ),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
                validator: (value) =>
                value!.isEmpty ? "Enter last name" : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (value) =>
                value!.isEmpty ? "Enter address" : null,
              ),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: "City"),
                validator: (value) =>
                value!.isEmpty ? "Enter city" : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                value!.isEmpty ? "Enter phone number" : null,
              ),
              const SizedBox(height: 20),
              Text(
                "Total: \$${totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...orderedProducts.map((product) => Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: product['imageUrl'] != ''
                      ? Image.network(
                    product['imageUrl'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                      : const Icon(Icons.image_not_supported),
                  title: Text(product['productName']),
                  subtitle: Text(
                      "Quantity: ${product['quantity']}  |  Price: \$${(product['price'] * product['quantity']).toStringAsFixed(2)}"),
                ),
              )),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _showPaymentSheet();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Pay Now", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}