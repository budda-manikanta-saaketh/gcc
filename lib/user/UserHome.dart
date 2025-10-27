import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gcc/utils/Cards.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all category docs and return list of maps with 'Name' and 'imageUrl'
  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Categories').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((data) =>
              data.containsKey('Name') && data.containsKey('imageUrl'))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Products').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/girijan_banner.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.yellow[100],
                    child: const Center(
                      child: Text('Girijan Co-operative Corporation Limited'),
                    ),
                  );
                },
              ),
            ),
          ),

          // Categories Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See All'),
                ),
              ],
            ),
          ),

          // Categories Grid
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Text('Error loading categories'),
                );
              }

              List<Map<String, dynamic>> categories = snapshot.data!;

              if (categories.isEmpty) {
                return const Center(child: Text("No categories found"));
              }

              // Add a "See All" dummy category at first position
              categories.insert(0, {
                'Name': 'See All\nProducts',
                'imageUrl': '',
              });

              return Container(
                height: 260,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryCard(
                      title: category['Name'] ?? 'Unnamed',
                      imageUrl: category['imageUrl'] ?? '',
                      isFirstItem: index == 0,
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Popular Products Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Products',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/userallproducts");
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),

          // Products Grid
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Text('Error loading products'),
                );
              }

              List<Map<String, dynamic>> products = snapshot.data!;
              if (products.isEmpty) {
                return const Center(
                  child: Text('No products found'),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/productdetails',
                          arguments: products[index]["product_Id"],
                        );
                      },
                      child: ProductCard(product: products[index]));
                },
              );
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
