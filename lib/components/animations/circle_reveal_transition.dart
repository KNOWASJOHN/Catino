import 'package:flutter/material.dart';

class CircleRevealTransition extends StatefulWidget {
  final Offset startPosition;
  final bool isAnimating;
  final VoidCallback onComplete;

  const CircleRevealTransition({
    super.key,
    required this.startPosition,
    required this.isAnimating,
    required this.onComplete,
  });

  @override
  State<CircleRevealTransition> createState() => _CircleRevealTransitionState();
}

class _CircleRevealTransitionState extends State<CircleRevealTransition>
    with TickerProviderStateMixin {
  late AnimationController _riseController;
  late AnimationController _expandController;
  late Animation<double> _riseAnimation;
  late Animation<double> _expandAnimation;
  
  bool _isRising = false;
  bool _isExpanding = false;
  Offset _currentStartPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    
    // Rise animation: circle moves from navbar to center (500ms)
    _riseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _riseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.easeOut),
    );

    // Expand animation: circle scales to cover screen then wipes away (800ms)
    _expandController = AnimationController(
      duration: const Duration(milliseconds:800),
      vsync: this,
    );
    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    _riseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Rise complete, start expand phase
        setState(() {
          _isRising = false;
          _isExpanding = true;
        });
        _expandController.forward(from: 0.0);
      }
    });

    _expandController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Animation complete, notify parent
        setState(() {
          _isExpanding = false;
        });
        widget.onComplete();
      }
    });
  }

  @override
  void didUpdateWidget(CircleRevealTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isAnimating && !oldWidget.isAnimating) {
      // Start new animation
      _currentStartPosition = widget.startPosition;
      setState(() {
        _isRising = true;
        _isExpanding = false;
      });
      _riseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _riseController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRising && !_isExpanding) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

    return AnimatedBuilder(
      animation: Listenable.merge([_riseAnimation, _expandAnimation]),
      builder: (context, child) {
        Offset position;
        double outerSize;
        double innerSize;

        if (_isRising) {
          // Rise phase: move from start to center
          position = Offset.lerp(
            _currentStartPosition,
            screenCenter,
            _riseAnimation.value,
          )!;
          outerSize = 32.0; // Small circle size during rise
          innerSize = 0.0; // Solid circle during rise
        } else {
          // Expand phase: first cover screen (0-0.5), then wipe away as ring (0.5-1.0)
          position = screenCenter;
          final maxDimension = screenSize.longestSide * 1.5;
          
          if (_expandAnimation.value < 0.5) {
            // First half: expand solid circle to cover screen
            outerSize = 32.0 + (maxDimension - 32.0) * (_expandAnimation.value * 2);
            innerSize = 0.0; // Keep solid
          } else {
            // Second half: ring wipes outward to reveal page
            outerSize = maxDimension; // Stay at full size
            final wipeProgress = (_expandAnimation.value - 0.5) * 2;
            innerSize = maxDimension * wipeProgress;
          }
        }

        return Positioned(
          left: position.dx - (outerSize / 2),
          top: position.dy - (outerSize / 2),
          child: SizedBox(
            width: outerSize,
            height: outerSize,
            child: CustomPaint(
              painter: _RingPainter(
                outerRadius: outerSize / 2,
                innerRadius: innerSize / 2,
                isRing: _isExpanding && innerSize > 0,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double outerRadius;
  final double innerRadius;
  final bool isRing;

  _RingPainter({
    required this.outerRadius,
    required this.innerRadius,
    required this.isRing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Create gradient paint
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.lime.shade300,
          Colors.lime.shade500,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
      ..style = PaintingStyle.fill;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.lime.shade400.withValues(alpha: 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isRing ? 40 : 20);
    
    if (isRing) {
      // Draw ring with hole in the middle
      final path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: outerRadius))
        ..addOval(Rect.fromCircle(center: center, radius: innerRadius))
        ..fillType = PathFillType.evenOdd;
      
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, paint);
    } else {
      // Draw solid circle
      canvas.drawCircle(center, outerRadius, shadowPaint);
      canvas.drawCircle(center, outerRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.outerRadius != outerRadius ||
        oldDelegate.innerRadius != innerRadius ||
        oldDelegate.isRing != isRing;
  }
}
