import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

class StaticsScreen extends StatefulWidget {
  const StaticsScreen({super.key});

  @override
  State<StaticsScreen> createState() => _StaticsScreenState();
}

class _StaticsScreenState extends State<StaticsScreen> with TickerProviderStateMixin {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  late AnimationController _fadeCtrl;
  late AnimationController _barCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _barAnim;
  bool _loaded = false;

  // Stats
  int _total = 0, _delivered = 0, _preparing = 0, _shipped = 0, _cancelled = 0, _products = 0;
  double _revenue = 0, _avgOrder = 0;
  Map<String, double> _monthly = {};

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    _loadStats();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('sid', isEqualTo: _uid)
          .get();
      final prodsSnap = await FirebaseFirestore.instance
          .collection('products')
          .where('cid', isEqualTo: _uid)
          .get();

      int total = 0, delivered = 0, preparing = 0, shipped = 0, cancelled = 0;
      double revenue = 0;
      final monthly = _emptyMonthlyMap();

      for (final doc in ordersSnap.docs) {
        final d = doc.data();
        final status = (d['deliverystatus'] ?? '').toString().toLowerCase();
        final price = (d['orderprice'] as num?)?.toDouble() ?? 0;
        total++;
        switch (status) {
          case 'delivered':
            delivered++;
            revenue += price;
            break;
          case 'preparing':
            preparing++;
            break;
          case 'shipped':
            shipped++;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
        final raw = d['orderdate'] ?? d['createdAt'];
        DateTime? date;
        if (raw is Timestamp) date = raw.toDate();
        if (raw is DateTime) date = raw;
        if (date != null && status == 'delivered') {
          final key = _monthLabel(date);
          if (monthly.containsKey(key)) monthly[key] = (monthly[key] ?? 0) + price;
        }
      }

      setState(() {
        _total = total;
        _delivered = delivered;
        _preparing = preparing;
        _shipped = shipped;
        _cancelled = cancelled;
        _products = prodsSnap.docs.length;
        _revenue = revenue;
        _avgOrder = delivered > 0 ? revenue / delivered : 0;
        _monthly = monthly;
        _loaded = true;
      });
      _fadeCtrl.forward();
      _barCtrl.forward();
    } catch (_) {
      setState(() => _loaded = true);
      _fadeCtrl.forward();
    }
  }

  Map<String, double> _emptyMonthlyMap() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return {for (int i = 5; i >= 0; i--) months[DateTime(now.year, now.month - i).month - 1]: 0.0};
  }

  String _monthLabel(DateTime d) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][d.month - 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FB),
        leading: const AppbarBackButton(),
        title: const AppbarTitle(title: 'Statistics'),
      ),
      body: _loaded
          ? FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KpiRow(
                      total: _total,
                      products: _products,
                      revenue: _revenue,
                      avgOrder: _avgOrder,
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel(label: 'Order Breakdown'),
                    const SizedBox(height: 12),
                    OrderBreakdownCard(
                      delivered: _delivered,
                      preparing: _preparing,
                      shipped: _shipped,
                      cancelled: _cancelled,
                      total: _total,
                      animation: _barAnim,
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel(label: 'Monthly Revenue'),
                    const SizedBox(height: 12),
                    MonthlyBarChart(data: _monthly, animation: _barAnim),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

// ── KPI row ───────────────────────────────────────────────────────────────────

class KpiRow extends StatelessWidget {
  final int total, products;
  final double revenue, avgOrder;
  const KpiRow({
    super.key,
    required this.total,
    required this.products,
    required this.revenue,
    required this.avgOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Total Orders',
                value: total.toString(),
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Products',
                value: products.toString(),
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Revenue',
                value: '\$${revenue.toStringAsFixed(0)}',
                icon: Icons.attach_money_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Avg Order',
                value: '\$${avgOrder.toStringAsFixed(2)}',
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order breakdown ───────────────────────────────────────────────────────────

class OrderBreakdownCard extends StatelessWidget {
  final int delivered, preparing, shipped, cancelled, total;
  final Animation<double> animation;
  const OrderBreakdownCard({
    super.key,
    required this.delivered,
    required this.preparing,
    required this.shipped,
    required this.cancelled,
    required this.total,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item('Delivered', delivered, const Color(0xFF10B981)),
      _Item('Preparing', preparing, const Color(0xFFF59E0B)),
      _Item('Shipped', shipped, const Color(0xFF3B82F6)),
      _Item('Cancelled', cancelled, const Color(0xFFEF4444)),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          final ratio = total == 0 ? 0.0 : item.count / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item.count}  (${(ratio * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: animation,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ratio * animation.value,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: AlwaysStoppedAnimation(item.color),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Item {
  final String label;
  final int count;
  final Color color;
  const _Item(this.label, this.count, this.color);
}

// ── Monthly bar chart ─────────────────────────────────────────────────────────

class MonthlyBarChart extends StatelessWidget {
  final Map<String, double> data;
  final Animation<double> animation;
  const MonthlyBarChart({super.key, required this.data, required this.animation});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.fold(0.0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, __) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.entries.map((e) {
                  final ratio = maxVal == 0 ? 0.0 : e.value / maxVal;
                  final height = (130 * ratio * animation.value).clamp(4.0, 130.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (e.value > 0)
                            Text(
                              '\$${e.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: data.keys
                .map(
                  (k) => Expanded(
                    child: Text(
                      k,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
    );
  }
}
