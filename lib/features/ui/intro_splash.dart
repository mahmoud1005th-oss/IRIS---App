import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show AuthGate;
import 'login_page.dart';

// شاشة البداية (V3.4): شاشة سودا، أيقونة آيرس، تحتها "I R I S" متحفورة بليزر،
// وتحتها الاسم الكامل بالإنجليزي. من غير شبكة الأعصاب. وبعدها تفتح على شاشة الدخول.
class IntroSplashScreen extends StatefulWidget {
  const IntroSplashScreen({super.key});

  @override
  State<IntroSplashScreen> createState() => _IntroSplashScreenState();
}

class _IntroSplashScreenState extends State<IntroSplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration kIntroDuration = Duration(milliseconds: 5600);
  static const String kFullName = 'Infinity Retinal Intelligence System';

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

  // مقطع من الزمن الكلي (٠..١) بيتحول لتقدم ٠..١
  double _seg(double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final k =
        (min(size.width, size.height * 0.62) / 390).clamp(0.8, 2.0).toDouble();
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goNext,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final logoP = _seg(0.0, 0.2, Curves.easeOutCubic);
            final irisP = _seg(0.22, 0.52);
            final nameP = _seg(0.56, 0.86);
            final fade = 1 - _seg(0.94, 1.0);
            return Opacity(
              opacity: fade,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: logoP,
                      child: Transform.scale(
                        scale: 0.8 + 0.2 * logoP,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: kIrisAccent.withOpacity(0.25 * logoP),
                                  blurRadius: 60 * k),
                            ],
                          ),
                          child: IrisLogo(size: 150 * k),
                        ),
                      ),
                    ),
                    SizedBox(height: 34 * k),
                    SizedBox(
                      width: 320 * k,
                      height: 64 * k,
                      child: CustomPaint(
                        painter: LaserTextPainter(
                          text: 'I R I S',
                          fontSize: 46 * k,
                          letterSpacing: 8 * k,
                          weight: FontWeight.w800,
                          progress: irisP,
                          color: const Color(0xFFDCE6EE),
                          seed: 3,
                        ),
                      ),
                    ),
                    SizedBox(height: 10 * k),
                    SizedBox(
                      width: 360 * k,
                      height: 30 * k,
                      child: CustomPaint(
                        painter: LaserTextPainter(
                          text: kFullName,
                          fontSize: 14 * k,
                          letterSpacing: 1.6 * k,
                          weight: FontWeight.w600,
                          progress: nameP,
                          color: kIrisAccent,
                          seed: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// نص بيتحفر بشعاع ليزر: الشعاع بيمشي من الشمال لليمين، ورا الشعاع الحروف
// بتبقى ساخنة (برتقالي-أبيض متوهج) وبعدين تبرد وتتحول لنقش فاتح بظل غائر.
// فيه شرار صغير بيتطاير من نقطة الشعاع.
class LaserTextPainter extends CustomPainter {
  final String text;
  final double fontSize;
  final double letterSpacing;
  final FontWeight weight;
  final double progress; // ٠..١
  final Color color;
  final int seed;
  const LaserTextPainter({
    required this.text,
    required this.fontSize,
    required this.letterSpacing,
    required this.weight,
    required this.progress,
    required this.color,
    required this.seed,
  });

  TextPainter _tp(Color c, {List<Shadow>? shadows}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: c,
          fontFamily: 'Roboto',
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final base = _tp(color);
    final origin =
        Offset((size.width - base.width) / 2, (size.height - base.height) / 2);
    final x0 = origin.dx, x1 = origin.dx + base.width;
    final laserX = x0 + (x1 - x0) * progress;
    final done = progress >= 1.0;
    final cy = origin.dy + base.height / 2;

    // الجزء المتحفور: ظل غائر + حافة مضيئة + لون النقش
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, laserX, size.height));
    _tp(Colors.black.withOpacity(0.9))
        .paint(canvas, origin + const Offset(1.4, 1.4));
    _tp(Colors.white.withOpacity(0.22))
        .paint(canvas, origin + const Offset(-0.8, -0.8));
    _tp(color.withOpacity(0.92)).paint(canvas, origin);
    canvas.restore();

    // التوهج الساخن ورا الشعاع (بيبرد مع المسافة)
    final hotW = fontSize * 2.2;
    final hotL = max(x0 - 4, laserX - hotW);
    if (laserX > hotL) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(hotL, 0, laserX, size.height));
      final rect = Rect.fromLTRB(hotL, 0, laserX, size.height);
      final hot = _tp(Colors.white);
      canvas.saveLayer(rect, Paint());
      hot.paint(canvas, origin);
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.srcIn
          ..shader = const LinearGradient(
            colors: [Color(0x009DB9CE), Color(0xCC9DB9CE), Color(0xFFEAF4FB)],
            stops: [0.0, 0.6, 1.0],
          ).createShader(rect),
      );
      canvas.restore();
      canvas.restore();
    }

    if (!done) {
      // نقطة الشعاع: خط ضوء رأسي رفيع + توهج
      final glow = Paint()
        ..color = const Color(0xFF9DB9CE).withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(laserX, cy), fontSize * 0.45, glow);
      canvas.drawLine(
          Offset(laserX, origin.dy - 4),
          Offset(laserX, origin.dy + base.height + 4),
          Paint()
            ..color = const Color(0xFFEAF4FB)
            ..strokeWidth = 1.6);
      canvas.drawCircle(Offset(laserX, cy), 3.2, Paint()..color = Colors.white);
      // شرار
      final r = Random(seed);
      for (var i = 0; i < 16; i++) {
        final ang = -pi / 2 + (r.nextDouble() - 0.5) * pi * 1.1;
        final life = ((progress * 60 + i * 0.37) % 1.0);
        final dist = life * fontSize * (0.5 + r.nextDouble() * 1.1);
        final p = Offset(laserX - dist * 0.4 + cos(ang) * dist * 0.6,
            cy + sin(ang) * dist + life * life * fontSize * 0.5);
        canvas.drawCircle(
            p,
            1.3 * (1 - life) + 0.3,
            Paint()
              ..color = Color.lerp(
                      const Color(0xFFF4F8FB), const Color(0xFF9DB9CE), life)!
                  .withOpacity(1 - life));
      }
    }
  }

  @override
  bool shouldRepaint(covariant LaserTextPainter old) =>
      old.progress != progress;
}
