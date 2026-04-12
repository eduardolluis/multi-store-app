import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SuppOrderModel extends StatefulWidget {
  final QueryDocumentSnapshot orderDoc;
  final String userId;

  const SuppOrderModel({super.key, required this.orderDoc, required this.userId});

  @override
  State<SuppOrderModel> createState() => _SuppOrderModelState();
}

class _SuppOrderModelState extends State<SuppOrderModel> {
  static const List<String> _statusOptions = [
    'pending',
    'preparing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  late String _selectedStatus;
  bool _isUpdatingStatus = false;

  Map<String, dynamic> get _data => widget.orderDoc.data() as Map<String, dynamic>;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _normalizeStatus(
      _readString(
        _firstExistingValue(['deliverystatus', 'deliveryStatus', 'status', 'orderStatus']),
        'pending',
      ),
    );
  }

  dynamic _firstExistingValue(List<String> keys) {
    for (final key in keys) {
      if (_data.containsKey(key) && _data[key] != null) {
        return _data[key];
      }
    }
    return null;
  }

  String _readString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double _readDouble(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  int _readInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  DateTime? _readDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
  }

  String _normalizeStatus(String value) {
    final normalized = value.trim().toLowerCase();
    if (_statusOptions.contains(normalized)) {
      return normalized;
    }
    return 'pending';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Color _statusColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'delivered':
        return const Color(0xFF1FA971);
      case 'shipped':
        return const Color(0xFF2F80ED);
      case 'preparing':
        return const Color(0xFFF2994A);
      case 'pending':
        return const Color(0xFFE67E22);
      case 'cancelled':
        return const Color(0xFFEB5757);
      default:
        return const Color(0xFF7F56D9);
    }
  }

  IconData _statusIcon(String status) {
    switch (_normalizeStatus(status)) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'preparing':
        return Icons.inventory_2_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  Future<void> _saveStatus() async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderDoc.id).update({
        'deliverystatus': _selectedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Order status updated successfully');
    } catch (e) {
      _showSnackBar('Failed to update order status');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final orderName = _readString(
      _firstExistingValue(['ordername', 'orderName', 'productName', 'name']),
      'Unknown product',
    );

    final orderImage = _readString(
      _firstExistingValue(['orderImage', 'orderimage', 'productImage', 'image']),
      '',
    );

    final status = _normalizeStatus(
      _readString(
        _firstExistingValue(['deliverystatus', 'deliveryStatus', 'status', 'orderStatus']),
        _selectedStatus,
      ),
    );

    final price = _readDouble(_firstExistingValue(['orderprice', 'orderPrice', 'price']));

    final qty = _readInt(_firstExistingValue(['orderqty', 'orderQty', 'qty', 'quantity']), 1);

    final safeQty = qty <= 0 ? 1 : qty;
    final total = price * safeQty;

    final productId = _readString(_firstExistingValue(['productid', 'productId']), 'N/A');

    final customerName = _readString(
      _firstExistingValue(['customerName', 'customername', 'buyerName', 'fullName']),
      'Unknown customer',
    );

    final customerId = _readString(_firstExistingValue(['cid', 'customerId', 'buyerId']), 'N/A');

    final customerEmail = _readString(
      _firstExistingValue(['customerEmail', 'buyerEmail', 'email']),
      'Not available',
    );

    final customerPhone = _readString(
      _firstExistingValue(['customerPhone', 'phone', 'buyerPhone']),
      'Not available',
    );

    final shippingAddress = _readString(
      _firstExistingValue(['address', 'customerAddress', 'shippingAddress', 'fullAddress']),
      'Not available',
    );

    final paymentStatus = _readString(
      _firstExistingValue(['paymentStatus', 'paymentstatus']),
      'Not available',
    );

    final orderDate = _formatDate(
      _readDate(_firstExistingValue(['orderDate', 'createdAt', 'date', 'timestamp'])),
    );

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 64,
              height: 64,
              color: const Color(0xFFF1F3F7),
              child: orderImage.isEmpty
                  ? const Icon(Icons.image_outlined, color: Colors.grey)
                  : Image.network(
                      orderImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, color: Colors.grey),
                    ),
            ),
          ),
          title: Text(
            orderName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SoftChip(icon: Icons.person_outline_rounded, label: customerName),
                _SoftChip(icon: Icons.shopping_bag_outlined, label: 'Qty: $safeQty'),
                _SoftChip(icon: Icons.attach_money_rounded, label: total.toStringAsFixed(2)),
                _StatusChip(
                  label: _capitalize(status),
                  color: statusColor,
                  icon: _statusIcon(status),
                ),
              ],
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.receipt_long_rounded,
                    title: 'Order Information',
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoBox(title: 'Order ID', value: widget.orderDoc.id),
                      _InfoBox(title: 'Product ID', value: productId),
                      _InfoBox(title: 'Product', value: orderName),
                      _InfoBox(title: 'Unit Price', value: '\$${price.toStringAsFixed(2)}'),
                      _InfoBox(title: 'Quantity', value: safeQty.toString()),
                      _InfoBox(title: 'Total', value: '\$${total.toStringAsFixed(2)}'),
                      _InfoBox(title: 'Payment', value: paymentStatus),
                      _InfoBox(title: 'Date', value: orderDate),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeader(icon: Icons.person_rounded, title: 'Customer Information'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoBox(title: 'Customer', value: customerName),
                      _InfoBox(title: 'Customer ID', value: customerId),
                      _InfoBox(title: 'Email', value: customerEmail),
                      _InfoBox(title: 'Phone', value: customerPhone),
                      _InfoBox(title: 'Address', value: shippingAddress),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeader(
                    icon: Icons.local_shipping_rounded,
                    title: 'Update Delivery Status',
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    items: _statusOptions.map((statusValue) {
                      return DropdownMenuItem<String>(
                        value: statusValue,
                        child: Text(_capitalize(statusValue)),
                      );
                    }).toList(),
                    onChanged: _isUpdatingStatus
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedStatus = value;
                            });
                          },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: statusColor, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickStatusButton(
                        label: 'Pending',
                        selected: _selectedStatus == 'pending',
                        color: _statusColor('pending'),
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'pending';
                          });
                        },
                      ),
                      _QuickStatusButton(
                        label: 'Preparing',
                        selected: _selectedStatus == 'preparing',
                        color: _statusColor('preparing'),
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'preparing';
                          });
                        },
                      ),
                      _QuickStatusButton(
                        label: 'Shipped',
                        selected: _selectedStatus == 'shipped',
                        color: _statusColor('shipped'),
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'shipped';
                          });
                        },
                      ),
                      _QuickStatusButton(
                        label: 'Delivered',
                        selected: _selectedStatus == 'delivered',
                        color: _statusColor('delivered'),
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'delivered';
                          });
                        },
                      ),
                      _QuickStatusButton(
                        label: 'Cancelled',
                        selected: _selectedStatus == 'cancelled',
                        color: _statusColor('cancelled'),
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'cancelled';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUpdatingStatus ? null : _saveStatus,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: _isUpdatingStatus
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isUpdatingStatus ? 'Updating...' : 'Save Status',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SoftChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF4B5563)),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF111827)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _InfoBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145, maxWidth: 240),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatusButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _QuickStatusButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.14) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? color : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class EmptySupplierOrdersView extends StatelessWidget {
  const EmptySupplierOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inventory_2_outlined, size: 82, color: Color(0xFF9CA3AF)),
            SizedBox(height: 14),
            Text(
              'No supplier orders yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF374151)),
            ),
            SizedBox(height: 8),
            Text(
              'Incoming customer orders will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
