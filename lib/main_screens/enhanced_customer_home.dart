import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/main_screens/cart.dart';
import 'package:multi_store_app/main_screens/category.dart';
import 'package:multi_store_app/main_screens/enhanced_home.dart';
import 'package:multi_store_app/main_screens/profile.dart';
import 'package:multi_store_app/main_screens/stores.dart';
import 'package:badges/badges.dart' as badge;
import 'package:multi_store_app/providers/cart_provider.dart';
import 'package:multi_store_app/widgets/animated_widgets.dart';
import 'package:multi_store_app/widgets/skip_widgets.dart';
import 'package:provider/provider.dart';


class EnhancedCustomerHomeScreen extends StatefulWidget {
  const EnhancedCustomerHomeScreen({super.key});

  @override
  State<EnhancedCustomerHomeScreen> createState() => _EnhancedCustomerHomeScreenState();
}

class _EnhancedCustomerHomeScreenState extends State<EnhancedCustomerHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _navBarCtrl;
  late Animation<double> _navBarSlide;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _navBarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _navBarSlide = Tween<double>(
      begin: 100,
      end: 0,
    ).animate(CurvedAnimation(parent: _navBarCtrl, curve: Curves.easeOutCubic));
    _navBarCtrl.forward();
  }

  @override
  void dispose() {
    _navBarCtrl.dispose();
    super.dispose();
  }
  static const _splashSlides = [
    SplashSlide(
      title: 'Welcome to\nDuck Store',
      subtitle: 'Your one-stop shop for everything',
      colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
      icon: Icons.store_rounded,
    ),
    SplashSlide(
      title: 'Exclusive\nDeals Daily',
      subtitle: 'Up to 70% off on selected items',
      colors: [Color(0xFFe52d27), Color(0xFF6a0000)],
      icon: Icons.local_fire_department_rounded,
    ),
    SplashSlide(
      title: 'Fast & Safe\nDelivery',
      subtitle: 'Track your orders in real time',
      colors: [Color(0xFF2d1b69), Color(0xFF11998e)],
      icon: Icons.local_shipping_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const EnhancedHomeScreen(),
      const CategoryScreen(),
      const StoresScreen(),
      const CartScreen(),
      ProfileScreen(documentId: _uid),
    ];

    return SplashAdScreen(
      slides: _splashSlides,
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
          child: KeyedSubtree(key: ValueKey(_selectedIndex), child: tabs[_selectedIndex]),
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: _navBarSlide,
          builder: (_, child) =>
              Transform.translate(offset: Offset(0, _navBarSlide.value), child: child),
          child: _EnhancedBottomNav(
            selectedIndex: _selectedIndex,
            cartCount: context.watch<Cart>().getItems.length,
            onTap: (i) => setState(() => _selectedIndex = i),
          ),
        ),
      ),
    );
  }
}

class _EnhancedBottomNav extends StatelessWidget {
  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _EnhancedBottomNav({
    required this.selectedIndex,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Browse',
                index: 1,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.store_rounded,
                label: 'Stores',
                index: 2,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _CartNavItem(count: cartCount, index: 3, selectedIndex: selectedIndex, onTap: onTap),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 4,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _bounce = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex == widget.index && oldWidget.selectedIndex != widget.index) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedIndex == widget.index;
    return GestureDetector(
      onTap: () => widget.onTap(widget.index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _bounce,
              child: Icon(
                widget.icon,
                size: 22,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartNavItem extends StatefulWidget {
  final int count;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _CartNavItem({
    required this.count,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<_CartNavItem> createState() => _CartNavItemState();
}

class _CartNavItemState extends State<_CartNavItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _bounce = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _prevCount = widget.count;
  }

  @override
  void didUpdateWidget(_CartNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != _prevCount) {
      _ctrl.forward().then((_) => _ctrl.reverse());
      _prevCount = widget.count;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedIndex == widget.index;
    return GestureDetector(
      onTap: () => widget.onTap(widget.index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _bounce,
              child: badge.Badge(
                showBadge: widget.count > 0,
                badgeStyle: const badge.BadgeStyle(badgeColor: Colors.amber),
                badgeContent: Text(
                  '${widget.count}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                child: Icon(
                  Icons.shopping_cart_rounded,
                  size: 22,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Text(
                'Cart',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
