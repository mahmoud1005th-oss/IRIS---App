import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show AuthGate;
import 'login_page.dart';

// شاشة البداية (أول تشغيل بس): نفس فيديو المرجع اللي محمود بعته (٢٧ نوفمبر):
// فلاش أزرق بخط ضوء أفقي، حلقات HUD متحدة المركز بتلف (تيكس ونقط وأقواس)،
// زووم جوه الحلقة، شبكة بلكسس بتتجمع، وفي الآخر الشبكة بتلف متصلة بالكامل
// حوالين علامة لوجو آيرس بخطوط زرقاء-رمادية بدل الأبيض والأسود.
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
      duration: const Duration(milliseconds: 8000), // نفس طول الفيديو
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _goNext();
      })
      ..forward();
  }

  // نعلّم إن الأنيميشن اتشاف عشان ميظهرش تاني
  Future<void> _markIntroSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthGate.kIntroSeenKey, true);
    } catch (_) {}
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _markIntroSeen();
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
            final flash = _phase(0.0, 0.10);
            final rings = _phase(0.08, 0.40);
            final zoom = _phase(0.42, 0.58);
            final plexus = _phase(0.55, 0.75);
            final converge = _phase(0.75, 0.92);
            final logo = _phase(0.82, 1.0);
            final logoCurve = Curves.easeOutBack.transform(logo);
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: IntroPainter(
                    flash: flash,
                    rings: rings,
                    zoom: zoom,
                    plexus: plexus,
                    converge: converge,
                    logoGlow: logo,
                    time: _c.value * 8.0, // الزمن بالثواني زي الفيديو
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
                                    color: const Color(0xFF9DB9CE)
                                        .withOpacity(0.45 * logo),
                                    blurRadius: 60,
                                    spreadRadius: 12,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                // علامة اللوجو بخطوط زرقاء-رمادية بدل الأبيض
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.matrix([
                                    0.616, 0, 0, 0, 0, //
                                    0, 0.725, 0, 0, 0, //
                                    0, 0, 0.808, 0, 0, //
                                    0, 0, 0, 1, 0, //
                                  ]),
                                  child: Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.cover,
                                  ),
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
  final double zoom; // 0..1 الزووم جوه الحلقة
  final double plexus; // 0..1 شبكة الخطوط
  final double converge; // 0..1 تجمّع الشبكة حوالين المركز
  final double logoGlow; // 0..1 توهج تحت اللوجو
  final double time; // الزمن بالثواني

  IntroPainter({
    required this.flash,
    required this.rings,
    required this.zoom,
    required this.plexus,
    required this.converge,
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

    // خلفية زرقاء غامقة خفيفة (الڤينييت بتاع الفيديو)
    final bg = RadialGradient(
      radius: 1.25,
      colors: [
        const Color(0xFF0D2B4D).withOpacity(0.55),
        Colors.black,
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = bg.createShader(Rect.fromCircle(
            center: center, radius: size.longestSide * 0.75)),
    );

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
        Paint()
          ..shader = gradient
              .createShader(Rect.fromCircle(center: center, radius: flashRadius)),
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

    // 2) حلقات HUD متحدة المركز بتلف، وبعدين زووم جواها
    if (rings > 0) {
      final build = Curves.easeOutCubic.transform(rings);
      final zoomScale = 1 + 6 * Curves.easeIn.transform(zoom);
      final fade = (1 - zoom).clamp(0.0, 1.0);
      final ringOpacity = build * fade;

      if (ringOpacity > 0) {
        final r = maxR * build * zoomScale;
        // حلقة خارجية فيها أقواس مضيئة على الأطراف
        _drawArcs(canvas, center, r * 0.97, time * 0.8,
            _blue.withOpacity(0.35 * ringOpacity));
        _drawArcs(canvas, center, r * 0.90, -time * 1.1,
            _deepBlue.withOpacity(0.8 * ringOpacity));
        // حلقة التيكس (علامات صغيرة على المحيط) - أوضح حاجة في الفيديو
        _drawTickRing(canvas, center, r * 0.78, 60, maxR * 0.045,
            -time * 1.2, _blue.withOpacity(0.8 * ringOpacity), 2.2);
        // حلقة نقط
        _drawDotRing(canvas, center, r * 0.66, 40, time * 0.5,
            _blue.withOpacity(0.5 * ringOpacity));
        // حلقة متقطعة
        _drawDashedRing(canvas, center, r * 0.52, 24, 4, time * 2.2,
            _blue.withOpacity(0.85 * ringOpacity), 2.4);
        // الحلقة الداخلية المضيئة
        canvas.drawCircle(
          center,
          r * 0.38,
          Paint()
            ..color = _blue.withOpacity(0.9 * ringOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        // نقطة مركزية متوهجة
        canvas.drawCircle(
          center,
          4 + 2 * sin(time * 6),
          Paint()
            ..color = Colors.white.withOpacity(0.9 * ringOpacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      // أثناء الزووم: حلقة صغيرة بعيدة في النص (إحساس النفق)
      if (zoom > 0 && zoom < 1) {
        final tunnel = sin(zoom * pi); // تظهر وتختفي نص الزووم
        canvas.drawCircle(
          center,
          maxR * 0.16 * (1 - 0.5 * zoom),
          Paint()
            ..color = _blue.withOpacity(0.7 * tunnel)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        _drawTickRing(canvas, center, maxR * 0.22 * (1 - 0.4 * zoom), 24,
            maxR * 0.02, time * 2, _blue.withOpacity(0.5 * tunnel), 1.4);
      }
    }

    // 3) شبكة البلكسس: نقاط وخطوط، وبعدين بتتجمع في دايرة بتلف متصلة كلها ببعض
    if (plexus > 0) {
      final c = Curves.easeInOut.transform(converge);
      final n = _plexusPoints.length;
      final List<Offset> pts = [];
      for (int i = 0; i < n; i++) {
        final p = _plexusPoints[i];
        // موضع حر مع انجراف خفيف
        final drift = Offset(
          (p.dx + 0.03 * sin(time * 0.7 + i * 1.7)) * size.width,
          (p.dy + 0.03 * cos(time * 0.9 + i * 2.3)) * size.height,
        );
        // الموضع المستهدف: دايرة منتظمة بتلف حوالين المركز
        final ang = i * 2 * pi / n + time * 0.45;
        final target = center +
            Offset(cos(ang), sin(ang)) * maxR * 0.72;
        pts.add(Offset.lerp(drift, target, c)!);
      }

      if (c < 0.999) {
        // قبل التجمع: توصيل بالمسافة زي البلكسس العادي
        final linePaint = Paint()
          ..color = _blue.withOpacity(0.28 * plexus * (1 - c))
          ..strokeWidth = 1;
        final maxDist = size.shortestSide * 0.35;
        for (int i = 0; i < pts.length; i++) {
          for (int j = i + 1; j < pts.length; j++) {
            if ((pts[i] - pts[j]).distance < maxDist) {
              canvas.drawLine(pts[i], pts[j], linePaint);
            }
          }
        }
      }
      if (c > 0.001) {
        // بعد التجمع: كل النقاط متصلة ببعضها بالكامل
        final fullPaint = Paint()
          ..color = _blue.withOpacity(0.16 * plexus * c)
          ..strokeWidth = 0.8;
        for (int i = 0; i < pts.length; i++) {
          for (int j = i + 1; j < pts.length; j++) {
            canvas.drawLine(pts[i], pts[j], fullPaint);
          }
        }
      }

      final dotPaint = Paint()..color = _blue.withOpacity(0.7 * plexus);
      final brightPaint = Paint()
        ..color = Colors.white.withOpacity(0.9 * plexus * c)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      for (int i = 0; i < pts.length; i++) {
        canvas.drawCircle(pts[i], 2, dotPaint);
        // كل تالت نقطة تبقى مضيئة في مرحلة التجمع
        if (i % 3 == 0) canvas.drawCircle(pts[i], 3, brightPaint);
      }
    }

    // 4) توهج أزرق خفيف تحت اللوجو في النهاية
    if (logoGlow > 0) {
      final glow = RadialGradient(
        colors: [
          const Color(0xFF9DB9CE).withOpacity(0.30 * logoGlow),
          Colors.transparent,
        ],
      );
      final r = maxR * 1.1;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader =
              glow.createShader(Rect.fromCircle(center: center, radius: r)),
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

  void _drawTickRing(Canvas canvas, Offset center, double radius,
      int tickCount, double tickLen, double rotation, Color color,
      double stroke) {
    if (radius <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < tickCount; i++) {
      final a = rotation + i * 2 * pi / tickCount;
      final p1 = center + Offset(cos(a), sin(a)) * radius;
      final p2 = center + Offset(cos(a), sin(a)) * (radius + tickLen);
      canvas.drawLine(p1, p2, paint);
    }
  }

  void _drawDotRing(Canvas canvas, Offset center, double radius, int dotCount,
      double rotation, Color color) {
    if (radius <= 0) return;
    final paint = Paint()..color = color;
    for (int i = 0; i < dotCount; i++) {
      final a = rotation + i * 2 * pi / dotCount;
      canvas.drawCircle(center + Offset(cos(a), sin(a)) * radius, 1.4, paint);
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
