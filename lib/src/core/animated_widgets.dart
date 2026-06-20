import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'motion_tokens.dart';
import '../utils/haptic_utils.dart';

class EntranceFadeSlide extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;
  final Curve curve;
  final double offset;

  const EntranceFadeSlide({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.offset = MotionOffsets.entranceSlide,
  });

  @override
  State<EntranceFadeSlide> createState() => _EntranceFadeSlideState();
}

class _EntranceFadeSlideState extends State<EntranceFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translate;

  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _translate = Tween(begin: widget.offset, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStarted) {
      _hasStarted = true;
      if (!MotionAccessibility.isReducedMotion(context)) {
        if (widget.delayMs > 0) {
          Future.delayed(Duration(milliseconds: widget.delayMs), () {
            if (mounted) _controller.forward();
          });
        } else {
          _controller.forward();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionAccessibility.isReducedMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _translate.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class StaggeredEntrance extends StatelessWidget {
  final List<Widget> children;
  final int maxStagger;
  final Duration interval;
  final Duration entranceDuration;
  final Curve curve;
  final double offset;
  final bool isColumn;

  const StaggeredEntrance({
    super.key,
    required this.children,
    this.maxStagger = MotionStagger.maxItems,
    this.interval = MotionStagger.interval,
    this.entranceDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.offset = MotionOffsets.entranceSlide,
    this.isColumn = true,
  });

  @override
  Widget build(BuildContext context) {
    final animated = List<Widget>.generate(children.length, (i) {
      if (i >= maxStagger) return children[i];
      return EntranceFadeSlide(
        delayMs: i * interval.inMilliseconds,
        duration: entranceDuration,
        curve: curve,
        offset: offset,
        child: children[i],
      );
    });
    if (MotionAccessibility.isReducedMotion(context)) {
      return (isColumn
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)
          : Column(children: children));
    }
    return (isColumn
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: animated)
        : Column(children: animated));
  }
}

class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final double pressedOpacity;
  final Duration pressDuration;
  final SpringDescription? spring;
  final bool haptic;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = MotionOffsets.pressScale,
    this.pressedOpacity = 0.9,
    this.pressDuration = MotionDurations.press,
    this.spring,
    this.haptic = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 0.0);
    _scaleAnim = Tween(begin: 1.0, end: widget.scale).animate(_controller);
    _opacityAnim = Tween(begin: 1.0, end: widget.pressedOpacity).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (MotionAccessibility.isReducedMotion(context)) return;
    if (widget.haptic) HapticUtils.light();
    _controller.stop();
    _controller.animateTo(1.0, duration: widget.pressDuration, curve: Curves.linear);
  }

  void _onTapUp(TapUpDetails _) => _springBack();
  void _onTapCancel() => _springBack();

  void _springBack() {
    if (MotionAccessibility.isReducedMotion(context)) return;
    _controller.stop();
    _controller.animateWith(SpringSimulation(
      widget.spring ?? MotionSprings.defaultSpring,
      _controller.value,
      0.0,
      _controller.velocity,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: Opacity(
            opacity: _opacityAnim.value,
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class CardPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration pressDuration;
  final SpringDescription? spring;

  const CardPress({
    super.key,
    required this.child,
    this.onTap,
    this.scale = MotionOffsets.cardPressScale,
    this.pressDuration = MotionDurations.press,
    this.spring,
  });

  @override
  State<CardPress> createState() => _CardPressState();
}

class _CardPressState extends State<CardPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 0.0);
    _scaleAnim = Tween(begin: 1.0, end: widget.scale).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (MotionAccessibility.isReducedMotion(context)) return;
    _controller.stop();
    _controller.animateTo(1.0, duration: widget.pressDuration, curve: Curves.linear);
  }

  void _onTapUp(TapUpDetails _) => _springBack();
  void _onTapCancel() => _springBack();

  void _springBack() {
    if (MotionAccessibility.isReducedMotion(context)) return;
    _controller.stop();
    _controller.animateWith(SpringSimulation(
      widget.spring ?? MotionSprings.gentleSpring,
      _controller.value,
      0.0,
      _controller.velocity,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
