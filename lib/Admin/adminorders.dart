import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';

class AdminOrdersPage extends StatefulWidget {
  final int initialTab;

  const AdminOrdersPage({super.key, this.initialTab = 0});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  List<DocumentSnapshot> _orderList = [];
  List<DocumentSnapshot> _orderRequestList = [];
  List<DocumentSnapshot> _filteredOrderList = [];
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _statusMap = {};
  bool loading = false;

  // Color palette
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color lightGreen = Color(0xFFC8E6C9);
  static const Color veryLightGreen = Color(0xFFF1F8E9);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color textDark = Color(0xFF1B1B1B);
  static const Color textMuted = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    getOrders();
    getOrderRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    DefaultCacheManager().emptyCache();
    super.dispose();
  }

  Future<void> getOrders() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    try {
      QuerySnapshot<Map<String, dynamic>> data = await _firestore
          .collection('Orders')
          .orderBy('orderDate', descending: true)
          .get();
      setState(() {
        _orderList = data.docs;
        _filteredOrderList = _orderList;
        for (var doc in _orderList) {
          _statusMap[doc.id] = doc['Status'];
        }
      });
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  Future<void> getOrderRequests() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    try {
      QuerySnapshot<Map<String, dynamic>> data = await _firestore
          .collection('Order_Requests')
          .orderBy('orderDate', descending: true)
          .get();
      setState(() {
        _orderRequestList = data.docs;
      });
    } catch (e) {
      print('Error fetching Order_Requests: $e');
    }
  }

  void _searchOrders(String query) {
    setState(() {
      _filteredOrderList = _orderList.where((order) {
        return order['OrderId'].toString().contains(query);
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return const Color(0xFF2196F3);
      case 'Preparing':
        return const Color(0xFFFFA500);
      case 'Out For Delivery':
        return const Color(0xFF9C27B0);
      case 'Delivered':
        return primaryGreen;
      default:
        return textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 160,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: surfaceColor,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryGreen, accentGreen],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Management',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track orders and requests',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Container(
                    color: surfaceColor,
                    child: TabBar(
                      controller: _tabController,
                      onTap: (_) {
                        setState(() {});
                      },
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_bag_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Orders',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pending_actions_rounded,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Requests',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (_orderRequestList.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _orderRequestList.length.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      labelColor: primaryGreen,
                      unselectedLabelColor: textMuted,
                      indicatorColor: primaryGreen,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersTab(),
              _buildRequestsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: lightGreen.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _searchOrders,
              decoration: InputDecoration(
                hintText: 'Search by Order ID...',
                hintStyle: TextStyle(
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: textMuted,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                )
              : _filteredOrderList.isEmpty
                  ? _buildEmptyState('No Orders', 'Orders will appear here')
                  : RefreshIndicator(
                      onRefresh: () async => await getOrders(),
                      color: primaryGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: _filteredOrderList.length,
                        itemBuilder: (context, index) {
                          var item = _filteredOrderList[index];
                          return _buildOrderCard(item);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    return _orderRequestList.isEmpty
        ? _buildEmptyState('No Requests', 'New Order_Requests will appear here')
        : RefreshIndicator(
            onRefresh: () async => await getOrderRequests(),
            color: primaryGreen,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _orderRequestList.length,
              itemBuilder: (context, index) {
                var item = _orderRequestList[index];
                return _buildRequestCard(item);
              },
            ),
          );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: textMuted.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot item) {
    var orderDate = (item['orderDate'] as Timestamp).toDate();
    var formattedDate = DateFormat('dd MMM, hh:mm a').format(orderDate);
    var itemId = item.id;
    var status = _statusMap[itemId] ?? item['Status'];
    var statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: veryLightGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: lightGreen.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item['Images'] != null && item['Images'].isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item['Images'][0],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.image_not_supported,
                            color: primaryGreen,
                          ),
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          color: primaryGreen,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['Item Name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Order ID: ${item['OrderId']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item['Price'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primaryGreen,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${item['quantity']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (status != 'Delivered') ...[
            Divider(
              color: lightGreen.withOpacity(0.3),
              thickness: 1,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatusDropdown(item, itemId, status),
                  ),
                  const SizedBox(width: 12),
                  _buildUpdateButton(item, itemId),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestCard(DocumentSnapshot item) {
    var orderDate = (item['orderDate'] as Timestamp).toDate();
    var formattedDate = DateFormat('dd MMM, hh:mm a').format(orderDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFA500).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA500).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: veryLightGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: lightGreen.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item['Images'] != null && item['Images'].isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item['Images'][0],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryGreen,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.image_not_supported,
                            color: primaryGreen,
                          ),
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          color: primaryGreen,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['Item Name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Qty: ${item['quantity']} × ₹${item['Price']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: lightGreen.withOpacity(0.3),
            thickness: 1,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => loading = true);
                      await _rejectOrder(item);
                      setState(() => loading = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.red,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => loading = true);
                      await _acceptOrder(item);
                      setState(() => loading = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      child: const Center(
                        child: Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(
    DocumentSnapshot item,
    String itemId,
    String currentStatus,
  ) {
    String nextStatus = currentStatus == 'Accepted'
        ? 'Preparing'
        : currentStatus == 'Preparing'
            ? 'Out For Delivery'
            : currentStatus == 'Out For Delivery'
                ? 'Delivered'
                : currentStatus;

    return Container(
      decoration: BoxDecoration(
        color: veryLightGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: lightGreen.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DropdownButton<String>(
        underline: const SizedBox(),
        isDense: true,
        isExpanded: true,
        value: nextStatus,
        items: [
          DropdownMenuItem<String>(
            value: nextStatus,
            child: Text(
              nextStatus,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkGreen,
              ),
            ),
          ),
        ],
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _statusMap[itemId] = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildUpdateButton(DocumentSnapshot item, String itemId) {
    return GestureDetector(
      onTap: () async {
        final FirebaseAuth auth = FirebaseAuth.instance;
        User? user = auth.currentUser;
        setState(() => loading = true);

        await _firestore
            .collection('Orders')
            .doc(itemId)
            .update({'Status': _statusMap[itemId]});

        final userdoc = await _firestore
            .collection('Orders')
            .where('OrderId', isEqualTo: item['OrderId'])
            .get();

        for (var doc in userdoc.docs) {
          await _firestore
              .collection('Orders')
              .doc(doc.id)
              .update({'Status': _statusMap[itemId]});
        }

        await getOrders();
        setState(() => loading = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        child: const Text(
          'Update',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Future<void> _acceptOrder(DocumentSnapshot item) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    try {
      await _firestore
          .collection('Order_Requests')
          .doc(item.id)
          .update({'Status': 'Accepted'});

      await _firestore.collection('Orders').add({
        'OrderId': item['OrderId'],
        'Images': item['Images'],
        'Item Name': item['Item Name'],
        'Item Category': item['Item Category'],
        'Price': item['Price'],
        'quantity': item['quantity'],
        'orderDate': Timestamp.now(),
        'Status': 'Accepted',
        'Item Description': item['Item Description'],
        'Type': item['Type'],
        'Address': item['Address'],
        'Paid Via': item['Paid via'],
        'Phone': item['Phone'],
        'Email': item['Email']
      });

      await _firestore.collection('Order_Requests').doc(item.id).delete();

      final userorder = await _firestore
          .collection('Orders')
          .where('OrderId', isEqualTo: item['OrderId'])
          .get();

      await _firestore
          .collection('Orders')
          .doc(userorder.docs[0].id)
          .update({'Status': 'Accepted'});

      await getOrders();
      await getOrderRequests();
    } catch (e) {
      print('Error accepting order: $e');
    }
  }

  Future<void> _rejectOrder(DocumentSnapshot item) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    try {
      await _firestore.collection('Order_Requests').doc(item.id).delete();

      await getOrderRequests();
    } catch (e) {
      print('Error rejecting order: $e');
    }
  }
}
