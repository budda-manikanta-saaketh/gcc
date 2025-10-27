import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//Category Card
import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isFirstItem;

  const CategoryCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.isFirstItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSeeAll = isFirstItem && title.contains("See All");

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isFirstItem ? Colors.green : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isSeeAll)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 50),
              ),
            )
          else
            const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSeeAll ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Product Card
class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Future<void> addToCart(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to add items to cart")),
        );
        return;
      }

      final userEmail = user.email!;
      final userDoc =
          FirebaseFirestore.instance.collection('Users').doc(userEmail);

      final productId = widget.product['product_Id'];
      final cartDoc = userDoc.collection('cart').doc(productId);

      final cartSnap = await cartDoc.get();

      if (cartSnap.exists) {
        await cartDoc.update({
          'quantity': FieldValue.increment(1),
        });
      } else {
        await cartDoc.set({
          'productId': productId,
          'productName': widget.product['product_Name'],
          'price': widget.product['price'],
          'image': widget.product['images'][0],
          'quantity': 1,
          'addedOn': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to cart successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding to cart: $e")),
      );
    }
  }

  Future<void> updateQuantity(BuildContext context, int newQuantity) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userEmail = user.email!;
      final userDoc =
          FirebaseFirestore.instance.collection('Users').doc(userEmail);
      final productId = widget.product['product_Id'];
      final cartDoc = userDoc.collection('cart').doc(productId);

      if (newQuantity <= 0) {
        await cartDoc.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Removed from cart")),
        );
      } else {
        await cartDoc.update({'quantity': newQuantity});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating quantity: $e")),
      );
    }
  }

  Future<void> toggleWishlist(BuildContext context, String productId) async {
    try {
      String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to add to wishlist")),
        );
        return;
      }

      final wishlistDoc = FirebaseFirestore.instance
          .collection("Users")
          .doc(userEmail)
          .collection('wishlist')
          .doc(productId);

      final data = await wishlistDoc.get();

      if (data.exists) {
        await wishlistDoc.delete();
      } else {
        await wishlistDoc.set({"likedOn": FieldValue.serverTimestamp()});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating wishlist: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.product['product_Name'] ?? 'Product';
    double price = widget.product['price'] ?? 0;
    String size = widget.product["size"];
    double originalPrice = widget.product['originalPrice'] ?? price;
    String imageUrl = widget.product['images'][0] ?? '';
    String productId = widget.product['product_Id'];
    bool hasDiscount = originalPrice > price;
    int discountPercent = hasDiscount
        ? (((originalPrice - price) / originalPrice) * 100).round()
        : 0;

    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with Discount Badge
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                          )
                        : null,
                    color: Colors.grey[100],
                  ),
                  child: imageUrl.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.eco,
                            size: 50,
                            color: Colors.green[300],
                          ),
                        )
                      : null,
                ),
                // Discount Badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Favorite Button with StreamBuilder
                Positioned(
                  top: 8,
                  right: 8,
                  child: user == null
                      ? _buildFavoriteButton(false, productId)
                      : StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("Users")
                              .doc(user.email!)
                              .collection('wishlist')
                              .doc(productId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            bool isWishlisted = false;

                            if (snapshot.hasData && snapshot.data != null) {
                              isWishlisted = snapshot.data!.exists;
                            }

                            return _buildFavoriteButton(
                                isWishlisted, productId);
                          },
                        ),
                ),
              ],
            ),
          ),

          // Product Details Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 6),

                // Size Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    size,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Price and Cart Section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              '₹$originalPrice',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          Row(
                            children: [
                              const Text(
                                '₹',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                '$price',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Add to Cart Button or Quantity Selector
                user == null
                    ? _buildAddToCartButton()
                    : Align(
                        alignment: Alignment.centerRight,
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Users')
                              .doc(user.email!)
                              .collection('cart')
                              .doc(productId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return _buildAddToCartButton();
                            }

                            final cartData = snapshot.data;
                            if (cartData == null || !cartData.exists) {
                              return _buildAddToCartButton();
                            }

                            final quantity = cartData['quantity'] ?? 0;
                            return _buildQuantitySelector(quantity);
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(bool isWishlisted, String productId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isWishlisted ? Icons.favorite : Icons.favorite_border,
          color: isWishlisted ? Colors.red : Colors.grey,
          size: 20,
        ),
        onPressed: () {
          toggleWishlist(context, productId);
        },
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            addToCart(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.add_shopping_cart,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(int quantity) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                updateQuantity(context, quantity - 1);
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  quantity == 1 ? Icons.delete_outline : Icons.remove,
                  color: quantity == 1 ? Colors.red : Colors.green.shade700,
                  size: 18,
                ),
              ),
            ),
          ),
          // Quantity Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          // Increase Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                updateQuantity(context, quantity + 1);
              },
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.add,
                  color: Colors.green.shade700,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
