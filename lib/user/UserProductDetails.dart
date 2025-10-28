import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  final _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    _checkIfInWishlist();
  }

  Future<void> _checkIfInWishlist() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final docRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .collection('wishlist')
          .doc(widget.productId);

      final doc = await docRef.get();
      if (mounted) {
        setState(() {
          _isFavorite = doc.exists;
        });
      }
    } catch (e) {
      debugPrint('Error checking wishlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.green),
            onPressed: () {
              Navigator.pushNamed(context, "/usercart");
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Products')
            .doc(widget.productId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Product not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final images = List<String>.from(data['images'] ?? []);
          final productName = data['product_Name'] ?? '';
          final price = data['price'] ?? 0;
          final description = data['product_Description'] ?? '';
          final size = data['size'] ?? '';
          final ratingCount = data['rating_Count'] ?? 0;
          final totalRating = data['total_Rating'] ?? 0;
          final availableQuantity = data['available_Quantity'] ?? 0;

          final averageRating =
              ratingCount > 0 ? totalRating / ratingCount : 0.0;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Carousel
                Stack(
                  children: [
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 300,
                        viewportFraction: 1.0,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                      ),
                      items: images.map((imageUrl) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error, size: 50);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () async {
                            final user = _auth.currentUser;
                            if (user == null) return;

                            final docRef = FirebaseFirestore.instance
                                .collection('Users')
                                .doc(user.email)
                                .collection('wishlist')
                                .doc(widget.productId);

                            setState(() {
                              _isFavorite = !_isFavorite;
                            });

                            if (_isFavorite) {
                              await docRef.set({
                                'likedOn': FieldValue.serverTimestamp(),
                              });
                            } else {
                              await docRef.delete();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Image Indicators
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == entry.key
                                ? Colors.green
                                : Colors.grey[300],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              size: 20,
                              color: index < averageRating.round()
                                  ? Colors.amber
                                  : Colors.grey[300],
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '($ratingCount)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Price
                      Row(
                        children: [
                          Text(
                            '₹$price',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '+ ADD',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Delivery Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping, size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Delivery Charge Varies with Location |',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Delivered Within 30 mins',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Highlights
                      const Text(
                        'Highlights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._getHighlightsForCategory(
                          data['product_Category'] ?? ''),
                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.green),
                ),
                child: const Text(
                  'Buy now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Add to cart',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getHighlightsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'honey':
        return [
          _buildHighlightItem(
              '100% Pure & Natural – Sourced directly from tribal beekeepers'),
          _buildHighlightItem(
              'Collected from Forests – No artificial processing or additives'),
          _buildHighlightItem('Rich in Nutrients'),
          _buildHighlightItem('Boosts Immunity'),
          _buildHighlightItem('Aids Digestion'),
          _buildHighlightItem('Certified Quality'),
        ];

      case 'coffee':
        return [
          _buildHighlightItem(
              'Premium Quality Coffee – Sourced from tribal farmers'),
          _buildHighlightItem('Natural & Organic – No artificial additives'),
          _buildHighlightItem('Rich Aroma and Flavor'),
          _buildHighlightItem('High in Antioxidants'),
          _buildHighlightItem('Boosts Energy and Focus'),
          _buildHighlightItem('Freshly Roasted'),
        ];

      case 'shampoos':
        return [
          _buildHighlightItem(
              'Natural & Herbal Formula – Made with traditional ingredients'),
          _buildHighlightItem('Free from Harsh Chemicals – No SLS, Parabens'),
          _buildHighlightItem('Nourishes Hair and Scalp'),
          _buildHighlightItem('Strengthens Hair Roots'),
          _buildHighlightItem('Suitable for All Hair Types'),
          _buildHighlightItem('Eco-Friendly and Sustainable'),
        ];

      case 'soaps':
        return [
          _buildHighlightItem(
              'Handcrafted Natural Soap – Made with herbal ingredients'),
          _buildHighlightItem(
              'Chemical-Free – No artificial colors or fragrances'),
          _buildHighlightItem('Gentle on Skin'),
          _buildHighlightItem('Moisturizing and Nourishing'),
          _buildHighlightItem('Suitable for All Skin Types'),
          _buildHighlightItem('Eco-Friendly and Biodegradable'),
        ];

      case 'nannari sharbat':
        return [
          _buildHighlightItem(
              'Traditional Herbal Drink – Made from natural Nannari roots'),
          _buildHighlightItem(
              'No Artificial Flavors – Pure and authentic taste'),
          _buildHighlightItem('Cooling and Refreshing'),
          _buildHighlightItem('Aids Digestion'),
          _buildHighlightItem('Rich in Antioxidants'),
          _buildHighlightItem('Natural Body Coolant'),
        ];

      case 'powders':
        return [
          _buildHighlightItem(
              '100% Natural Powder – Sourced from tribal communities'),
          _buildHighlightItem('No Additives or Preservatives'),
          _buildHighlightItem('Rich in Nutrients'),
          _buildHighlightItem('Traditional Processing Methods'),
          _buildHighlightItem('Versatile Usage'),
          _buildHighlightItem('High Quality and Purity'),
        ];

      case 'triphala':
        return [
          _buildHighlightItem(
              'Pure Triphala – Traditional Ayurvedic formulation'),
          _buildHighlightItem('Natural & Organic – No chemicals or additives'),
          _buildHighlightItem('Supports Digestive Health'),
          _buildHighlightItem('Rich in Antioxidants'),
          _buildHighlightItem('Boosts Immunity'),
          _buildHighlightItem('Detoxifies the Body'),
        ];

      default:
        return [
          _buildHighlightItem('100% Natural & Organic'),
          _buildHighlightItem('Sourced from Tribal Communities'),
          _buildHighlightItem('No Artificial Additives'),
          _buildHighlightItem('High Quality Product'),
          _buildHighlightItem('Traditionally Processed'),
          _buildHighlightItem('Certified Quality'),
        ];
    }
  }

  Widget _buildHighlightItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
