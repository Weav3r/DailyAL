import 'dart:math';

import 'package:flutter/material.dart';

class InterlaceAnimation extends StatefulWidget {
  final ColorScheme colorScheme;
  const InterlaceAnimation({super.key, required this.colorScheme});
  @override
  _InterlaceAnimationState createState() => _InterlaceAnimationState();
}

class _InterlaceAnimationState extends State<InterlaceAnimation>
    with TickerProviderStateMixin {
  static final _shiftTween = Tween<double>(begin: -pi, end: pi);
  static final _aTween = Tween<double>(begin: -10.0, end: 10.0);
  static final _bTween = Tween<double>(begin: -70.0, end: 70.0);
  static final _cTween = Tween<double>(begin: -100.0, end: 100.0);
  static final _dTween = Tween<double>(begin: -200.0, end: 200.0);
  static final _eTween = Tween<double>(begin: -300.0, end: 300.0);

  late ColorTween _lightTween1;
  late ColorTween _lightTween2;
  late ColorTween _glowTween1;
  late ColorTween _glowTween2;

  static final _glowInterval = CurveTween(curve: Interval(0.9, 1.0));

  static final _curve = CurveTween(curve: Curves.easeInOut);

  late AnimationController _shiftController;
  late AnimationController _aController;
  late AnimationController _bController;
  late AnimationController _cController;
  late AnimationController _dController;
  late AnimationController _eController;

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    final init = (int duration, double value) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: duration),
        value: value,
      );
    };

    _shiftController = init(8000, 0.0);
    _aController = init(6000, 0.7);
    _bController = init(4000, 0.3);
    _cController = init(8000, 0.8);
    _dController = init(8000, 0.0);
    _eController = init(8000, 0.6);
    _glowController = init(4000, 0.0);

    final scheme = widget.colorScheme;

    _lightTween1 = ColorTween(
      begin: scheme.primary,
      end: scheme.secondary,
    );

    _lightTween2 = ColorTween(
      begin: scheme.secondary,
      end: scheme.primary,
    );

    _glowTween1 = ColorTween(
      begin: scheme.primary,
      end: scheme.secondary,
    );

    _glowTween2 = ColorTween(
      begin: scheme.secondary,
      end: scheme.primary,
    );

    _shiftController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shiftController.forward(from: 0.0);
      }
    });

    [
      _aController,
      _bController,
      _cController,
      _dController,
      _eController,
      _glowController,
    ].forEach((c) {
      c.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          c.reverse();
        } else if (status == AnimationStatus.dismissed) {
          c.forward();
        }
      });

      c.forward();
    });

    _shiftController.forward();
  }

  @override
  void dispose() {
    _shiftController.dispose();
    _aController.dispose();
    _bController.dispose();
    _cController.dispose();
    _dController.dispose();
    _eController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _shiftController,
          builder: (context, _) {
            return RepaintBoundary(
              child: CustomPaint(
                painter: CirclePainter(
                  shift: _shiftTween.evaluate(_shiftController),
                  a: _aTween.chain(_curve).evaluate(_aController),
                  b: _bTween.chain(_curve).evaluate(_bController),
                  c: _cTween.chain(_curve).evaluate(_cController),
                  d: _dTween.chain(_curve).evaluate(_dController),
                  e: _eTween.chain(_curve).evaluate(_eController),
                  light1: _lightTween1
                      .chain(_glowInterval)
                      .chain(_curve)
                      .evaluate(_glowController)!,
                  light2: _lightTween2
                      .chain(_glowInterval)
                      .chain(_curve)
                      .evaluate(_glowController)!,
                  glow1: _glowTween1
                      .chain(_glowInterval)
                      .chain(_curve)
                      .evaluate(_glowController)!,
                  glow2: _glowTween2
                      .chain(_glowInterval)
                      .chain(_curve)
                      .evaluate(_glowController)!,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  CirclePainter({
    required this.shift,
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.e,
    required this.light1,
    required this.light2,
    required this.glow1,
    required this.glow2,
  });

  final double shift;
  final double a;
  final double b;
  final double c;
  final double d;
  final double e;

  final Color light1;
  final Color light2;
  final Color glow1;
  final Color glow2;

  double getHarmonic(double x, double shift, List<double> components) {
    double y = 0;

    final angle = sin(x + shift);
    for (var i = 0; i < components.length; i++) {
      y += components[i] * angle / (i + 1);
    }

    return y;
  }

  Offset polarToCartesian({required double distance, required double angle}) {
    final x = distance * cos(angle);
    final y = distance * sin(angle);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    var points = <Offset>[];
    for (var i = 0; i <= pi * 2 * 1000; i++) {
      final point = polarToCartesian(
        distance: 110.0 + getHarmonic(i / 1000, shift, [a, b, c, d, e]),
        angle: i / 1000,
      );

      points.add(point);
    }

    path.addPolygon(points, false);

    final glowShader = LinearGradient(
      colors: [
        glow1,
        glow2,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      height: 110.0,
      width: 110.0,
    ));

    final strokeShader = LinearGradient(
      colors: [light1, light2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      height: 110.0,
      width: 110.0,
    ));

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0
      ..shader = glowShader
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 14.0);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..shader = strokeShader
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 2.0);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
