import 'package:flutter/material.dart';

class NavigatorSwitch extends StatefulWidget {
  final List<String> labels;
  final List<Widget> pages;
  final Color activeColor;
  final Color inactiveColor;
  const NavigatorSwitch({
    super.key,
    required this.labels,
    required this.pages,
    this.activeColor = const Color(0xFF111827),
    this.inactiveColor = const Color(0xFFF3F4F6),
  });

  @override
  State<NavigatorSwitch> createState() => _NavigatorSwitchState();
}

class _NavigatorSwitchState extends State<NavigatorSwitch> with SingleTickerProviderStateMixin {
  int _selected = 0;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _switchTo(int index) async {
    if (index == _selected) return;
    await _ctrl.reverse();
    setState(() => _selected = index);
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.inactiveColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: List.generate(widget.labels.length, (i) {
              final isActive = _selected == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _switchTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? widget.activeColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: widget.activeColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        widget.labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: FadeTransition(opacity: _fade, child: widget.pages[_selected]),
        ),
      ],
    );
  }
}

class PositionedBadge extends StatefulWidget {
  final Widget child;
  final String label;
  final Color color;
  final Alignment alignment;
  const PositionedBadge({
    super.key,
    required this.child,
    required this.label,
    this.color = Colors.red,
    this.alignment = Alignment.topRight,
  });

  @override
  State<PositionedBadge> createState() => _PositionedBadgeState();
}

class _PositionedBadgeState extends State<PositionedBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _bounce = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          top: widget.alignment == Alignment.topRight || widget.alignment == Alignment.topLeft
              ? -8
              : null,
          bottom:
              widget.alignment == Alignment.bottomRight || widget.alignment == Alignment.bottomLeft
              ? -8
              : null,
          right: widget.alignment == Alignment.topRight || widget.alignment == Alignment.bottomRight
              ? -8
              : null,
          left: widget.alignment == Alignment.topLeft || widget.alignment == Alignment.bottomLeft
              ? -8
              : null,
          child: ScaleTransition(
            scale: _bounce,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PositionedProductLabel extends StatelessWidget {
  final Widget child;
  final String? discountLabel;
  final String? stockLabel;
  final bool isNew;
  const PositionedProductLabel({
    super.key,
    required this.child,
    this.discountLabel,
    this.stockLabel,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (discountLabel != null)
          Positioned(
            top: 8,
            left: 8,
            child: _FloatingChip(label: discountLabel!, color: Colors.red),
          ),
        if (isNew)
          Positioned(
            top: 8,
            right: 8,
            child: _FloatingChip(label: 'NEW', color: const Color(0xFF10B981)),
          ),
        if (stockLabel != null)
          Positioned(
            bottom: 8,
            left: 8,
            child: _FloatingChip(label: stockLabel!, color: Colors.orange),
          ),
      ],
    );
  }
}

class _FloatingChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FloatingChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class AnimatedInfoCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? expandedChild;
  const AnimatedInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color = const Color(0xFF111827),
    this.expandedChild,
  });

  @override
  State<AnimatedInfoCard> createState() => _AnimatedInfoCardState();
}

class _AnimatedInfoCardState extends State<AnimatedInfoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: EdgeInsets.all(_expanded ? 20 : 16),
        decoration: BoxDecoration(
          color: _expanded ? widget.color : Colors.white,
          borderRadius: BorderRadius.circular(_expanded ? 24 : 16),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_expanded ? 0.3 : 0.08),
              blurRadius: _expanded ? 20 : 10,
              offset: Offset(0, _expanded ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _expanded
                        ? Colors.white.withOpacity(0.2)
                        : widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: _expanded ? Colors.white : widget.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _expanded ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: _expanded ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _expanded ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
            if (_expanded && widget.expandedChild != null) ...[
              const SizedBox(height: 16),
              widget.expandedChild!,
            ],
          ],
        ),
      ),
    );
  }
}

class AnimatedCartSummary extends StatefulWidget {
  final double total;
  final int itemCount;
  final VoidCallback onCheckout;
  const AnimatedCartSummary({
    super.key,
    required this.total,
    required this.itemCount,
    required this.onCheckout,
  });

  @override
  State<AnimatedCartSummary> createState() => _AnimatedCartSummaryState();
}

class _AnimatedCartSummaryState extends State<AnimatedCartSummary>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<double>(
      begin: 100,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (_, child) => Transform.translate(offset: Offset(0, _slideAnim.value), child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.itemCount} item${widget.itemCount != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  Text(
                    '\$${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onCheckout,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideFrom;
  const FadeInWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.slideFrom = const Offset(0, 20),
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.slideFrom,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(offset: _slide.value, child: child),
      ),
      child: widget.child,
    );
  }
}

class StaggeredFadeList extends StatelessWidget {
  final List<Widget> children;
  final Duration stagger;
  const StaggeredFadeList({
    super.key,
    required this.children,
    this.stagger = const Duration(milliseconds: 80),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(children.length, (i) {
        return FadeInWidget(delay: stagger * i, child: children[i]);
      }),
    );
  }
}

class AnimatedVisibilitySection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyVisible;
  const AnimatedVisibilitySection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyVisible = true,
  });

  @override
  State<AnimatedVisibilitySection> createState() => _AnimatedVisibilitySectionState();
}

class _AnimatedVisibilitySectionState extends State<AnimatedVisibilitySection> {
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _visible = widget.initiallyVisible;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _visible = !_visible),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _visible ? 0 : -0.5,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _visible ? widget.child : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
