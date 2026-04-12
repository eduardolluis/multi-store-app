import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/order_widget.dart';

class OrderCard extends StatefulWidget {
  final QueryDocumentSnapshot orderDoc;
  final String userId;
  const OrderCard({super.key, required this.orderDoc, required this.userId});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final _reviewController = TextEditingController();
  bool _loadingReview = true;
  bool _submitting = false;
  bool _hasReview = false;
  int _rating = 0;

  Map<String, dynamic> get _data => widget.orderDoc.data() as Map<String, dynamic>;

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

  Future<void> _loadReview() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.orderDoc.id)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _reviewController.text = (data['reviewText'] ?? '').toString();
        final r = data['rating'];
        _rating = r is num ? r.toInt() : int.tryParse(r.toString()) ?? 0;
        _hasReview = true;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingReview = false);
  }

  Future<void> _submitReview() async {
    if (_rating == 0) return _snack('Please select a rating');
    if (_reviewController.text.trim().isEmpty) return _snack('Please write a review');

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('reviews').doc(widget.orderDoc.id).set({
        'orderId': widget.orderDoc.id,
        'cid': widget.userId,
        'productId': _data['productid'],
        'productName': (_data['ordername'] ?? 'Unknown').toString(),
        'productImage': (_data['orderImage'] ?? '').toString(),
        'rating': _rating,
        'reviewText': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _hasReview = true);
      _snack('Review saved successfully');
    } catch (_) {
      _snack('Failed to save review');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final name = (_data['ordername'] ?? 'Unknown product').toString();
    final image = (_data['orderImage'] ?? '').toString();
    final status = (_data['deliverystatus'] ?? 'Pending').toString();
    final price = (_data['orderprice'] as num?)?.toDouble() ?? 0;
    final qty = (_data['orderqty'] as num?)?.toInt() ?? 0;
    final statusColor = orderStatusColor(status);

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
          leading: _OrderImage(url: image),
          title: Text(
            name,
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
                SoftChip(icon: Icons.attach_money_rounded, label: price.toStringAsFixed(2)),
                SoftChip(icon: Icons.shopping_bag_outlined, label: 'Qty: $qty'),
                StatusChip(label: status, color: statusColor, icon: orderStatusIcon(status)),
              ],
            ),
          ),
          children: [
            OrderExpansionContainer(
              children: [
                const OrderSectionHeader(
                  icon: Icons.receipt_long_rounded,
                  title: 'Order Information',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    InfoBox(title: 'Order ID', value: widget.orderDoc.id),
                    InfoBox(title: 'Product', value: name),
                    InfoBox(title: 'Price', value: '\$${price.toStringAsFixed(2)}'),
                    InfoBox(title: 'Quantity', value: qty.toString()),
                    InfoBox(title: 'Status', value: status),
                  ],
                ),
                const SizedBox(height: 18),
                const OrderSectionHeader(icon: Icons.rate_review_rounded, title: 'Write a Review'),
                const SizedBox(height: 12),
                _StarSelector(rating: _rating, onChanged: (v) => setState(() => _rating = v)),
                const SizedBox(height: 12),
                _loadingReview
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _ReviewField(controller: _reviewController),
                const SizedBox(height: 14),
                _ReviewButton(
                  submitting: _submitting,
                  loading: _loadingReview,
                  hasReview: _hasReview,
                  onPressed: _submitReview,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _OrderImage extends StatelessWidget {
  final String url;
  const _OrderImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 64,
        height: 64,
        color: const Color(0xFFF1F3F7),
        child: url.isEmpty
            ? const Icon(Icons.image_outlined, color: Colors.grey)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
      ),
    );
  }
}

class _StarSelector extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  const _StarSelector({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      children: List.generate(5, (i) {
        final v = i + 1;
        return IconButton(
          onPressed: () => onChanged(v),
          splashRadius: 22,
          icon: Icon(
            v <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: v <= rating ? const Color(0xFFF4B400) : const Color(0xFF9CA3AF),
            size: 32,
          ),
        );
      }),
    );
  }
}

class _ReviewField extends StatelessWidget {
  final TextEditingController controller;
  const _ReviewField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
    );
  }
}

class _ReviewButton extends StatelessWidget {
  final bool submitting;
  final bool loading;
  final bool hasReview;
  final VoidCallback onPressed;
  const _ReviewButton({
    required this.submitting,
    required this.loading,
    required this.hasReview,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: submitting || loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(hasReview ? Icons.edit_rounded : Icons.send_rounded),
        label: Text(
          submitting
              ? 'Saving...'
              : hasReview
              ? 'Update Review'
              : 'Submit Review',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
