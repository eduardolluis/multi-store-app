import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:multi_store_app/minor_screens/subcateg_products.dart';


class OfferData {
  final String title;
  final String subtitle;
  final String discount;
  final List<Color> gradientColors;
  final IconData icon;
  final String mainCategory;
  final String subCategory;
  final String tag;

  const OfferData({
    required this.title,
    required this.subtitle,
    required this.discount,
    required this.gradientColors,
    required this.icon,
    required this.mainCategory,
    required this.subCategory,
    required this.tag,
  });
}

const offerWatches = OfferData(
  title: 'LUXURY\nWATCHES',
  subtitle: 'Exclusive timepieces',
  discount: 'UP TO 40% OFF',
  gradientColors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
  icon: Icons.watch_rounded,
  mainCategory: 'accessories',
  subCategory: 'classic watch',
  tag: 'NEW',
);

const offerShoes = OfferData(
  title: 'STEP IN\nSTYLE',
  subtitle: 'Latest footwear drops',
  discount: 'SAVE 35%',
  gradientColors: [Color(0xFF2d1b69), Color(0xFF11998e), Color(0xFF38ef7d)],
  icon: Icons.do_not_step_rounded,
  mainCategory: 'shoes',
  subCategory: 'men sport',
  tag: 'HOT',
);

const offerSale = OfferData(
  title: 'MEGA\nSALE',
  subtitle: 'Limited time deals',
  discount: '50-70% OFF',
  gradientColors: [Color(0xFFe52d27), Color(0xFFb31217), Color(0xFF6a0000)],
  icon: Icons.local_fire_department_rounded,
  mainCategory: 'women',
  subCategory: 'dress',
  tag: 'SALE',
);


class RandomOfferBanner extends StatefulWidget {
  const RandomOfferBanner({super.key});

  @override
  State<RandomOfferBanner> createState() => _RandomOfferBannerState();
}

class _RandomOfferBannerState extends State<RandomOfferBanner> with SingleTickerProviderStateMixin {
  final List<OfferData> _offers = [offerWatches, offerShoes, offerSale];
  late OfferData _currentOffer;
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _currentOffer = _offers[_random.nextInt(_offers.length)];
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _shuffle() async {
    await _ctrl.reverse();
    final filtered = _offers.where((o) => o != _currentOffer).toList();
    setState(() => _currentOffer = filtered[_random.nextInt(filtered.length)]);
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: _OfferCard(offer: _currentOffer, onShuffle: _shuffle),
      ),
    );
  }
}


class OfferWatchesBanner extends StatelessWidget {
  const OfferWatchesBanner({super.key});

  @override
  Widget build(BuildContext context) => _OfferCard(offer: offerWatches);
}

class OfferShoesBanner extends StatelessWidget {
  const OfferShoesBanner({super.key});

  @override
  Widget build(BuildContext context) => _OfferCard(offer: offerShoes);
}

class OfferSaleBanner extends StatelessWidget {
  const OfferSaleBanner({super.key});

  @override
  Widget build(BuildContext context) => _OfferCard(offer: offerSale);
}


class _OfferCard extends StatefulWidget {
  final OfferData offer;
  final VoidCallback? onShuffle;
  const _OfferCard({required this.offer, this.onShuffle});

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubcategProducts(
            maincategoryName: widget.offer.mainCategory,
            subcategoryName: widget.offer.subCategory,
          ),
        ),
      ),
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: widget.offer.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.offer.gradientColors.first.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: 60,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.offer.tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: widget.offer.gradientColors.last,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Icon(widget.offer.icon, size: 70, color: Colors.white.withOpacity(0.15)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.offer.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.offer.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.offer.discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onShuffle != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: widget.onShuffle,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  Timer? _timer;
  final List<OfferData> _offers = [offerWatches, offerShoes, offerSale];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _offers.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 196,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _offers.length,
            itemBuilder: (_, i) => _OfferCard(offer: _offers[i]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_offers.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == i ? _offers[i].gradientColors.first : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
