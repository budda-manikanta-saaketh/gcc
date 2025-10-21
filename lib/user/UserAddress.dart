import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserAddress extends StatefulWidget {
  const UserAddress({super.key});

  @override
  State<UserAddress> createState() => _UserAddressState();
}

class _UserAddressState extends State<UserAddress> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Future<List<Map<String, dynamic>>> _futureAddresses;

  @override
  void initState() {
    super.initState();
    _futureAddresses = _fetchAddresses();
  }

  Future<List<Map<String, dynamic>>> _fetchAddresses() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('Users')
          .doc(user.email)
          .collection('address')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // store doc id if needed
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching addresses: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Addresses"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureAddresses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading addresses',
                style: TextStyle(color: Colors.red.shade700),
              ),
            );
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No addresses found.\nAdd your first address!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          } else {
            final addresses = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _buildAddressCard(address);
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, "/useraddaddress");
          setState(() {
            _futureAddresses = _fetchAddresses();
          });
        },
        backgroundColor: Colors.green,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: Colors.green.shade700,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address['name'] ?? 'Unnamed',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  "${address['flat'] ?? ''}, ${address['address'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''}, ${address['pincode'] ?? ''}",
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                ),
                if (address['contactName'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Name: ${address['contactName']}",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
                if (address['phone'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Phone: ${address['phone']}",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Handle edit address
            },
            icon: Icon(
              Icons.edit,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
