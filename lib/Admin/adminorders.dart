import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  List<DocumentSnapshot> _requestList = [];
  List<DocumentSnapshot> _filteredOrderList = [];

  final TextEditingController _searchController = TextEditingController();

  bool loading = false;

  final Map<String, String> _statusMap = {};

  // ----------------------------
  // COLORS
  // ----------------------------
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color lightGreen = Color(0xFFC8E6C9);
  static const Color veryLightGreen = Color(0xFFF1F8E9);
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

    _getOrders();
    _getOrderRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    DefaultCacheManager().emptyCache();
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // FETCH ORDERS
  // ----------------------------------------------------------------------

  Future<void> _getOrders() async {
    try {
      final data = await _firestore
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
      debugPrint("Error loading orders: $e");
    }
  }

  // ----------------------------------------------------------------------
  // FETCH REQUESTS
  // ----------------------------------------------------------------------

  Future<void> _getOrderRequests() async {
    try {
      final data = await _firestore
          .collection('Order_Requests')
          .orderBy('orderDate', descending: true)
          .get();

      setState(() {
        _requestList = data.docs;
      });
    } catch (e) {
      debugPrint("Error loading requests: $e");
    }
  }

  // ----------------------------------------------------------------------
  // SEARCH
  // ----------------------------------------------------------------------

  void _searchOrders(String query) {
    setState(() {
      _filteredOrderList = _orderList.where((order) {
        return order['OrderId'].toString().contains(query);
      }).toList();
    });
  }

  // ----------------------------------------------------------------------
  // STATUS COLOR
  // ----------------------------------------------------------------------

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.blue;
      case 'Preparing':
        return Colors.orange;
      case 'Out For Delivery':
        return Colors.purple;
      case 'Delivered':
        return primaryGreen;
      default:
        return textMuted;
    }
  }

  // ----------------------------------------------------------------------
  // MAIN UI
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: veryLightGreen,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersTab(),
                  _buildRequestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // HEADER
  // ----------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade900, primaryGreen],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Management",
            style: TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Manage orders and requests",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // TAB BAR
  // ----------------------------------------------------------------------

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryGreen,
        unselectedLabelColor: textMuted,
        indicatorColor: primaryGreen,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_rounded, size: 18),
                const SizedBox(width: 6),
                const Text("Orders"),
              ],
            ),
          ),

          /// REQUESTS TAB WITH BADGE
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pending_actions, size: 18),
                const SizedBox(width: 6),
                const Text("Requests"),
                if (_requestList.isNotEmpty)
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
                      _requestList.length.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  // ----------------------------------------------------------------------
  // ORDERS TAB
  // ----------------------------------------------------------------------

  Widget _buildOrdersTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _filteredOrderList.isEmpty
              ? _buildEmptyState("No Orders Found")
              : RefreshIndicator(
                  onRefresh: () => _getOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _filteredOrderList.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_filteredOrderList[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // ORDER REQUESTS TAB
  // ----------------------------------------------------------------------

  Widget _buildRequestsTab() {
    return _requestList.isEmpty
        ? _buildEmptyState("No Order Requests")
        : RefreshIndicator(
            onRefresh: () => _getOrderRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _requestList.length,
              itemBuilder: (context, index) {
                return _buildRequestCard(_requestList[index]);
              },
            ),
          );
  }

  // ----------------------------------------------------------------------
  // SEARCH BAR
  // ----------------------------------------------------------------------

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _searchOrders,
          decoration: const InputDecoration(
            hintText: "Search by Order ID...",
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // EMPTY STATE
  // ----------------------------------------------------------------------

  Widget _buildEmptyState(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: textMuted,
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // ORDER CARD (unchanged except status flow)
  // ----------------------------------------------------------------------

  Widget _buildOrderCard(DocumentSnapshot item) {
    var orderDate = (item['orderDate'] as Timestamp).toDate();
    var formattedDate = DateFormat('dd MMM, hh:mm a').format(orderDate);

    String status = item['Status'];
    Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // IMAGE
              _buildOrderImage(item),

              const SizedBox(width: 14),

              // DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["Item Name"] ?? "No Name",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text("Order ID: ${item['OrderId']}"),
                    Text(formattedDate, style: TextStyle(color: textMuted)),
                  ],
                ),
              ),

              // PRICE
              Text(
                "₹${item["Price"]}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // STATUS
          _buildStatusDropdown(item),
        ],
      ),
    );
  }

  Widget _buildOrderImage(DocumentSnapshot item) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: veryLightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: item['Images'] != null
          ? CachedNetworkImage(imageUrl: item['Images'][0], fit: BoxFit.cover)
          : const Icon(Icons.image_not_supported),
    );
  }

  // ----------------------------------------------------------------------
  // UPDATED STATUS FLOW
  // Pending → Accepted → Preparing → Out For Delivery → Delivered
  // ----------------------------------------------------------------------

  Widget _buildStatusDropdown(DocumentSnapshot item) {
    String current = item["Status"];

    List<String> flow = [
      "Pending",
      "Accepted",
      "Preparing",
      "Out For Delivery",
      "Delivered"
    ];

    String next = current;

    if (current != "Delivered") {
      int index = flow.indexOf(current);
      if (index != -1 && index < flow.length - 1) {
        next = flow[index + 1];
      }
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: veryLightGreen,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              next,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildUpdateButton(item, next),
      ],
    );
  }

  Widget _buildUpdateButton(DocumentSnapshot item, String nextStatus) {
    return GestureDetector(
      onTap: () async {
        setState(() => loading = true);

        await _firestore.collection("Orders").doc(item.id).update({
          "status": nextStatus,
        });
        await _firestore
            .collection("Users")
            .doc(item["userEmail"])
            .collection("orders")
            .doc(item.id)
            .update({"status": nextStatus});

        await _getOrders();

        setState(() => loading = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryGreen, accentGreen]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          "Update",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // REQUEST CARD (unchanged)
  // ----------------------------------------------------------------------

  Widget _buildRequestCard(DocumentSnapshot item) {
    var orderDate = (item['orderDate'] as Timestamp).toDate();
    var formattedDate = DateFormat('dd MMM, hh:mm a').format(orderDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildOrderImage(item),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item["Item Name"],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Qty: ${item['quantity']} × ₹${item["Price"]}"),
                    Text(formattedDate, style: TextStyle(color: textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildRejectButton(item)),
              const SizedBox(width: 12),
              Expanded(child: _buildAcceptButton(item)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRejectButton(DocumentSnapshot item) {
    return GestureDetector(
      onTap: () async {
        _rejectOrder(item);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Center(
          child: Text("Reject",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildAcceptButton(DocumentSnapshot item) {
    return GestureDetector(
      onTap: () async {
        _acceptOrder(item);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryGreen, accentGreen]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text("Accept",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _acceptOrder(DocumentSnapshot item) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    try {
      await _firestore.collection('Orders').add({
        "orderId": item.id,
        "userEmail": user?.email,
        "createdAt": FieldValue.serverTimestamp(),
        "subTotal": item["subtotal"],
        "deliveryCharge": item['deliveryCharge'],
        "total": item["total"],
        "status": "Accepted",
        "items": item["items"].map((item) {
          return {
            "productId": item.productId,
            "name": item.name,
            "price": item.price,
            "quantity": item.quantity,
            "size": item.size,
            "imageUrl": item.imageUrl,
          };
        }).toList(),
      });
      await _firestore
          .collection("Users")
          .doc(item["userEmail"])
          .collection("orders")
          .doc(item.id)
          .update({"status": "Accepted"});
      await _firestore.collection('Order_Requests').doc(item.id).delete();

      await _getOrders();
      await _getOrderRequests();
    } catch (e) {
      print('Error accepting order: $e');
    }
  }

  Future<void> _rejectOrder(DocumentSnapshot item) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    try {
      await _firestore.collection('Order_Requests').doc(item.id).update({
        "status": "Rejected",
      });
      await _firestore
          .collection("Users")
          .doc(item["userEmail"])
          .collection("orders")
          .doc(item.id)
          .update({"status": "Rejected"});
      await _getOrderRequests();
    } catch (e) {
      print('Error rejecting order: $e');
    }
  }
}
