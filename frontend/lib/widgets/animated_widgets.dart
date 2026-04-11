// lib/widgets/animated_widgets.dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';

class AnimatedOnScroll extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double delay;

  const AnimatedOnScroll({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.delay = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: duration,
      curve: curve,
      delay: Duration(milliseconds: (delay * 1000).round()),
      child: child,
    );
  }
}

class AnimatedHover extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;

  const AnimatedHover({
    Key? key,
    required this.child,
    this.scale = 1.05,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<AnimatedHover> createState() => _AnimatedHoverState();
}

class _AnimatedHoverState extends State<AnimatedHover> {
  bool _isHovered = false;
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
          _scale = widget.scale;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _scale = 1.0;
        });
      },
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isHovered ? 1.0 : 0.9,
          duration: widget.duration,
          child: widget.child,
        ),
      ),
    );
  }
}

class ShimmerEffect extends StatelessWidget {
  final Widget child;

  const ShimmerEffect({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: child,
    );
  }
}

class AnimatedPulse extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool loop;

  const AnimatedPulse({
    Key? key,
    required this.child,
    this.onTap,
    this.loop = false,
  }) : super(key: key);

  @override
  State<AnimatedPulse> createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<AnimatedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.loop) {
      _controller.repeat(reverse: true);
    }

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.loop) {
          _controller.forward().then((_) => _controller.reverse());
        }
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.loop ? _animation.value : 1.0,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class ParallaxScroll extends StatelessWidget {
  final Widget child;
  final double speed;

  const ParallaxScroll({Key? key, required this.child, this.speed = 0.5})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final scrollOffset = notification.metrics.pixels;
        }
        return false;
      },
      child: child,
    );
  }
}
