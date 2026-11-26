import 'dart:math';
import 'package:flutter/material.dart';
import 'login_page.dart';

// شاشة البداية: فلاش ضوء أزرق، حلقات HUD بتلف، شبكة خطوط (بلكسس)،
// وفي الآخر لوجو آيرس يظهر بتوهج مع الاسم، وبعدين تسجيل الدخول.
// مرجع التصميم: الفيديو اللي محمود بعته (٢٧ نوفمبر) - معاد بناؤه بالكود.
class IntroSplashScreen extends StatefulWidget {
  const IntroSplashScreen({super.key});

  @override
  State<IntroSplashScreen> createState() => _IntroSplashScreenState();
}

class _IntroSplashScreenState extends State<IntroSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _goNext();
      })
      ..forward();
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _phase(double start, double end) =>
      ((_c.value - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    // مقاسات بتتغير حسب الجهاز: موبايل / لابتوب / تلفزيون
    final double uiScale = shortest < 600 ? 1.0 : (shortest < 1100 ? 1.2 : 1.5);
    final double logoSize = shortest * (size.width > 1100 ? 0.3 : 0.42);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _goNext, // ضغطة في أي مكان بتعدي الأنيميشن
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final flash = _phase(0.0, 0.16);
            final rings = _phase(0.10, 0.52);
            final plexus = _phase(0.48, 0.78);
            final logo = _phase(0.76, 1.0);
            final logoCurve = Curves.easeOutBack.transform(logo);
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: IntroPainter(
                    flash: flash,
                    rings: rings,
                    plexus: plexus,
                    logoGlow: logo,
                    time: _c.value,
                  ),
                ),
                if (logo > 0)
                  Center(
                    child: Opacity(
                      opacity: logo,
                      child: Transform.scale(
                        scale: 0.75 + 0.25 * logoCurve,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'I.R.I.S',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30 * uiScale,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 10 * uiScale,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF4FC3F7)
                                        .withOpacity(0.9 * logo),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 18 * uiScale),
                            Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4FC3F7)
                                        .withOpacity(0.45 * logo),
                                    blurRadius: 60,
                                    spreadRadius: 12,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 18 * uiScale),
                            Text(
                              'Infinity Retinal Intelligence System',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85 * logo),
                                fontSize: 14 * uiScale,
                                letterSpacing: 3.5 * uiScale,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class IntroPainter extends CustomPainter {
  final double flash; // 0..1 فلاش البداية
  final double rings; // 0..1 حلقات HUD
  final double plexus; // 0..1 شبكة الخطوط
  final double logoGlow; // 0..1 توهج تحت اللوجو
  final double time; // الزمن الكلي للحركة المستمرة

  IntroPainter({
    required this.flash,
    required this.rings,
    required this.plexus,
    required this.logoGlow,
    required this.time,
  });

  static const Color _blue = Color(0xFF4FC3F7);
  static const Color _deepBlue = Color(0xFF0277BD);

  // نقاط شبكة البلكسس (نسب من أبعاد الشاشة، ثابتة عشان الشكل ما يترعش)
  static final List<Offset> _plexusPoints = _buildPoints();

  static List<Offset> _buildPoints() {
    final rnd = Random(7);
    return List.generate(26, (_) => Offset(rnd.nextDouble(), rnd.nextDouble()));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide * 0.42;

    // 1) فلاش الضوء الأزرق في البداية
    if (flash > 0 && flash < 1) {
      final flashRadius = size.shortestSide * (0.15 + flash * 0.9);
      final flashOpacity = (1 - flash) * 0.95;
      final gradient = RadialGradient(
        colors: [
          Colors.white.withOpacity(flashOpacity),
          _blue.withOpacity(flashOpacity * 0.7),
          _deepBlue.withOpacity(0.0),
        ],
        stops: const [0.0, 0.35, 1.0],
      );
      canvas.drawCircle(
        center,
        flashRadius,
        Paint()..shader = gradient.createShader(Rect.fromCircle(center: center, radius: flashRadius)),
      );
      // خط ضوء أفقي زي اللي في الفيديو
      final linePaint = Paint()
        ..color = _blue.withOpacity(flashOpacity * 0.8)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawLine(
        Offset(center.dx - flashRadius, center.dy),
        Offset(center.dx + flashRadius, center.dy),
        linePaint,
      );
    }

    // 2) حلقات HUD بتلف (داخلة بحركة)
    if (rings > 0) {
      final ringsScale = Curves.easeOutCubic.transform(rings);
      final ringOpacity = rings.clamp(0.0, 1.0);
      _drawDashedRing(canvas, center, maxR * 0.45 * ringsScale, 24, 4,
          time * 2.2, _blue.withOpacity(0.85 * ringOpacity), 2.4);
      _drawDashedRing(canvas, center, maxR * 0.62 * ringsScale, 30, 3,
          -time * 1.6, _blue.withOpacity(0.55 * ringOpacity), 1.6);
      _drawArcs(canvas, center, maxR * 0.82 * ringsScale, time * 1.1,
          _deepBlue.withOpacity(0.8 * ringOpacity));
      _drawArcs(canvas, center, maxR * 0.97 * ringsScale, -time * 0.8,
          _blue.withOpacity(0.35 * ringOpacity));
      // نقطة مركزية متوهجة
      canvas.drawCircle(
        center,
        4 + 2 * sin(time * 6),
        Paint()
          ..color = Colors.white.withOpacity(0.9 * ringOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // 3) شبكة البلكسس (نقاط وخطوط زرقاء)
    if (plexus > 0) {
      final pts = _plexusPoints
          .map((p) => Offset(p.dx * size.width, p.dy * size.height))
          .toList();
      final linePaint = Paint()
        ..color = _blue.withOpacity(0.28 * plexus)
        ..strokeWidth = 1;
      final maxDist = size.shortestSide * 0.35;
      for (int i = 0; i < pts.length; i++) {
        for (int j = i + 1; j < pts.length; j++) {
          if ((pts[i] - pts[j]).distance < maxDist) {
            canvas.drawLine(pts[i], pts[j], linePaint);
          }
        }
      }
      final dotPaint = Paint()..color = _blue.withOpacity(0.7 * plexus);
      for (final p in pts) {
        canvas.drawCircle(p, 2, dotPaint);
      }
    }

    // 4) توهج أزرق خفيف تحت اللوجو في النهاية
    if (logoGlow > 0) {
      final glow = RadialGradient(
        colors: [
          _blue.withOpacity(0.30 * logoGlow),
          Colors.transparent,
        ],
      );
      final r = maxR * 1.1;
      canvas.drawCircle(
        center,
        r,
        Paint()..shader = glow.createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
  }

  void _drawDashedRing(Canvas canvas, Offset center, double radius,
      int dashCount, int gapCount, double rotation, Color color, double stroke) {
    if (radius <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final total = dashCount + gapCount;
    final sweep = 2 * pi / total;
    for (int i = 0; i < total; i += 2) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        rotation + i * sweep,
        sweep * 0.9,
        false,
        paint,
      );
    }
  }

  void _drawArcs(Canvas canvas, Offset center, double radius, double rotation,
      Color color) {
    if (radius <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final start in [0.0, pi]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        rotation + start,
        pi / 2.5,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IntroPainter oldDelegate) => true;
}
