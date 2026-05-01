import 'package:flutter/material.dart';
import 'package:multi_store_app/gallery/accessories_gallery.dart';
import 'package:multi_store_app/gallery/bags_gallery.dart';
import 'package:multi_store_app/gallery/beauty_gallery.dart';
import 'package:multi_store_app/gallery/electronics_gallery.dart';
import 'package:multi_store_app/gallery/homegarden_gallery.dart';
import 'package:multi_store_app/gallery/kids_gallery.dart';
import 'package:multi_store_app/gallery/men_gallery.dart';
import 'package:multi_store_app/gallery/shoes_gallery.dart';
import 'package:multi_store_app/gallery/women_gallery.dart';
import 'package:multi_store_app/widgets/animated_widgets.dart';
import 'package:multi_store_app/widgets/fake_search.dart';
import 'package:multi_store_app/widgets/offer_banner.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabLabels = [
    'Men',
    'Women',
    'Shoes',
    'Bags',
    'Electronics',
    'Accessories',
    'Home & Garden',
    'Kids',
    'Beauty',
  ];

  final List<Widget> _tabViews = [
    MenGalleryScreen(),
    WomenGalleryScreen(),
    ShoesGalleryScreen(),
    BagsGalleryScreen(),
    ElectronicsGalleryScreen(),
    AccessoriesGalleryScreen(),
    HomeGardenGalleryScreen(),
    KidsGalleryScreen(),
    BeautyGalleryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Colors.white,
              title: const FakeSearch(),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: _AnimatedTabBar(controller: _tabController, labels: _tabLabels),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const FadeInWidget(delay: Duration(milliseconds: 100), child: OffersCarousel()),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: _SectionHeader(
                      title: '🎲 Today\'s Random Deal',
                      subtitle: 'Refreshes every visit',
                    ),
                  ),
                  const FadeInWidget(
                    delay: const Duration(milliseconds: 250),
                    child: RandomOfferBanner(),
                  ),
                  // Quick category pills
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: _SectionHeader(title: '🔥 Trending Now', subtitle: 'Browse by category'),
                  ),
                  const FadeInWidget(
                    delay: const Duration(milliseconds: 350),
                    child: _CategoryQuickPills(),
                  ),
                  const SizedBox(height: 8),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: _SectionHeader(
                      title: '🛍️ All Products',
                      subtitle: 'Explore everything',
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(controller: _tabController, children: _tabViews),
      ),
    );
  }
}

class _AnimatedTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  const _AnimatedTabBar({required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      indicatorColor: const Color(0xFF111827),
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      labelColor: const Color(0xFF111827),
      unselectedLabelColor: Colors.grey,
      splashFactory: NoSplash.splashFactory,
      tabs: labels.map((l) => Tab(text: l)).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            'See all →',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryQuickPills extends StatelessWidget {
  const _CategoryQuickPills();

  static const _categories = [
    ('👔 Men', 'men'),
    ('👗 Women', 'women'),
    ('👟 Shoes', 'shoes'),
    ('💻 Electronics', 'electronics'),
    ('💄 Beauty', 'beauty'),
    ('👜 Bags', 'bags'),
    ('⌚ Accessories', 'accessories'),
    ('🧒 Kids', 'kids'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, cat) = _categories[i];
          return _CategoryPill(label: label, category: cat);
        },
      ),
    );
  }
}

class _CategoryPill extends StatefulWidget {
  final String label;
  final String category;
  const _CategoryPill({required this.label, required this.category});

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}

class RepeatedTab extends StatelessWidget {
  final String label;
  const RepeatedTab({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Text(label, style: TextStyle(color: Colors.grey[600])),
    );
  }
}
