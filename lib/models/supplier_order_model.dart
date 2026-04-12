import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/order_widget.dart';

// ── Helper functions ──────────────────────────────────────────────────────────

const _statusOptions = ['pending', 'preparing', 'shipped', 'delivered', 'cancelled'];

String normalizeStatus(String v) {
  final n = v.trim().toLowerCase();
  return _statusOptions.contains(n) ? n : 'pending';
}

String capitalize(String v) => v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);

String formatDate(DateTime? date) {
  if (date == null) return 'Not available';
  final d = date.day.toString().padLeft(2, '0');
  final mo = date.month.toString().padLeft(2, '0');
  final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final mi = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$d/$mo/${date.year} • $h:$mi $period';
}

dynamic _firstOf(Map<String, dynamic> data, List<String> keys) {
  for (final k in keys) {
    if (data.containsKey(k) && data[k] != null) return data[k];
  }
  return null;
}

String readStr(dynamic v, [String fb = '']) {
  if (v == null) return fb;
  final t = v.toString().trim();
  return t.isEmpty ? fb : t;
}

double readDouble(dynamic v, [double fb = 0]) {
  if (v == null) return fb;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fb;
}

int readInt(dynamic v, [int fb = 0]) {
  if (v == null) return fb;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fb;
}

DateTime? readDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return null;
}

// ── Main widget ───────────────────────────────────────────────────────────────

class SuppOrderModel extends StatefulWidget {
  final QueryDocumentSnapshot orderDoc;
  final String userId;
  const SuppOrderModel({super.key, required this.orderDoc, required this.userId});

  @override
  State<SuppOrderModel> createState() => _SuppOrderModelState();
}

class _SuppOrderModelState extends State<SuppOrderModel> {
  late String _status;
  bool _updatingStatus = false;
  bool _savingDate = false;
  DateTime? _estDelivery;

  Map<String, dynamic> get _data => widget.orderDoc.data() as Map<String, dynamic>;

  @override
  void initState() {
    super.initState();
    _status = normalizeStatus(
      readStr(_firstOf(_data, ['deliverystatus', 'deliveryStatus', 'status', 'orderStatus'])),
    );
    final existing = _firstOf(_data, ['estimatedDelivery']);
    if (existing is Timestamp) _estDelivery = existing.toDate();
  }

  void _snack(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  Future<void> _saveStatus() async {
    setState(() => _updatingStatus = true);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderDoc.id).update({
        'deliverystatus': _status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _snack('Order status updated successfully');
    } catch (_) {
      _snack('Failed to update order status');
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _saveDeliveryDate() async {
    if (_estDelivery == null) return _snack('Please select a delivery date first');
    setState(() => _savingDate = true);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderDoc.id).update({
        'estimatedDelivery': Timestamp.fromDate(_estDelivery!),
        'deliverydate': formatDate(_estDelivery),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _snack('Estimated delivery date saved');
    } catch (_) {
      _snack('Failed to save delivery date');
    } finally {
      if (mounted) setState(() => _savingDate = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _estDelivery ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF111827),
            onPrimary: Colors.white,
            onSurface: Color(0xFF111827),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_estDelivery ?? now.add(const Duration(days: 3))),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF111827),
            onPrimary: Colors.white,
            onSurface: Color(0xFF111827),
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;

    setState(() {
      _estDelivery = time == null
          ? picked
          : DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = readStr(
      _firstOf(_data, ['ordername', 'orderName', 'productName', 'name']),
      'Unknown product',
    );
    final image = readStr(_firstOf(_data, ['orderImage', 'orderimage', 'productImage', 'image']));
    final status = normalizeStatus(
      readStr(_firstOf(_data, ['deliverystatus', 'deliveryStatus', 'status']), _status),
    );
    final price = readDouble(_firstOf(_data, ['orderprice', 'orderPrice', 'price']));
    final qty = readInt(_firstOf(_data, ['orderqty', 'orderQty', 'qty', 'quantity']), 1);
    final safeQty = qty <= 0 ? 1 : qty;
    final statusColor = orderStatusColor(status);

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
          leading: _SupplierOrderImage(url: image),
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
                SoftChip(
                  icon: Icons.person_outline_rounded,
                  label: readStr(
                    _firstOf(_data, ['custname', 'customerName', 'buyerName']),
                    'Unknown',
                  ),
                ),
                SoftChip(icon: Icons.shopping_bag_outlined, label: 'Qty: $safeQty'),
                SoftChip(
                  icon: Icons.attach_money_rounded,
                  label: (price * safeQty).toStringAsFixed(2),
                ),
                StatusChip(
                  label: capitalize(status),
                  color: statusColor,
                  icon: orderStatusIcon(status),
                ),
              ],
            ),
          ),
          children: [
            OrderExpansionContainer(
              children: [
                // ── Order info ──
                _OrderInfoSection(
                  data: _data,
                  orderId: widget.orderDoc.id,
                  name: name,
                  price: price,
                  safeQty: safeQty,
                  estDelivery: _estDelivery,
                ),
                const SizedBox(height: 18),

                // ── Customer info ──
                _CustomerInfoSection(data: _data),
                const SizedBox(height: 18),

                // ── Delivery date ──
                _DeliveryDateSection(
                  estDelivery: _estDelivery,
                  saving: _savingDate,
                  onPickDate: _pickDate,
                  onQuickDate: (days) =>
                      setState(() => _estDelivery = DateTime.now().add(Duration(days: days))),
                  onSave: _saveDeliveryDate,
                ),
                const SizedBox(height: 18),

                // ── Status update ──
                _StatusUpdateSection(
                  selectedStatus: _status,
                  updating: _updatingStatus,
                  statusColor: statusColor,
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                  onQuickSelect: (s) => setState(() => _status = s),
                  onSave: _saveStatus,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section sub-widgets ───────────────────────────────────────────────────────

class _SupplierOrderImage extends StatelessWidget {
  final String url;
  const _SupplierOrderImage({required this.url});

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

class _OrderInfoSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final String orderId;
  final String name;
  final double price;
  final int safeQty;
  final DateTime? estDelivery;

  const _OrderInfoSection({
    required this.data,
    required this.orderId,
    required this.name,
    required this.price,
    required this.safeQty,
    required this.estDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final paymentStatus = readStr(
      _firstOf(data, ['paymentStatus', 'paymentstatus']),
      'Not available',
    );
    final orderDate = formatDate(
      readDate(_firstOf(data, ['orderDate', 'createdAt', 'date', 'orderdate'])),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OrderSectionHeader(icon: Icons.receipt_long_rounded, title: 'Order Information'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            InfoBox(title: 'Order ID', value: orderId),
            InfoBox(title: 'Product', value: name),
            InfoBox(title: 'Unit Price', value: '\$${price.toStringAsFixed(2)}'),
            InfoBox(title: 'Quantity', value: safeQty.toString()),
            InfoBox(title: 'Total', value: '\$${(price * safeQty).toStringAsFixed(2)}'),
            InfoBox(title: 'Payment', value: paymentStatus),
            InfoBox(title: 'Order Date', value: orderDate),
            if (estDelivery != null)
              InfoBox(title: 'Est. Delivery', value: formatDate(estDelivery)),
          ],
        ),
      ],
    );
  }
}

class _CustomerInfoSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CustomerInfoSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OrderSectionHeader(icon: Icons.person_rounded, title: 'Customer Information'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            InfoBox(
              title: 'Customer',
              value: readStr(_firstOf(data, ['custname', 'customerName', 'buyerName']), 'Unknown'),
            ),
            InfoBox(
              title: 'Customer ID',
              value: readStr(_firstOf(data, ['cid', 'customerId']), 'N/A'),
            ),
            InfoBox(
              title: 'Email',
              value: readStr(_firstOf(data, ['email', 'customerEmail']), 'Not available'),
            ),
            InfoBox(
              title: 'Phone',
              value: readStr(_firstOf(data, ['phone', 'customerPhone']), 'Not available'),
            ),
            InfoBox(
              title: 'Address',
              value: readStr(
                _firstOf(data, ['address', 'customerAddress', 'shippingAddress']),
                'Not available',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeliveryDateSection extends StatelessWidget {
  final DateTime? estDelivery;
  final bool saving;
  final VoidCallback onPickDate;
  final void Function(int days) onQuickDate;
  final VoidCallback onSave;

  const _DeliveryDateSection({
    required this.estDelivery,
    required this.saving,
    required this.onPickDate,
    required this.onQuickDate,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OrderSectionHeader(icon: Icons.calendar_month_rounded, title: 'Estimated Delivery'),
        const SizedBox(height: 14),
        InkWell(
          onTap: saving ? null : onPickDate,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: estDelivery != null ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
                width: estDelivery != null ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estDelivery == null ? 'Tap to select date & time' : formatDate(estDelivery),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: estDelivery == null
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF111827),
                        ),
                      ),
                      if (estDelivery != null)
                        const Text(
                          'Tap to change',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: estDelivery != null ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in {'+1 day': 1, '+3 days': 3, '+1 week': 7, '+2 weeks': 14}.entries)
              _QuickDateChip(label: entry.key, onTap: () => onQuickDate(entry.value)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: saving || estDelivery == null ? null : onSave,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.event_available_rounded),
            label: Text(
              saving ? 'Saving...' : 'Save Delivery Date',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusUpdateSection extends StatelessWidget {
  final String selectedStatus;
  final bool updating;
  final Color statusColor;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String> onQuickSelect;
  final VoidCallback onSave;

  const _StatusUpdateSection({
    required this.selectedStatus,
    required this.updating,
    required this.statusColor,
    required this.onChanged,
    required this.onQuickSelect,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OrderSectionHeader(
          icon: Icons.local_shipping_rounded,
          title: 'Update Delivery Status',
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: selectedStatus,
          items: _statusOptions
              .map((s) => DropdownMenuItem(value: s, child: Text(capitalize(s))))
              .toList(),
          onChanged: updating ? null : onChanged,
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
          children: _statusOptions
              .map(
                (s) => _QuickStatusButton(
                  label: capitalize(s),
                  selected: selectedStatus == s,
                  color: orderStatusColor(s),
                  onTap: () => onQuickSelect(s),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: updating ? null : onSave,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: updating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              updating ? 'Updating...' : 'Save Status',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Small chips ───────────────────────────────────────────────────────────────

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

class _QuickDateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickDateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on_rounded, size: 13, color: Color(0xFF4B5563)),
            const SizedBox(width: 4),
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
      ),
    );
  }
}
