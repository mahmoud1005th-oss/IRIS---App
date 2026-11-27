import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login_page.dart' show kIrisAccent, IrisLogo;

// إنترو جديد (V3.4): "فتحة العدسة". شاشة سودا، نقطة ضوء، خط نور بيتمد ويتفتح
// على شكل عين، جواها حلقات HUD وشفرات فتحة عدسة بتلف، النواة بتولع وموجة ضوء
// بتطلع، والشفرات بتتجمع وتتحول للوجو آيرس، وبعدها الاسم والتحية.
// خفيف: خطوط وأقواس بس، من غير بلور ولا طبقات تقيلة، عشان مفيش لاج.
class IntroLegend extends StatefulWidget {
  final VoidCallback? onDone;
  final double? freeze; // ٠..١ للصور الثابتة
  final String name;
  const IntroLegend({super.key, this.onDone, this.freeze, this.name = 'محمود'});
  @override
  State<IntroLegend> createState() => _IntroLegendState();
}

class _IntroLegendState extends State<IntroLegend> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 6200));

  @override
  void initState() {
    super.initState();
    if (widget.freeze != null) {
      _c.value = widget.freeze!;
    } else {
      _c.addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone?.call();
      });
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double seg(double v, double a, double b, [Curve c = Curves.linear]) => c.transform(((v - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onDone?.call(),
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          final k = (math.min(w, h * 0.62) / 390).clamp(0.8, 2.0).toDouble();
          final center = Offset(w / 2, h * 0.42);
          return AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final v = _c.value;
              final draw = seg(v, 0.28, 0.52, Curves.easeInOutCubic); // اللوجو بيترسم جوه العين
              final logoScale = 0.62 + 0.38 * seg(v, 0.60, 0.78, Curves.easeOutBack);
              final textP = seg(v, 0.74, 0.90, Curves.easeOutCubic);
              final greetP = seg(v, 0.86, 0.97, Curves.easeOut);
              final fade = 1 - seg(v, 0.97, 1.0);
              return Opacity(
                opacity: fade,
                child: Stack(children: [
                  Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _LensPainter(v, center, 150 * k, draw, logoScale)))),
                  if (v > 0.28)
                    Positioned(
                      left: center.dx - 75 * k,
                      top: center.dy - 75 * k,
                      child: Transform.scale(
                        scale: logoScale,
                        child: ClipPath(
                          clipper: _SweepClipper(draw),
                          child: IrisLogo(size: 150 * k),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: center.dy + 110 * k,
                    child: Opacity(
                      opacity: textP,
                      child: Center(
                        child: Text('I R I S', style: TextStyle(color: const Color(0xFFEAF4FB), fontSize: 40 * k, fontWeight: FontWeight.w800, letterSpacing: (26 - 18 * textP) * k, shadows: [Shadow(color: kIrisAccent.withOpacity(.7 * textP), blurRadius: 18)])),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: center.dy + 166 * k,
                    child: Opacity(
                      opacity: greetP,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - greetP)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: FittedBox(fit: BoxFit.scaleDown, child: Text('Infinity Retinal Intelligence System', style: TextStyle(color: kIrisAccent, fontSize: 13.5 * k, letterSpacing: 2.6 * k, fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                  ),
                ]),
              );
            },
          );
        }),
      ),
    );
  }
}

class _LensPainter extends CustomPainter {
  final double v;
  final Offset c;
  final double R; // قطر اللوجو تقريباً
  final double draw, logoScale;
  _LensPainter(this.v, this.c, this.R, this.draw, this.logoScale);

  static double seg(double v, double a, double b, [Curve cu = Curves.linear]) => cu.transform(((v - a) / (b - a)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size s) {
    final acc = kIrisAccent;
    final t = v * 6.2; // ثواني
    // ١) نقطة ثم خط نور بيتمد
    final dot = seg(v, 0.0, 0.05);
    final line = seg(v, 0.05, 0.20, Curves.easeOutCubic);
    final lensA = 1 - seg(v, 0.60, 0.72);
    if (dot > 0 && v < 0.22) {
      canvas.drawCircle(c, 2.5 + 1.5 * math.sin(t * 9), Paint()..color = Colors.white.withOpacity(dot));
    }
    final L = s.width * 0.46;
    if (line > 0 && lensA > 0) {
      final r = Rect.fromLTRB(c.dx - L * line, c.dy - 1, c.dx + L * line, c.dy + 1);
      final sh = LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(.95), Colors.transparent]).createShader(r);
      canvas.drawRect(r.inflate(5).intersect(Rect.fromLTRB(r.left, c.dy - 4, r.right, c.dy + 4)), Paint()..shader = LinearGradient(colors: [Colors.transparent, acc.withOpacity(.25), Colors.transparent]).createShader(r));
      canvas.drawLine(Offset(r.left, c.dy), Offset(r.right, c.dy), Paint()..strokeWidth = 1.8..shader = sh);
    }
    // ٢) العدسة (شكل عين) بتتفتح
    final open = seg(v, 0.17, 0.40, Curves.easeInOutCubic);
    if (open > 0 && lensA > 0) {
      final half = s.width * 0.46;
      final ht = R * 1.15 * open;
      final lens = Path()
        ..moveTo(c.dx - half, c.dy)
        ..quadraticBezierTo(c.dx, c.dy - ht * 2, c.dx + half, c.dy)
        ..quadraticBezierTo(c.dx, c.dy + ht * 2, c.dx - half, c.dy)
        ..close();
      canvas.save();
      canvas.clipPath(lens);
      canvas.drawRect(Offset.zero & s, Paint()..shader = RadialGradient(colors: [const Color(0xFF16222E).withOpacity(lensA), const Color(0xFF05080C).withOpacity(lensA)]).createShader(Rect.fromCircle(center: c, radius: R * 1.6)));
      _inside(canvas, s, t, lensA);
      canvas.restore();
      canvas.drawPath(lens, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = acc.withOpacity(.12 * lensA));
      canvas.drawPath(lens, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = acc.withOpacity(.85 * lensA));
    }
    // حافة الرسم: خط نور بيلف مع ظهور اللوجو
    if (draw > 0 && draw < 1) {
      final ang = -math.pi / 2 + 2 * math.pi * draw;
      final rr = R * 0.5 * logoScale * 1.02;
      final e = c + Offset(math.cos(ang), math.sin(ang)) * rr;
      canvas.drawLine(c, e, Paint()..strokeWidth = 2..color = Colors.white.withOpacity(.9));
      canvas.drawLine(c, e, Paint()..strokeWidth = 7..color = kIrisAccent.withOpacity(.25));
      canvas.drawCircle(e, 4, Paint()..color = Colors.white);
    }
    // ٣) موجة الضوء لما النواة تولع
    final wave = seg(v, 0.60, 0.88, Curves.easeOutCubic);
    if (wave > 0 && wave < 1) {
      canvas.drawCircle(c, R * (0.4 + 2.6 * wave), Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4 * (1 - wave) + .4..color = Colors.white.withOpacity(.7 * (1 - wave)));
      canvas.drawCircle(c, R * (0.3 + 2.0 * wave), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = acc.withOpacity(.5 * (1 - wave)));
    }
    // ٤) توهج خفيف تحت اللوجو
    final glow = seg(v, 0.62, 0.8) * (1 - seg(v, 0.97, 1.0));
    if (glow > 0) {
      canvas.drawCircle(c, R * 1.2, Paint()..shader = RadialGradient(colors: [acc.withOpacity(.26 * glow), Colors.transparent]).createShader(Rect.fromCircle(center: c, radius: R * 1.2)));
    }
  }

  void _inside(Canvas canvas, Size s, double t, double a) {
    final acc = kIrisAccent;
    // جزيئات بتتجمع ناحية النواة
    final conv = seg(v, 0.36, 0.62, Curves.easeInCubic);
    final rnd = math.Random(5);
    for (var i = 0; i < 40; i++) {
      final ang = rnd.nextDouble() * 2 * math.pi;
      final r0 = R * (0.9 + rnd.nextDouble() * 2.2);
      final r = r0 * (1 - conv) + 6;
      final p = c + Offset(math.cos(ang + t * .15) * r, math.sin(ang + t * .15) * r * .7);
      canvas.drawCircle(p, 1.2 + rnd.nextDouble(), Paint()..color = Colors.white.withOpacity((.25 + .5 * rnd.nextDouble()) * a * (1 - seg(v, 0.58, 0.64))));
    }
    // حلقات HUD بتترسم وبتلف
    final radii = [0.52, 0.74, 0.98, 1.22];
    for (var i = 0; i < radii.length; i++) {
      final p = seg(v, 0.22 + 0.04 * i, 0.46 + 0.04 * i, Curves.easeOutCubic);
      if (p <= 0) continue;
      final rot = t * (i.isEven ? 0.9 : -0.7) + i;
      final r = R * radii[i];
      final paint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = i == 1 ? 3 : 1.5..color = acc.withOpacity((.35 + .5 * (i == 1 ? 1 : 0)) * a);
      final seg1 = i == 1 ? math.pi * 1.5 : math.pi * 0.9;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), rot, seg1 * p, false, paint);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), rot + math.pi, seg1 * p, false, paint);
      // علامات صغيرة
      if (i == 2) {
        for (var k = 0; k < 24; k++) {
          final ang = rot * .5 + k * 2 * math.pi / 24;
          canvas.drawLine(c + Offset(math.cos(ang), math.sin(ang)) * (r - 5), c + Offset(math.cos(ang), math.sin(ang)) * (r + (k % 3 == 0 ? 6 : 2)), Paint()..strokeWidth = 1..color = acc.withOpacity(.5 * p * a));
        }
      }
    }
    // شفرات فتحة العدسة
    final bl = seg(v, 0.30, 0.50, Curves.easeOutCubic);
    final close = seg(v, 0.56, 0.68, Curves.easeInCubic);
    if (bl > 0) {
      final n = 8;
      final rot = t * 0.55;
      final inner = R * (0.36 + .02 * (1 - close));
      final outer = R * (0.62 * bl) * (1 - .25 * close);
      for (var k = 0; k < n; k++) {
        final ang = rot + k * 2 * math.pi / n;
        final dir = Offset(math.cos(ang), math.sin(ang));
        final nor = Offset(-dir.dy, dir.dx);
        final path = Path()
          ..moveTo(c.dx + dir.dx * inner + nor.dx * 3, c.dy + dir.dy * inner + nor.dy * 3)
          ..lineTo(c.dx + dir.dx * outer + nor.dx * 20, c.dy + dir.dy * outer + nor.dy * 20)
          ..lineTo(c.dx + dir.dx * outer - nor.dx * 4, c.dy + dir.dy * outer - nor.dy * 4)
          ..close();
        canvas.drawPath(path, Paint()..color = acc.withOpacity(.10 * a * (1 - close)));
        canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = acc.withOpacity(.7 * a * (1 - close)));
      }
    }
    // النواة بتولع (ورا اللوجو)
    final core = seg(v, 0.40, 0.62, Curves.easeIn);
    if (false) canvas.drawCircle(c, R * (0.06 + 0.22 * core), Paint()..shader = RadialGradient(colors: [Colors.white.withOpacity(.95 * a), acc.withOpacity(.6 * a * core), Colors.transparent]).createShader(Rect.fromCircle(center: c, radius: R * (0.06 + 0.22 * core) * 2.2)));
  }

  @override
  bool shouldRepaint(_LensPainter o) => o.v != v;
}


// قص على شكل قطاع دايري: بيكبر من فوق مع عقارب الساعة (اللوجو بيترسم)
class _SweepClipper extends CustomClipper<Path> {
  final double p;
  _SweepClipper(this.p);
  @override
  Path getClip(Size s) {
    if (p >= 1) return Path()..addRect(Offset.zero & s);
    final c = s.center(Offset.zero);
    return Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: s.width), -math.pi / 2, 2 * math.pi * p, false)
      ..close();
  }

  @override
  bool shouldReclip(_SweepClipper o) => o.p != p;
}
