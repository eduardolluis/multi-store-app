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

  late AnimationController _fadeController;
  late AnimationController _barController;
  late Animation<double> _fadeAnim;
  late Animation<double> _barAnim;

  bool _loaded = false;

  int _totalOrders = 0;
  int _deliveredOrders = 0;
  int _preparingOrders = 0;
  int _shippedOrders = 0;
  int _cancelledOrders = 0;
  int _totalProducts = 0;
  double _totalRevenue = 0;
  double _avgOrderValue = 0;

  // Monthly data (last 6 months)
  Map<String, double> _monthlyRevenue = {};

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _barController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _barAnim = CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic);

    _loadStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _barController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('sid', isEqualTo: _uid)
          .get();

      final productsSnap = await FirebaseFirestore.instance
          .collection('products')
          .where('cid', isEqualTo: _uid)
          .get();

      int total = 0, delivered = 0, preparing = 0, shipped = 0, cancelled = 0;
      double revenue = 0;
      final Map<String, double> monthly = {};

      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final key = _monthKey(d);
        monthly[key] = 0;
      }

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final status = (data['deliverystatus'] ?? '').toString().toLowerCase();
        final price = (data['orderprice'] as num?)?.toDouble() ?? 0;

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

        // Monthly breakdown
        DateTime? orderDate;
        final raw = data['orderdate'] ?? data['createdAt'];
        if (raw is Timestamp) orderDate = raw.toDate();
        if (raw is DateTime) orderDate = raw;

        if (orderDate != null && status == 'delivered') {
          final key = _monthKey(orderDate);
          if (monthly.containsKey(key)) {
            monthly[key] = (monthly[key] ?? 0) + price;
          }
        }
      }

      setState(() {
        _totalOrders = total;
        _deliveredOrders = delivered;
        _preparingOrders = preparing;
        _shippedOrders = shipped;
        _cancelledOrders = cancelled;
        _totalRevenue = revenue;
        _avgOrderValue = delivered > 0 ? revenue / delivered : 0;
        _totalProducts = productsSnap.docs.length;
        _monthlyRevenue = monthly;
        _loaded = true;
      });

      _fadeController.forward();
      _barController.forward();
    } catch (_) {
      setState(() => _loaded = true);
      _fadeController.forward();
    }
  }

  String _monthKey(DateTime d) {
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
    return months[d.month - 1];
  }

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
                    // ── KPI row ──
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            label: 'Total Orders',
                            value: _totalOrders.toString(),
                            icon: Icons.shopping_bag_rounded,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            label: 'Products',
                            value: _totalProducts.toString(),
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
                          child: _KpiCard(
                            label: 'Revenue',
                            value: '\$${_totalRevenue.toStringAsFixed(0)}',
                            icon: Icons.attach_money_rounded,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            label: 'Avg Order',
                            value: '\$${_avgOrderValue.toStringAsFixed(2)}',
                            icon: Icons.bar_chart_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Order status breakdown ──
                    _SectionLabel(label: 'Order Breakdown'),
                    const SizedBox(height: 12),
                    _OrderStatusBreakdown(
                      delivered: _deliveredOrders,
                      preparing: _preparingOrders,
                      shipped: _shippedOrders,
                      cancelled: _cancelledOrders,
                      total: _totalOrders,
                      animation: _barAnim,
                    ),

                    const SizedBox(height: 24),

                    // ── Monthly revenue bar chart ──
                    _SectionLabel(label: 'Monthly Revenue'),
                    const SizedBox(height: 12),
                    _MonthlyBarChart(data: _monthlyRevenue, animation: _barAnim),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

// ── KPI card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
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

// ── Order status breakdown ────────────────────────────────────────────────────

class _OrderStatusBreakdown extends StatelessWidget {
  final int delivered;
  final int preparing;
  final int shipped;
  final int cancelled;
  final int total;
  final Animation<double> animation;

  const _OrderStatusBreakdown({
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
      _StatusItem('Delivered', delivered, const Color(0xFF10B981)),
      _StatusItem('Preparing', preparing, const Color(0xFFF59E0B)),
      _StatusItem('Shipped', shipped, const Color(0xFF3B82F6)),
      _StatusItem('Cancelled', cancelled, const Color(0xFFEF4444)),
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

class _StatusItem {
  final String label;
  final int count;
  final Color color;
  const _StatusItem(this.label, this.count, this.color);
}

// ── Monthly bar chart ─────────────────────────────────────────────────────────

class _MonthlyBarChart extends StatelessWidget {
  final Map<String, double> data;
  final Animation<double> animation;

  const _MonthlyBarChart({required this.data, required this.animation});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.fold(0.0, (a, b) => a > b ? a : b);
    const barColor = Color(0xFF6366F1);

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
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, __) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.entries.map((entry) {
                    final ratio = maxVal == 0 ? 0.0 : entry.value / maxVal;
                    final height = 130 * ratio * animation.value;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (entry.value > 0)
                              Text(
                                '\$${entry.value.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              height: height.clamp(4, 130),
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: data.keys.map((k) {
              return Expanded(
                child: Text(
                  k,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              );
            }).toList(),
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
