import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

class Balance extends StatefulWidget {
  const Balance({super.key});

  @override
  State<Balance> createState() => _BalanceState();
}

class _BalanceState extends State<Balance> with TickerProviderStateMixin {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  late AnimationController _fadeController;
  late AnimationController _countController;
  late Animation<double> _fadeAnim;
  late Animation<double> _countAnim;

  double _totalEarnings = 0;
  double _pendingBalance = 0;
  double _paidOut = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _countAnim = CurvedAnimation(parent: _countController, curve: Curves.easeOutExpo);

    _loadBalance();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('sid', isEqualTo: _uid)
          .get();

      double total = 0;
      double pending = 0;
      double paid = 0;

      for (final doc in snap.docs) {
        final data = doc.data();
        final price = (data['orderprice'] as num?)?.toDouble() ?? 0;
        final status = (data['deliverystatus'] ?? '').toString().toLowerCase();
        final payStatus = (data['paymentstatus'] ?? '').toString().toLowerCase();

        total += price;

        if (status == 'delivered') {
          paid += price;
        } else if (status != 'cancelled') {
          pending += price;
        }
      }

      setState(() {
        _totalEarnings = total;
        _pendingBalance = pending;
        _paidOut = paid;
        _loaded = true;
      });

      _fadeController.forward();
      _countController.forward();
    } catch (_) {
      setState(() => _loaded = true);
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        leading: const YellowBackButton(),
        centerTitle: true,
        title: const Text(
          'Balance',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Acme',
            fontSize: 28,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: _loaded
          ? FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ── Main balance card ──
                    _AnimatedBalanceCard(animation: _countAnim, total: _totalEarnings),

                    const SizedBox(height: 20),

                    // ── Two sub cards ──
                    Row(
                      children: [
                        Expanded(
                          child: _SmallBalanceCard(
                            animation: _countAnim,
                            label: 'Pending',
                            amount: _pendingBalance,
                            icon: Icons.hourglass_top_rounded,
                            color: const Color(0xFFF59E0B),
                            bgColor: const Color(0xFF1C1A0F),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SmallBalanceCard(
                            animation: _countAnim,
                            label: 'Paid Out',
                            amount: _paidOut,
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF10B981),
                            bgColor: const Color(0xFF0A1F18),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Recent transactions ──
                    _RecentTransactions(uid: _uid),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class _AnimatedBalanceCard extends StatelessWidget {
  final Animation<double> animation;
  final double total;

  const _AnimatedBalanceCard({required this.animation, required this.total});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final displayValue = total * animation.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Total Earnings',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '\$${displayValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Lifetime revenue',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallBalanceCard extends StatelessWidget {
  final Animation<double> animation;
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _SmallBalanceCard({
    required this.animation,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final displayValue = amount * animation.value;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 12),
              Text(
                '\$${displayValue.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  final String uid;
  const _RecentTransactions({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('sid', isEqualTo: uid)
          .where('deliverystatus', isEqualTo: 'delivered')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Text(
                'No completed transactions yet',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ...docs.take(10).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['ordername'] ?? 'Unknown').toString();
              final price = (data['orderprice'] as num?)?.toDouble() ?? 0;
              final image = (data['orderImage'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 46,
                        height: 46,
                        color: const Color(0xFF0F172A),
                        child: image.isEmpty
                            ? const Icon(Icons.image_outlined, color: Colors.white24)
                            : Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image_outlined, color: Colors.white24),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '+\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
