import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserAddAddress extends StatefulWidget {
  const UserAddAddress({super.key});

  @override
  State<UserAddAddress> createState() => _UserAddAddressState();
}

class _UserAddAddressState extends State<UserAddAddress> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _name = TextEditingController();

  bool _isSaving = false;

  void _saveAddress(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final docRef = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .collection('address')
          .add({
        "flat": _flatController.text.trim(),
        "address": _addressController.text.trim(),
        "city": _cityController.text.trim(),
        "state": _stateController.text.trim(),
        "pincode": _pincodeController.text.trim(),
        "contactName": _contactNameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        "name": _name.text.trim(),
      });

      await docRef.update({
        "id": docRef.id,
      });

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Address"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_name, "Address Name"),
              _buildTextField(
                  _flatController, "Flat / House No / Building Name"),
              _buildTextField(_addressController, "Full Address"),
              _buildTextField(_cityController, "City"),
              _buildTextField(_stateController, "State"),
              _buildTextField(_pincodeController, "Pincode", isNumber: true),
              _buildTextField(_contactNameController, "Contact Name"),
              _buildTextField(_phoneController, "Phone Number",
                  isNumber: true, maxLength: 10),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveAddress(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Address",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          if (isNumber && value.trim().length < 6) {
            return 'Please enter a valid $label';
          }
          return null;
        },
      ),
    );
  }
}
