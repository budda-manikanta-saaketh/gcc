import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final String orderId = orderData['orderId']?.toString() ?? '—';
    final String status = orderData['status']?.toString() ?? 'Pending';
    final total = orderData['total'] ?? 0;
    final subtotal = (orderData['subtotal'] ?? total).toDouble();
    final shipping = (orderData['deliveryCharge'] ?? 0).toDouble();
    final totalAmount = (orderData['total'] ?? 0).toDouble();

    final String dateLabel =
        _formatOrderDate(orderData['createdAt'] ?? orderData['date']);
    final items = orderData['items'] as List? ?? [];

    // Delivery/shipping address
    final shippingAddress =
        orderData['shippingAddress'] as Map<String, dynamic>?;
    final paymentMethod =
        orderData['paymentMethod']?.toString() ?? 'Not specified';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Order Details",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Order Status Header
            _buildOrderStatusHeader(context, orderId, status, dateLabel),

            const SizedBox(height: 12),

            // Order Timeline/Progress
            _buildOrderTimeline(context, status),

            const SizedBox(height: 12),

            // Items List
            _buildItemsSection(context, items),

            const SizedBox(height: 12),

            // Shipping Address
            if (shippingAddress != null)
              _buildShippingAddressSection(context, shippingAddress),

            const SizedBox(height: 12),

            // Payment Summary
            _buildPaymentSummary(
                context, subtotal, shipping, totalAmount, paymentMethod),

            const SizedBox(height: 12),

            // Action Buttons
            _buildActionButtons(context, status),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusHeader(
      BuildContext context, String orderId, String status, String date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Status Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(status),
              size: 48,
              color: _statusColor(status),
            ),
          ),
          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor(status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Order ID
          Text(
            "Order #$orderId",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          // Date
          Text(
            "Placed on $date",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(BuildContext context, String status) {
    final steps = [
      {'title': 'Pending', 'icon': Icons.hourglass_empty},
      {'title': 'Accepted', 'icon': Icons.check_circle_outline},
      {'title': 'Shipped', 'icon': Icons.local_shipping},
      {'title': 'Out For Delivery', 'icon': Icons.delivery_dining},
      {'title': 'Delivered', 'icon': Icons.check_circle},
    ];

    // Normalize status
    final s = status.toLowerCase();

    int currentStep = 0;
    if (s == 'pending') currentStep = 0;
    if (s == 'accepted') currentStep = 1;
    if (s == 'shipped') currentStep = 2;
    if (s == 'out for delivery') currentStep = 3;
    if (s == 'delivered') currentStep = 4;
    if (s == 'cancelled') currentStep = -1;

    // CANCELLED UI
    if (currentStep == -1) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red[700], size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Order Cancelled",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "This order has been cancelled",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // NORMAL TIMELINE UI
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Progress",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(steps.length, (index) {
              final isCompleted = index <= currentStep;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              steps[index]['icon'] as IconData,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 70, // <- fixed width to prevent shifting
                            child: Text(
                              steps[index]['title'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCompleted
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isCompleted
                                    ? Colors.black87
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 30),
                          color: index < currentStep
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, List items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Order Items",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${items.length} item${items.length > 1 ? 's' : ''}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;

            return _buildOrderItem(context, item, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, dynamic item, bool isLast) {
    String name = "Product";
    String? imageUrl;
    int quantity = 1;
    double price = 0;

    if (item is Map) {
      name = item['name']?.toString() ?? "Product";
      imageUrl = (item['image'] ?? item['imageUrl'] ?? item['img'])?.toString();
      quantity = item['quantity'] ?? 1;
      price = (item['price'] ?? 0).toDouble();
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image_outlined,
                              color: Colors.grey[400], size: 30);
                        },
                      )
                    : Icon(Icons.image_outlined,
                        color: Colors.grey[400], size: 30),
              ),
            ),

            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Qty: $quantity",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₹${price.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildShippingAddressSection(
      BuildContext context, Map<String, dynamic> address) {
    final name = address['name']?.toString() ?? '';
    final street =
        address['street']?.toString() ?? address['address']?.toString() ?? '';
    final city = address['city']?.toString() ?? '';
    final state = address['state']?.toString() ?? '';
    final zip =
        address['zip']?.toString() ?? address['zipCode']?.toString() ?? '';
    final phone = address['phone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.location_on, color: Colors.green[700], size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Shipping Address",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (name.isNotEmpty) ...[
            Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (street.isNotEmpty) ...[
            Text(
              street,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
          ],
          if (city.isNotEmpty || state.isNotEmpty || zip.isNotEmpty) ...[
            Text(
              [city, state, zip].where((s) => s.isNotEmpty).join(', '),
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
          ],
          if (phone.isNotEmpty)
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  phone,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context, double subtotal,
      double shipping, double total, String paymentMethod) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.receipt_long, color: Colors.blue[700], size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Payment Summary",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow("Subtotal", subtotal, false),
          const SizedBox(height: 12),
          _buildSummaryRow("Shipping", shipping, false),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[300], height: 1, thickness: 1),
          const SizedBox(height: 16),
          _buildSummaryRow("Total", total, true),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, color: Colors.grey[700], size: 20),
                const SizedBox(width: 10),
                Text(
                  "Payment: ",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  paymentMethod,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.black87 : Colors.grey[700],
          ),
        ),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Colors.black87 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, String status) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (status.toLowerCase() != 'cancelled' &&
              status.toLowerCase() != 'delivered') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showCancelDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Cancel Order",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Contact support
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              icon: const Icon(Icons.support_agent),
              label: const Text(
                "Contact Support",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Cancel Order?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to cancel this order? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "No, Keep Order",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement order cancellation
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Order cancelled successfully"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatOrderDate(dynamic createdAt) {
    try {
      DateTime dt;
      if (createdAt == null) return '';
      if (createdAt is Timestamp) {
        dt = createdAt.toDate();
      } else if (createdAt is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
      } else if (createdAt is String) {
        final parsed = DateTime.tryParse(createdAt);
        dt = parsed ?? DateTime.now();
      } else if (createdAt is DateTime) {
        dt = createdAt;
      } else {
        dt = DateTime.now();
      }
      return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "delivered":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      case "shipped":
        return Colors.blue;
      case "processing":
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case "delivered":
        return Icons.check_circle;
      case "cancelled":
        return Icons.cancel;
      case "shipped":
        return Icons.local_shipping;
      case "processing":
        return Icons.inventory_2;
      default:
        return Icons.schedule;
    }
  }
}
