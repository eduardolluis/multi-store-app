import 'dart:async';
import 'package:flutter/material.dart';


class SkipButton extends StatefulWidget {
  final VoidCallback onSkip;
  final String label;
  const SkipButton({super.key, required this.onSkip, this.label = 'Skip'});

  @override
  State<SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<SkipButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.92,
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
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onSkip();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.skip_next_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}


class SkipOnTimer extends StatefulWidget {
  final VoidCallback onSkip;
  final int seconds;
  final Color color;
  const SkipOnTimer({
    super.key,
    required this.onSkip,
    this.seconds = 5,
    this.color = Colors.black87,
  });

  @override
  State<SkipOnTimer> createState() => _SkipOnTimerState();
}

class _SkipOnTimerState extends State<SkipOnTimer> with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _countdownTimer;
  late AnimationController _progressCtrl;
  bool _canSkip = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _progressCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    )..forward();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        setState(() => _canSkip = true);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _canSkip ? widget.onSkip : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _canSkip ? widget.color : widget.color.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _canSkip
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (_, __) => CircularProgressIndicator(
                      value: _progressCtrl.value,
                      strokeWidth: 2.5,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  if (!_canSkip)
                    Text(
                      '$_remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (_canSkip) const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _canSkip ? 'Skip' : 'Skip in $_remaining',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_canSkip) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}


class SplashAdScreen extends StatefulWidget {
  final Widget child;
  final List<SplashSlide> slides;
  const SplashAdScreen({super.key, required this.child, required this.slides});

  @override
  State<SplashAdScreen> createState() => _SplashAdScreenState();
}

class SplashSlide {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;
  const SplashSlide({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.icon,
  });
}

class _SplashAdScreenState extends State<SplashAdScreen> with TickerProviderStateMixin {
  int _currentSlide = 0;
  bool _dismissed = false;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  static const _defaultSlides = [
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
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInBack));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));
    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _skip() async {
    await _slideCtrl.forward();
    if (mounted) setState(() => _dismissed = true);
  }

  void _nextSlide() async {
    if (_currentSlide < widget.slides.length - 1) {
      await _contentCtrl.reverse();
      setState(() => _currentSlide++);
      _contentCtrl.forward();
    } else {
      _skip();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return widget.child;

    final slides = widget.slides.isEmpty ? _defaultSlides : widget.slides;
    final slide = slides[_currentSlide];
    final isLast = _currentSlide == slides.length - 1;

    return SlideTransition(
      position: _slideAnim,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: slide.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -60,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: isLast
                      ? SkipOnTimer(onSkip: _skip, seconds: 3)
                      : SkipButton(onSkip: _skip),
                ),
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(slide.icon, size: 100, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(height: 40),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 60),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(slides.length, (i) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentSlide == i ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentSlide == i
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 40),
                            GestureDetector(
                              onTap: _nextSlide,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    isLast ? 'Get Started' : 'Next',
                                    style: TextStyle(
                                      color: slide.colors.first,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
