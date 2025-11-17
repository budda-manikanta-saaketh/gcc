// cart_screen.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserCart extends StatefulWidget {
  const UserCart({super.key});

  @override
  State<UserCart> createState() => _UserCartState();
}

class _UserCartState extends State<UserCart> {
  final _firestore = FirebaseFirestore.instance;
  final int deliveryCharge = 40;

  // Optimistic / UI state
  final Map<String, int> _optimisticQuantities = {};
  final Map<String, bool> _updatingItems = {};

  // Live in-memory items used for UI. Use ValueNotifier to update UI without full rebuild flicker.
  final ValueNotifier<List<CartItem>> _itemsNotifier =
      ValueNotifier<List<CartItem>>([]);

  // Firestore subscription
  StreamSubscription<QuerySnapshot>? _cartSubscription;

  // Track first-time load complete so we can show empty-cart vs "loading"
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _startCartListener();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _itemsNotifier.dispose();
    super.dispose();
  }

  Future<void> _placeorder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to place an order")),
      );
      return;
    }

    final userEmail = user.email!;
    final items = _itemsNotifier.value;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty")),
      );
      return;
    }

    final int subtotal = _subtotal;
    final int total = subtotal + deliveryCharge;

    try {
      final orderRef = _firestore.collection("Orders_Requests").doc();
      final userRef = _firestore
          .collection("Users")
          .doc(userEmail)
          .collection("orders")
          .doc(orderRef.id);
      final orderData = {
        "orderId": orderRef.id,
        "userEmail": userEmail,
        "createdAt": FieldValue.serverTimestamp(),
        "subTotal": subtotal,
        "deliveryCharge": deliveryCharge,
        "total": total,
        "status": "Pending",
        "items": items.map((item) {
          return {
            "productId": item.productId,
            "name": item.name,
            "price": item.price,
            "quantity": item.quantity,
            "size": item.size,
            "imageUrl": item.imageUrl,
          };
        }).toList(),
      };

      await orderRef.set(orderData);
      await userRef.set(orderData);

      // Optionally: clear the user's cart
      final cartCollection =
          _firestore.collection("Users").doc(userEmail).collection("cart");

      final batch = _firestore.batch();
      final cartDocs = await cartCollection.get();
      for (final doc in cartDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order placed successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Optionally navigate to an order confirmation page
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccessPage()));
    } catch (e) {
      debugPrint("Error placing order: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to place order. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _startCartListener() {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return;

    _cartSubscription = _firestore
        .collection('Users')
        .doc(userEmail)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      _handleCartSnapshot(snapshot.docs);
    }, onError: (err) {
      debugPrint('Cart listen error: $err');
    });
  }

  Future<void> _handleCartSnapshot(
      List<DocumentSnapshot<Map<String, dynamic>>> cartDocs) async {
    // If there are no cart docs and we've already loaded once, clear items.
    if (cartDocs.isEmpty) {
      _itemsNotifier.value = [];
      _initialLoadDone = true;
      return;
    }

    // Preserve current UI by immediately leaving current _itemsNotifier.value while we fetch product details.
    // Fetch product docs in parallel to reduce latency.
    final futures = <Future<CartItem?>>[];
    for (var cartDoc in cartDocs) {
      futures.add(_cartDocToCartItem(cartDoc));
    }

    final results = await Future.wait(futures);

    final items = results.whereType<CartItem>().toList();

    // Keep optimistic quantities if present: _cartDocToCartItem already applies optimistic quantity.
    // Update notifier with new list (atomic replace) — this will update bottom bar and list smoothly.
    _itemsNotifier.value = items;
    _initialLoadDone = true;
  }

  Future<CartItem?> _cartDocToCartItem(
      DocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      final cartData = doc.data();
      if (cartData == null) return null;

      final productId = (cartData['productId'] ?? '') as String;
      if (productId.isEmpty) return null;

      final productDoc =
          await _firestore.collection('Products').doc(productId).get();
      if (!productDoc.exists) return null;

      final p = productDoc.data()!;
      final cartId = doc.id;

      final actualQuantity = (cartData['quantity'] ?? 1) is int
          ? (cartData['quantity'] as int)
          : int.tryParse('${cartData['quantity']}') ?? 1;

      final displayQuantity = _optimisticQuantities[cartId] ?? actualQuantity;

      return CartItem(
        id: cartId,
        productId: productId,
        name: p['product_Name'] ?? '',
        imageUrl: (p['images'] as List?)?.isNotEmpty == true
            ? (p['images'] as List)[0] as String
            : '',
        price: (p['price'] ?? 0) is int
            ? (p['price'] as int)
            : (p['price'] is double
                ? (p['price'] as double).toInt()
                : int.tryParse('${p['price']}') ?? 0),
        quantity: displayQuantity,
        availableQuantity: (p['available_Quantity'] ?? 0) is int
            ? (p['available_Quantity'] as int)
            : int.tryParse('${p['available_Quantity']}') ?? 0,
        size: p['size'] ?? '',
      );
    } catch (e) {
      debugPrint('Error mapping cart doc: $e');
      return null;
    }
  }

  // Optimistic update: immediately update local state, then push change to Firestore.
  Future<void> _updateQuantity(String cartId, int newQty) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return;
    if (newQty <= 0) {
      await _removeItem(cartId);
      return;
    }

    // Apply optimistic
    _optimisticQuantities[cartId] = newQty;
    _updatingItems[cartId] = true;
    _applyOptimisticToNotifier(cartId, newQty);

    try {
      await _firestore
          .collection('Users')
          .doc(userEmail)
          .collection('cart')
          .doc(cartId)
          .update({'quantity': newQty});

      // small delay to let user see the updating state nicely
      await Future.delayed(const Duration(milliseconds: 300));
      _optimisticQuantities.remove(cartId);
      _updatingItems[cartId] = false;

      // After success, refresh already occurs via the listener; but ensure notifier reflects final value.
      _refreshSingleCartItem(cartId);
    } catch (e) {
      // revert optimistic state on error
      _optimisticQuantities.remove(cartId);
      _updatingItems[cartId] = false;
      // re-fetch cart item to restore correct quantity
      _refreshSingleCartItem(cartId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update quantity')),
        );
      }
    }
  }

  // Remove item from firestore (and optimistic flags)
  Future<void> _removeItem(String cartId) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return;

    _updatingItems[cartId] = true;
    // update UI: dim or overlay is handled by CartItemWidget
    try {
      await _firestore
          .collection('Users')
          .doc(userEmail)
          .collection('cart')
          .doc(cartId)
          .delete();
      // listener will remove it from notifier
      _updatingItems.remove(cartId);
      _optimisticQuantities.remove(cartId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Item removed from cart'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _updatingItems.remove(cartId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove item')),
        );
      }
    }
  }

  // Apply optimistic quantity change to the in-memory notifier list immediately.
  void _applyOptimisticToNotifier(String cartId, int newQty) {
    final current = List<CartItem>.from(_itemsNotifier.value);
    final idx = current.indexWhere((it) => it.id == cartId);
    if (idx != -1) {
      final old = current[idx];
      current[idx] = old.copyWith(quantity: newQty);
      _itemsNotifier.value = current;
    }
  }

  // Rebuild only a single item by refetching its product doc (used after update or error).
  Future<void> _refreshSingleCartItem(String cartId) async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;

      final cartDoc = await _firestore
          .collection('Users')
          .doc(userEmail)
          .collection('cart')
          .doc(cartId)
          .get();

      if (!cartDoc.exists) {
        // item removed — remove from notifier
        final current = List<CartItem>.from(_itemsNotifier.value);
        current.removeWhere((it) => it.id == cartId);
        _itemsNotifier.value = current;
        return;
      }

      final newItem = await _cartDocToCartItem(cartDoc);
      if (newItem == null) return;

      final current = List<CartItem>.from(_itemsNotifier.value);
      final idx = current.indexWhere((it) => it.id == cartId);
      if (idx != -1) {
        current[idx] = newItem;
      } else {
        current.add(newItem);
      }
      _itemsNotifier.value = current;
    } catch (e) {
      debugPrint('refreshSingleCartItem error: $e');
    }
  }

  // Compute subtotal from current in-memory items.
  int get _subtotal {
    final items = _itemsNotifier.value;
    return items.fold(0, (s, it) => s + it.price * it.quantity);
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to view your cart")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text("My Cart",
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: _itemsNotifier,
        builder: (context, items, _) {
          // If initial load not done and items list is empty, show a gentle placeholder (no spinner).
          if (!_initialLoadDone && items.isEmpty) {
            return _buildLoadingPlaceholder();
          }

          if (items.isEmpty) {
            return _buildEmptyCart();
          }

          final subtotal = _subtotal;
          final total = subtotal + deliveryCharge;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with item count
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        "Items in Cart",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${items.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Cart Items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isUpdating = _updatingItems[item.id] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CartItemWidget(
                        item: item,
                        isUpdating: isUpdating,
                        onQuantityChanged: (change) =>
                            _updateQuantity(item.id, item.quantity + change),
                        onRemove: () => _removeItem(item.id),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Price Summary
                _buildPriceSummaryCard(subtotal, deliveryCharge, total),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),

      // Bottom Bar
      bottomNavigationBar: ValueListenableBuilder<List<CartItem>>(
        valueListenable: _itemsNotifier,
        builder: (context, items, _) {
          if (items.isEmpty) return const SizedBox.shrink();
          final subtotal = items.fold(0, (s, it) => s + it.price * it.quantity);
          final total = subtotal + deliveryCharge;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹$total',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _placeorder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Proceed to Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // A subtle placeholder used only during the very first load (no spinner).
  Widget _buildLoadingPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.green[200]),
          const SizedBox(height: 12),
          Text('Loading cart...',
              style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some items to continue!',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  Widget _buildPriceSummaryCard(int subtotal, int delivery, int total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Subtotal', '₹$subtotal'),
          const SizedBox(height: 4),
          _buildPriceRow('Delivery Charge', '₹$delivery'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.grey[300], thickness: 1),
          ),
          _buildPriceRow('Total Amount', '₹$total', isBold: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 17 : 15,
              color: isBold ? Colors.grey[800] : Colors.grey[600],
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              color: isBold ? const Color(0xFF2E7D32) : Colors.grey[800],
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final int price;
  int quantity;
  final int availableQuantity;
  final String size;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.availableQuantity,
    required this.size,
  });

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    int? price,
    int? quantity,
    int? availableQuantity,
    String? size,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      size: size ?? this.size,
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final bool isUpdating;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.isUpdating,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUpdating
              ? const Color(0xFF2E7D32).withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Hero(
                tag: 'cart-${item.id}',
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: item.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[200],
                  ),
                  child: item.imageUrl.isEmpty
                      ? const Icon(Icons.image, color: Colors.grey, size: 40)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${item.price}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _qtyButton(Icons.remove, () => onQuantityChanged(-1),
                            enabled: item.quantity > 1),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUpdating
                                ? const Color(0xFFE8F5E9)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.quantity}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isUpdating
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey[800],
                            ),
                          ),
                        ),
                        _qtyButton(Icons.add, () {
                          if (item.quantity < item.availableQuantity) {
                            onQuantityChanged(1);
                          }
                        }, enabled: item.quantity < item.availableQuantity),
                        const Spacer(),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onRemove,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Updating overlay - non-spinner (pulsing dot + text)
          if (isUpdating)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.4),
                ),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        _PulsingDot(size: 10, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Updating...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onPressed,
      {bool enabled = true}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFE8F5E9) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF2E7D32).withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 20,
              color: enabled ? const Color(0xFF2E7D32) : Colors.grey[400]),
        ),
      ),
    );
  }
}

// Small pulsing dot used in "Updating..." badge
class _PulsingDot extends StatefulWidget {
  final double size;
  final Color color;
  const _PulsingDot({required this.size, required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.7, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: widget.color.withOpacity(0.7),
                blurRadius: 8,
                spreadRadius: 2)
          ],
        ),
      ),
    );
  }
}
