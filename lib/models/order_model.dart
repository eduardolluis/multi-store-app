import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatefulWidget {
  final QueryDocumentSnapshot orderDoc;
  final String userId;

  const OrderCard({super.key, required this.orderDoc, required this.userId});

  @override
  State<OrderCard> createState() => OrderCardState();
}

class OrderCardState extends State<OrderCard> {
  final TextEditingController _reviewController = TextEditingController();

  bool _isLoadingReview = true;
  bool _isSubmitting = false;
  bool _hasReview = false;
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _data => widget.orderDoc.data() as Map<String, dynamic>;

  String _readString(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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
    switch (status.toLowerCase()) {
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

  Future<void> _loadReview() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.orderDoc.id)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _reviewController.text = (data['reviewText'] ?? '').toString();

        final ratingValue = data['rating'];
        if (ratingValue is num) {
          _rating = ratingValue.toInt();
        } else {
          _rating = int.tryParse(ratingValue.toString()) ?? 0;
        }

        _hasReview = true;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingReview = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      _showSnackBar('Please select a rating');
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      _showSnackBar('Please write a review');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('reviews').doc(widget.orderDoc.id).set({
        'orderId': widget.orderDoc.id,
        'cid': widget.userId,
        'productId': _data['productid'],
        'productName': _readString(_data['ordername'], 'Unknown product'),
        'productImage': _readString(_data['orderImage'], ''),
        'rating': _rating,
        'reviewText': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _hasReview = true;
      });

      _showSnackBar('Review saved successfully');
    } catch (_) {
      _showSnackBar('Failed to save review');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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
    final orderName = _readString(_data['ordername'], 'Unknown product');
    final orderImage = _readString(_data['orderImage'], '');
    final status = _readString(_data['deliverystatus'], 'Pending');
    final price = _readDouble(_data['orderprice']);
    final qty = _readInt(_data['orderqty']);
    final statusColor = _statusColor(status);

    return Container(
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
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
                _SoftChip(icon: Icons.attach_money_rounded, label: price.toStringAsFixed(2)),
                _SoftChip(icon: Icons.shopping_bag_outlined, label: 'Qty: $qty'),
                _StatusChip(label: status, color: statusColor, icon: _statusIcon(status)),
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
                      _InfoBox(title: 'Product', value: orderName),
                      _InfoBox(title: 'Price', value: '\$${price.toStringAsFixed(2)}'),
                      _InfoBox(title: 'Quantity', value: qty.toString()),
                      _InfoBox(title: 'Status', value: status),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeader(icon: Icons.rate_review_rounded, title: 'Write a Review'),
                  const SizedBox(height: 12),
                  _StarSelector(
                    currentRating: _rating,
                    onChanged: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _isLoadingReview
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : TextField(
                          controller: _reviewController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Share your experience with this product...',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
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
                              borderSide: const BorderSide(color: Color(0xFFF4B400), width: 1.4),
                            ),
                          ),
                        ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting || _isLoadingReview ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(_hasReview ? Icons.edit_rounded : Icons.send_rounded),
                      label: Text(
                        _isSubmitting
                            ? 'Saving...'
                            : _hasReview
                            ? 'Update Review'
                            : 'Submit Review',
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
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
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
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
            maxLines: 3,
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

class _StarSelector extends StatelessWidget {
  final int currentRating;
  final ValueChanged<int> onChanged;

  const _StarSelector({required this.currentRating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = value <= currentRating;

        return IconButton(
          onPressed: () => onChanged(value),
          splashRadius: 22,
          icon: Icon(
            selected ? Icons.star_rounded : Icons.star_border_rounded,
            color: selected ? const Color(0xFFF4B400) : const Color(0xFF9CA3AF),
            size: 32,
          ),
        );
      }),
    );
  }
}

class EmptyOrdersView extends StatelessWidget {
  const EmptyOrdersView();

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
            Icon(Icons.shopping_bag_outlined, size: 82, color: Color(0xFF9CA3AF)),
            SizedBox(height: 14),
            Text(
              'You have no active orders',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF374151)),
            ),
            SizedBox(height: 8),
            Text(
              'Your current orders will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
