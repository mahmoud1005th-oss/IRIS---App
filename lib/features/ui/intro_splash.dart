import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show AuthGate;
import 'login_page.dart';

// شاشة البداية: مطابقة لفيديو المرجع اللي محمود بعته (٢٧ نوفمبر) مرحلة بمرحلة:
// ١) ظلام أزرق ونقطة ضوء صغيرة (٠ - ٠٫٣٥ ث)
// ٢) فلاش أبيض-أزرق بخط ضوء أفقي قوي (٠٫٣٥ - ٠٫٧٥ ث)
// ٣) حلقات HUD متحدة المركز بتظهر واحدة ورا التانية (٠٫٧٥ - ٢ ث)
// ٤) الحلقات ثابتة وبتلف ببطء في اتجاهين (٢ - ٤٫٢ ث)
// ٥) زووم جوه الحلقة: الحلقات بتكبر وبتعدي من ورا الكاميرا وحلقة صغيرة بتبعد (٤٫٢ - ٥٫٣ ث)
// ٦) جزيئات بتطفو ونقطة مركزية متوهجة (٥٫٣ - ٦٫١ ث)
// ٧) شبكة بلكسس بتكبر على الشاشة كلها، شعاع بيلمع، وبعدين بتتجمع في نواة مضيئة (٦٫١ - ٧٫٦ ث)
// ٨) النواة بتحول للوجو آيرس بخطوط زرقاء-رمادية مع I.R.I.S والاسم الكامل (٧٫٦ - ٨٫٦ ث)
class IntroSplashScreen extends StatefulWidget {
  const IntroSplashScreen({super.key});

  @override
  State<IntroSplashScreen> createState() => _IntroSplashScreenState();
}

class _IntroSplashScreenState extends State<IntroSplashScreen>
    with SingleTickerProviderStateMixin {
  // طول الأنيميشن كله: ٧٫٦ ث زي الفيديو + ثانية لظهور اللوجو
  static const Duration kIntroDuration = Duration(milliseconds: 8600);

  late final AnimationController _c;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kIntroDuration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _goNext();
      })
      ..forward();
  }

  // نعلّم إن الأنيميشن اتشاف (بتشتغل لما AuthGate.kIntroFirstLaunchOnly يبقى true)
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
            final logo = _phase(0.890, 1.0);
            final logoCurve = Curves.easeOutBack.transform(logo);
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: IntroPainter(
                    dotIn: _phase(0.0, 0.035),
                    flash: _phase(0.035, 0.088),
                    build: _phase(0.088, 0.232),
                    zoom: _phase(0.490, 0.617),
                    driftIn: _phase(0.60, 0.66),
                    driftOut: _phase(0.80, 0.86),
                    coreDot: _phase(0.63, 0.68),
                    plexus: _phase(0.700, 0.800),
                    converge: _phase(0.800, 0.925),
                    beam: _phase(0.775, 0.800),
                    core: _phase(0.840, 0.945),
                    logoGlow: logo,
                    time: _c.value *
                        (kIntroDuration.inMilliseconds / 1000.0), // بالثواني
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
  final double dotIn; // 0..1 النقطة الأولى
  final double flash; // 0..1 فلاش البداية
  final double build; // 0..1 بناء حلقات HUD بالتتابع
  final double zoom; // 0..1 الزووم جوه الحلقات
  final double driftIn; // دخول الجزيئات
  final double driftOut; // خروج الجزيئات
  final double coreDot; // النقطة المركزية المتوهجة بعد الزووم
  final double plexus; // 0..1 نمو شبكة البلكسس
  final double converge; // 0..1 تجمع الشبكة في النواة
  final double beam; // 0..1 الشعاع اللماع
  final double core; // 0..1 توهج النواة النهائي
  final double logoGlow; // 0..1 مرحلة اللوجو
  final double time; // الزمن بالثواني

  IntroPainter({
    required this.dotIn,
    required this.flash,
    required this.build,
    required this.zoom,
    required this.driftIn,
    required this.driftOut,
    required this.coreDot,
    required this.plexus,
    required this.converge,
    required this.beam,
    required this.core,
    required this.logoGlow,
    required this.time,
  });

  static const Color _blue = Color(0xFF4FC3F7);
  static const Color _bright = Color(0xFF9FE4FF);
  static const Color _deep = Color(0xFF0277BD);

  // نقاط شبكة البلكسس (نسب من أبعاد الشاشة، ثابتة عشان الشكل ما يترعش)
  static final List<Offset> _plexusPoints = _buildPoints();
  // جزيئات الطفو بين المراحل
  static final List<Offset> _driftPoints = _buildDrift();

  static List<Offset> _buildPoints() {
    final rnd = Random(7);
    return List.generate(55, (_) => Offset(rnd.nextDouble(), rnd.nextDouble()));
  }

  static List<Offset> _buildDrift() {
    final rnd = Random(11);
    return List.generate(16, (_) => Offset(rnd.nextDouble(), rnd.nextDouble()));
  }

  double _ringT(int i) =>
      Curves.easeOutCubic.transform((build * 1.9 - i * 0.11).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide * 0.33;

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

    // 1) نقطة الضوء الصغيرة قبل الفلاش
    if (dotIn > 0 && flash < 1) {
      final o = dotIn * (1 - flash);
      canvas.drawCircle(
        center,
        2.6,
        Paint()
          ..color = Colors.white.withOpacity(0.9 * o)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // 2) فلاش الضوء الأزرق بخط أفقي قوي (زي أول الفيديو)
    if (flash > 0) {
      final env = pow(sin(pi * flash), 0.8).toDouble(); // قمة في نص المرحلة
      if (env > 0.01) {
        final flashRadius = size.shortestSide * (0.12 + flash * 0.85);
        final gradient = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.95 * env),
            _blue.withOpacity(0.7 * env),
            _deep.withOpacity(0.0),
          ],
          stops: const [0.0, 0.35, 1.0],
        );
        canvas.drawCircle(
          center,
          flashRadius,
          Paint()
            ..shader = gradient.createShader(
                Rect.fromCircle(center: center, radius: flashRadius)),
        );
        // خط الضوء الأفقي
        canvas.drawLine(
          Offset(0, center.dy),
          Offset(size.width, center.dy),
          Paint()
            ..color = _bright.withOpacity(0.85 * env)
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );
        // توهج أفقي أعرض وأخف
        canvas.drawLine(
          Offset(size.width * 0.2, center.dy),
          Offset(size.width * 0.8, center.dy),
          Paint()
            ..color = _blue.withOpacity(0.5 * env)
            ..strokeWidth = 8
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
        );
      }
    }

    // 3) حلقات HUD: بتظهر واحدة ورا التانية، ثابتة شوية، وبعدين زووم جواها
    if (build > 0) {
      final zoomScale = 1 + 8 * Curves.easeInCubic.transform(zoom);
      final fade = pow(1 - zoom, 1.15).toDouble().clamp(0.0, 1.0);
      if (fade > 0.01) {
        final zs = zoomScale;
        // حلقة خارجية متقطعة خافتة بره التشكيلة
        _drawDashedRing(canvas, center, maxR * 1.14 * zs, 48, 12, -time * 0.06,
            _blue.withOpacity(0.15 * _ringT(0) * fade), 1.1);
        // الحلقة الخارجية الرفيعة المستمرة (أول حاجة بتظهر في الفيديو)
        final t1 = _ringT(1);
        if (t1 > 0) {
          canvas.drawCircle(
            center,
            maxR * 1.00 * zs * (0.8 + 0.2 * t1),
            Paint()
              ..color = _blue.withOpacity(0.30 * t1 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
          // قوسين لامعين على أطراف الحلقة الخارجية
          _drawArcs(canvas, center, maxR * 1.00 * zs, 2, 0.5, time * 0.18,
              _bright.withOpacity(0.85 * t1 * fade), 3);
        }
        // حلقة النقط الصغيرة
        _drawDotRing(canvas, center, maxR * 0.91 * zs, 56, -time * 0.10,
            _blue.withOpacity(0.45 * _ringT(2) * fade), 1.3);
        // حلقة التيكس الكتيفة - أوضح عنصر في الفيديو
        _drawTickRing(canvas, center, maxR * 0.83 * zs, 72, maxR * 0.05,
            time * 0.25, _blue.withOpacity(0.75 * _ringT(3) * fade), 2.0);
        // حلقة الدوائر الصغيرة المفرغة (صف الـ ooooo في الفيديو)
        _drawHollowRing(canvas, center, maxR * 0.74 * zs, 40, -time * 0.20,
            _bright.withOpacity(0.80 * _ringT(4) * fade), 1.2);
        // قوسين سميكين لامعين بيلفوا عكس الاتجاه
        _drawArcs(canvas, center, maxR * 0.65 * zs, 2, 1.3, -time * 0.40,
            _blue.withOpacity(0.90 * _ringT(5) * fade), 3.5);
        // حلقة متقطعة سريعة
        _drawDashedRing(canvas, center, maxR * 0.55 * zs, 36, 8, time * 0.60,
            _blue.withOpacity(0.80 * _ringT(6) * fade), 2.0);
        // الحلقة الداخلية المضيئة حوالين مركز غامق
        final t8 = _ringT(7);
        if (t8 > 0) {
          canvas.drawCircle(
            center,
            maxR * 0.38 * zs * (1 + 0.02 * sin(time * 3)),
            Paint()
              ..color = _bright.withOpacity(0.95 * t8 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
        }
        // جزيئات صغيرة مبعثرة حوالين الحلقات زي الفيديو
        _drawAmbient(canvas, size, 0.35 * fade * build);
      }

      // أثناء الزووم: حلقة تيكس صغيرة بتبعد قدامنا (إحساس النفق)
      if (zoom > 0.25 && zoom < 1) {
        final zt = ((zoom - 0.25) / 0.75).clamp(0.0, 1.0);
        final tunnel = sin(zt * pi);
        final rr = maxR * (0.55 - 0.40 * zt);
        if (rr > 0) {
          canvas.drawCircle(
            center,
            rr,
            Paint()
              ..color = _blue.withOpacity(0.5 * tunnel)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
          _drawTickRing(canvas, center, rr, 24, maxR * 0.025, time * 1.5,
              _bright.withOpacity(0.65 * tunnel), 2.2);
        }
      }
    }

    // 4) جزيئات بتطفو بهدوء بعد الزووم (قبل الشبكة)
    final driftO = driftIn * (1 - driftOut);
    if (driftO > 0) {
      final paint = Paint()..color = _blue.withOpacity(0.45 * driftO);
      for (int i = 0; i < _driftPoints.length; i++) {
        final p = _driftPoints[i];
        final dx = (p.dx + 0.02 * sin(time * 0.6 + i * 2.1)) * size.width;
        final dy = (p.dy + 0.03 * cos(time * 0.4 + i * 1.3)) * size.height;
        canvas.drawCircle(Offset(dx, dy), i % 4 == 0 ? 1.8 : 1.1, paint);
      }
    }

    // 5) النقطة المركزية المتوهجة: بتظهر بعد الزووم وبتكبر مع التجمع
    if (coreDot > 0 && logoGlow < 0.6) {
      final grow = 1 + 3.5 * converge;
      canvas.drawCircle(
        center,
        (2.4 + 1.1 * sin(time * 4)) * grow,
        Paint()
          ..color = Colors.white.withOpacity(0.9 * coreDot)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }

    // 6) شبكة البلكسس: بتغطي الشاشة، وبعدين بتتجمع في النواة
    if (plexus > 0) {
      final grow = Curves.easeOutCubic.transform(plexus);
      final c = Curves.easeInOut.transform(converge);
      final n = _plexusPoints.length;
      final List<Offset> pts = [];
      final rnd = Random(21);
      for (int i = 0; i < n; i++) {
        final p = _plexusPoints[i];
        // موضع حر مع انجراف خفيف زي الفيديو
        final drift = Offset(
          (p.dx + 0.03 * sin(time * 0.7 + i * 1.7)) * size.width,
          (p.dy + 0.03 * cos(time * 0.9 + i * 2.3)) * size.height,
        );
        // هدف التجمع: نقطة قريبة من المركز (الشبكة بتنهار في النواة)
        final target = center +
            Offset((rnd.nextDouble() - 0.5), (rnd.nextDouble() - 0.5)) *
                maxR *
                0.25;
        pts.add(Offset.lerp(drift, target, c)!);
      }

      // التوصيل بالمسافة زي البلكسس العادي
      final netFade = (1 - Curves.easeIn.transform(c)).clamp(0.0, 1.0);
      if (netFade > 0.01) {
        final linePaint = Paint()
          ..color = _blue.withOpacity(0.30 * grow * netFade)
          ..strokeWidth = 1;
        final maxDist = size.shortestSide * 0.40;
        for (int i = 0; i < pts.length; i++) {
          for (int j = i + 1; j < pts.length; j++) {
            if ((pts[i] - pts[j]).distance < maxDist) {
              canvas.drawLine(pts[i], pts[j], linePaint);
            }
          }
        }
      }

      // أثناء التجمع: الكتلة اللي حوالين المركز بتبقى متصلة كلها ببعض
      if (c > 0.2 && c < 0.98) {
        final cc = ((c - 0.2) / 0.78).clamp(0.0, 1.0);
        final clusterFade = (1 - Curves.easeIn.transform((c - 0.7) / 0.3))
            .clamp(0.0, 1.0);
        final idx = List<int>.generate(n, (i) => i)
          ..sort((a, b) => (pts[a] - center)
              .distance
              .compareTo((pts[b] - center).distance));
        final fullPaint = Paint()
          ..color = _bright.withOpacity(0.20 * cc * clusterFade)
          ..strokeWidth = 0.8;
        for (int a = 0; a < 14; a++) {
          for (int b = a + 1; b < 14; b++) {
            canvas.drawLine(pts[idx[a]], pts[idx[b]], fullPaint);
          }
        }
      }

      // العقد نفسها
      final dotPaint = Paint()
        ..color = _blue.withOpacity(0.65 * grow * (1 - c * 0.7));
      final brightPaint = Paint()
        ..color = _bright.withOpacity(0.85 * grow * (1 - c * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      for (int i = 0; i < pts.length; i++) {
        canvas.drawCircle(pts[i], 1.6, dotPaint);
        if (i % 5 == 0) canvas.drawCircle(pts[i], 2.6, brightPaint);
      }
    }

    // 7) الشعاع اللماع اللي بيعدي قبل النهاية (موجود في الفيديو حوالي ٦٫٧٥ ث)
    if (beam > 0 && beam < 1) {
      final o = sin(pi * beam);
      final y = center.dy - (1 - beam) * size.height * 0.45;
      canvas.save();
      canvas.translate(size.width / 2, y);
      canvas.rotate(-0.18); // ميل خفيف زي الفيديو
      canvas.drawLine(
        Offset(-size.width * 0.6, 0),
        Offset(size.width * 0.6, 0),
        Paint()
          ..color = _bright.withOpacity(0.75 * o)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      canvas.restore();
    }

    // 8) توهج النواة النهائي بخط أفقي (آخر مشهد في الفيديو)
    if (core > 0) {
      final o = Curves.easeOut.transform(core) * (1 - 0.35 * logoGlow);
      final r = size.shortestSide * 0.55;
      final glow = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.95 * o),
          _blue.withOpacity(0.55 * o),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = glow.createShader(Rect.fromCircle(center: center, radius: r)),
      );
      canvas.drawLine(
        Offset(0, center.dy),
        Offset(size.width, center.dy),
        Paint()
          ..color = _bright.withOpacity(0.6 * o)
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // 9) هالة اللوجو: دايرة عقد متصلة كلها ببعض بتلف بهدوء (البلكسس المتصل الكامل)
    if (logoGlow > 0) {
      const nHalo = 18;
      final haloR = maxR * 0.78;
      final List<Offset> halo = [];
      for (int i = 0; i < nHalo; i++) {
        final a = i * 2 * pi / nHalo + time * 0.3;
        halo.add(center + Offset(cos(a), sin(a)) * haloR);
      }
      final haloPaint = Paint()
        ..color = const Color(0xFF9DB9CE).withOpacity(0.08 * logoGlow)
        ..strokeWidth = 0.8;
      for (int i = 0; i < nHalo; i++) {
        for (int j = i + 1; j < nHalo; j++) {
          canvas.drawLine(halo[i], halo[j], haloPaint);
        }
      }
      final haloDot = Paint()
        ..color = _bright.withOpacity(0.55 * logoGlow);
      for (final p in halo) {
        canvas.drawCircle(p, 1.8, haloDot);
      }
    }
  }

  // جزيئات صغيرة مبعثرة حوالين تشكيلة الحلقات
  void _drawAmbient(Canvas canvas, Size size, double opacity) {
    if (opacity <= 0.01) return;
    final rnd = Random(31);
    final paint = Paint()..color = _blue.withOpacity(opacity);
    for (int i = 0; i < 10; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 1.0, paint);
    }
  }

  void _drawDashedRing(Canvas canvas, Offset center, double radius,
      int dashCount, int gapCount, double rotation, Color color, double stroke) {
    if (radius <= 0 || color.opacity <= 0.01) return;
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
    if (radius <= 0 || color.opacity <= 0.01) return;
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
      double rotation, Color color, double dotR) {
    if (radius <= 0 || color.opacity <= 0.01) return;
    final paint = Paint()..color = color;
    for (int i = 0; i < dotCount; i++) {
      final a = rotation + i * 2 * pi / dotCount;
      canvas.drawCircle(center + Offset(cos(a), sin(a)) * radius, dotR, paint);
    }
  }

  // حلقة دوائر مفرغة صغيرة (صف الـ ooooo اللي في الفيديو)
  void _drawHollowRing(Canvas canvas, Offset center, double radius,
      int count, double rotation, Color color, double stroke) {
    if (radius <= 0 || color.opacity <= 0.01) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final cr = (radius * 0.022).clamp(1.6, 4.0);
    for (int i = 0; i < count; i++) {
      final a = rotation + i * 2 * pi / count;
      canvas.drawCircle(center + Offset(cos(a), sin(a)) * radius, cr, paint);
    }
  }

  // أقواس لامعة موزعة بالتساوي على الحلقة
  void _drawArcs(Canvas canvas, Offset center, double radius, int count,
      double sweepFrac, double rotation, Color color, double stroke) {
    if (radius <= 0 || color.opacity <= 0.01) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final sweep = 2 * pi * sweepFrac / count;
    for (int i = 0; i < count; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        rotation + i * 2 * pi / count,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IntroPainter oldDelegate) => true;
}
