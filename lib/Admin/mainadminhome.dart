import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gcc/Admin/Uploadfood.dart';
import 'package:gcc/utils/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'EditFood.dart';

class MainAdminHome extends StatefulWidget {
  const MainAdminHome({super.key});

  @override
  State<MainAdminHome> createState() => _MainAdminHomeState();
}

class _MainAdminHomeState extends State<MainAdminHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List _orderRequestList = [];

  // Premium color palette
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color lightGreen = Color(0xFFC8E6C9);
  static const Color veryLightGreen = Color(0xFFF1F8E9);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textDark = Color(0xFF1B1B1B);
  static const Color textMuted = Color(0xFF757575);

  Future<void> getorderrequests() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;

    try {
      QuerySnapshot<Map<String, dynamic>> data =
          await _firestore.collection('Menu').get();
      setState(() {
        _orderRequestList = data.docs;
      });
    } catch (e) {
      print('Error fetching orders data: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
    DefaultCacheManager().emptyCache();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      floatingActionButton: Container(
        width: 100,
        child: FloatingActionButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40.0),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UploadFood()),
            );
          },
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 18),
                child: Icon(Icons.add),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 4,
                ),
                child: Text(
                  "New",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                  ),
                ),
              )
            ],
          ),
          backgroundColor: HexColor('#242424'),
          foregroundColor: Colors.white,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder(
                stream: getorderrequests().asStream(),
                builder: (context, snapshot) {
                  if (_orderRequestList.isEmpty &&
                      (snapshot.connectionState == ConnectionState.waiting ||
                          snapshot.connectionState == ConnectionState.active)) {
                    return _buildAnimatedLoader();
                  }
                  return _orderRequestList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          itemCount: _orderRequestList.length,
                          itemBuilder: (context, index) {
                            var item = _orderRequestList[index];
                            return _buildInventoryCard(item, context);
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryGreen,
            accentGreen,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Inventory',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Manage and organize your menu items',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        primaryGreen.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 6.28,
                          child: child,
                        );
                      },
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: veryLightGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: primaryGreen,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Loading Inventory',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching your menu items...',
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  veryLightGreen,
                  lightGreen.withOpacity(0.5),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'No Items Yet',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start by adding your first menu item',
            style: TextStyle(
              fontSize: 16,
              color: textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(dynamic item, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: lightGreen.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditFood(snapshot: item),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: primaryGreen.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageContainer(item),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _buildItemHeader(item),
                    ),
                    _buildActionMenu(item, context),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDescription(item),
                const SizedBox(height: 18),
                _buildStatsRow(item),
                const SizedBox(height: 16),
                _buildDetailsRow(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContainer(dynamic item) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: veryLightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lightGreen.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: item['Images'] != null && item['Images'].isNotEmpty
          ? CachedNetworkImage(
              imageUrl: item['Images'][0],
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => const Icon(
                  Icons.image_not_supported,
                  color: primaryGreen,
                  size: 44),
              key: UniqueKey(),
            )
          : const Icon(Icons.image_not_supported,
              color: primaryGreen, size: 44),
    );
  }

  Widget _buildItemHeader(dynamic item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['Product Name'] ?? 'No Name',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textDark,
            height: 1.2,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, accentGreen],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '₹${item['Price'] ?? '0'}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: veryLightGreen,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: lightGreen.withOpacity(0.7), width: 1.5),
              ),
              child: Text(
                item['Product Category'] ?? 'Uncategorized',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: darkGreen,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildRatingBadge(item),
      ],
    );
  }

  Widget _buildRatingBadge(dynamic item) {
    final totalRating = item['Total Rating'] ?? 0;
    final ratingCount = item['Rating Count'] ?? 0;
    final avgRating = ratingCount > 0
        ? (totalRating / ratingCount).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFE082).withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFA500)),
          const SizedBox(width: 6),
          Text(
            '$avgRating',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '($ratingCount)',
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(dynamic item) {
    final description = item['Product Description'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(dynamic item) {
    final availableQty = item['Available Quantity'] ?? '0';
    final size = item['Size'] ?? 'N/A';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Available',
            value: availableQty.toString(),
            color: primaryGreen,
            backgroundColor: veryLightGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.straighten,
            label: 'Size',
            value: size.toString(),
            color: const Color(0xFF2196F3),
            backgroundColor: const Color(0xFFE3F2FD),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsRow(dynamic item) {
    final userEmail = item['User Email'] ?? 'No email';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.email_outlined, size: 20, color: textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              userEmail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu(dynamic item, BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_rounded, size: 20, color: primaryGreen),
              const SizedBox(width: 12),
              const Text('Edit Details',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 10),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 20, color: Colors.red[500]),
              const SizedBox(width: 12),
              Text('Delete',
                  style: TextStyle(
                      color: Colors.red[500],
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditFood(snapshot: item),
            ),
          );
        } else if (value == 'delete') {
          _showDeleteDialog(context, item);
        }
      },
      icon: const Icon(Icons.more_vert_rounded, size: 26, color: darkGreen),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(-10, 40),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Delete Item',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: darkGreen,
              letterSpacing: -0.5,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${item['Product Name']}"? This action cannot be undone.',
            style: TextStyle(
              color: textMuted,
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                _firestore.collection('Menu').doc(item.id).delete();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[500],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 4,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}
