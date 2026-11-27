import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'login_page.dart' show kIrisAccent, IrisLogo;
import 'menu_preview.dart' show MenuList;

const Color _bg = Color(0xFF05080C);
const Color _panel = Color(0xFF0B1118);
const Color _card = Color(0xFF111A24);
const Color _ok = Color(0xFF2EE66B);
const Color _warn = Color(0xFFFFC857);

Widget badge(String t) => Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: _warn.withOpacity(.15), border: Border.all(color: _warn), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: const TextStyle(color: _warn, fontWeight: FontWeight.w700, fontSize: 11)),
      ),
    );

// ===== أيقونات ريلز ملوّنة ومتحركة (t = ٠..١ دورة كاملة) =====
class LivelyIconPainter extends CustomPainter {
  final int kind;
  final double t;
  LivelyIconPainter(this.kind, this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final f = Paint()..style = PaintingStyle.fill;
    final st = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final a = 2 * pi * t;
    if (kind == 0) {
      // شمس بتلف
      final sun = Offset(w * .83, w * .17);
      for (var i = 0; i < 8; i++) {
        final ang = a / 2 + i * pi / 4;
        canvas.drawLine(sun + Offset(cos(ang), sin(ang)) * w * .075, sun + Offset(cos(ang), sin(ang)) * w * .12, st..color = const Color(0xFFFFD54F)..strokeWidth = w * .022);
      }
      canvas.drawCircle(sun, w * .06, f..color = const Color(0xFFFFD54F));
      // ورقة رسم
      final paper = RRect.fromRectAndRadius(Rect.fromLTWH(w * .46, w * .30, w * .46, w * .52), Radius.circular(w * .05));
      canvas.drawRRect(paper, f..color = const Color(0xFFFFF3D6));
      // البيت بيترسم تدريجي
      final p = (t * 1.25).clamp(0.0, 1.0);
      final house = Path()..moveTo(w * .55, w * .70)..lineTo(w * .55, w * .54)..lineTo(w * .69, w * .42)..lineTo(w * .83, w * .54)..lineTo(w * .83, w * .70)..close();
      for (final mtr in house.computeMetrics()) {
        canvas.drawPath(mtr.extractPath(0, mtr.length * p), st..color = const Color(0xFFE5484D)..strokeWidth = w * .03);
      }
      if (p > .9) canvas.drawRect(Rect.fromLTWH(w * .65, w * .58, w * .08, w * .12), f..color = const Color(0xFF4FC3F7));
      // طفل من غير وش
      final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * .13, w * .44, w * .20, w * .26), Radius.circular(w * .07));
      canvas.drawRRect(body, f..color = const Color(0xFF29B6F6));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .14, w * .68, w * .07, w * .16), Radius.circular(w * .03)), f..color = const Color(0xFF7E57C2));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .25, w * .68, w * .07, w * .16), Radius.circular(w * .03)), f..color = const Color(0xFF7E57C2));
      canvas.drawCircle(Offset(w * .23, w * .34), w * .10, f..color = const Color(0xFFFFB74D));
      canvas.drawArc(Rect.fromCenter(center: Offset(w * .23, w * .31), width: w * .22, height: w * .2), pi, pi, true, f..color = const Color(0xFF6D4C41));
      // دراع بيرسم (بيتحرك)
      final hand = Offset(w * .53 + sin(a) * w * .03, w * .56 + cos(a * 2) * w * .02);
      canvas.drawLine(Offset(w * .31, w * .50), hand, st..color = const Color(0xFFFFB74D)..strokeWidth = w * .045);
      canvas.drawLine(hand, hand + Offset(w * .05, -w * .04), st..color = const Color(0xFFE5484D)..strokeWidth = w * .035);
    } else if (kind == 1) {
      // ترس برتقالي بيلف
      final gc = Offset(w * .72, w * .42);
      final g = Path();
      const teeth = 8;
      for (var i = 0; i < teeth * 2; i++) {
        final a0 = a / teeth * 1.0 + (i / (teeth * 2)) * 2 * pi;
        final a1 = a / teeth * 1.0 + ((i + 1) / (teeth * 2)) * 2 * pi;
        final rr = i.isEven ? w * .19 : w * .145;
        g.lineTo(gc.dx + cos(a0) * rr, gc.dy + sin(a0) * rr);
        g.lineTo(gc.dx + cos(a1) * rr, gc.dy + sin(a1) * rr);
      }
      g.close();
      canvas.drawPath(g, f..color = const Color(0xFFFF9F43));
      canvas.drawCircle(gc, w * .06, f..color = const Color(0xFF0B1118));
      // أنبوب
      canvas.save();
      canvas.translate(w * .34, w * .52);
      canvas.rotate(-0.3);
      final tube = Path()..moveTo(-w * .10, -w * .34)..lineTo(-w * .10, w * .18)..arcToPoint(Offset(w * .10, w * .18), radius: Radius.circular(w * .10), clockwise: false)..lineTo(w * .10, -w * .34);
      final liq = Path()..moveTo(-w * .10, -w * .04)..lineTo(w * .10, -w * .04)..lineTo(w * .10, w * .18)..arcToPoint(Offset(-w * .10, w * .18), radius: Radius.circular(w * .10), clockwise: true)..close();
      canvas.drawPath(liq, f..shader = ui.Gradient.linear(Offset(0, -w * .04), Offset(0, w * .28), [const Color(0xFF3DDC97), const Color(0xFF7C4DFF)]));
      f.shader = null;
      canvas.drawPath(tube, st..color = const Color(0xFFE0F2FF)..strokeWidth = w * .032);
      canvas.drawLine(Offset(-w * .14, -w * .34), Offset(w * .14, -w * .34), st);
      for (var i = 0; i < 3; i++) {
        final ph = (t + i / 3) % 1.0;
        canvas.drawCircle(Offset(sin(ph * 6 + i) * w * .04, w * .16 - ph * w * .30), w * (.018 + .012 * (1 - ph)), f..color = Colors.white.withOpacity(.85 * (1 - ph * .6)));
      }
      canvas.restore();
      // نجمة صغيرة بتلمع
      final sp = (.5 + .5 * sin(a));
      final sc = Offset(w * .20, w * .16);
      canvas.drawLine(sc - Offset(0, w * .05 * sp), sc + Offset(0, w * .05 * sp), st..color = const Color(0xFFFFD54F)..strokeWidth = w * .02);
      canvas.drawLine(sc - Offset(w * .05 * sp, 0), sc + Offset(w * .05 * sp, 0), st);
    } else {
      // قطة ملوّنة
      canvas.save();
      canvas.translate(w / 2, w * .55);
      canvas.rotate(sin(a) * .06);
      canvas.translate(-w / 2, -w * .55);
      final orange = const Color(0xFFFFA45B);
      final ear = Path()..moveTo(w * .18, w * .46)..lineTo(w * .20, w * .14)..lineTo(w * .40, w * .30)..close();
      final ear2 = Path()..moveTo(w * .82, w * .46)..lineTo(w * .80, w * .14)..lineTo(w * .60, w * .30)..close();
      final tw = sin(a * 2) * w * .012;
      canvas.save();
      canvas.translate(0, tw);
      canvas.drawPath(ear, f..color = orange);
      canvas.drawPath(ear2, f..color = orange);
      canvas.restore();
      canvas.drawPath(Path()..moveTo(w * .23, w * .38)..lineTo(w * .24, w * .22)..lineTo(w * .35, w * .31)..close(), f..color = const Color(0xFFFF8FB1));
      canvas.drawPath(Path()..moveTo(w * .77, w * .38)..lineTo(w * .76, w * .22)..lineTo(w * .65, w * .31)..close(), f..color = const Color(0xFFFF8FB1));
      canvas.drawOval(Rect.fromLTWH(w * .14, w * .26, w * .72, w * .58), f..color = orange);
      // خطوط القطة
      for (final dx in [-.06, 0.0, .06]) {
        canvas.drawLine(Offset(w * (.5 + dx), w * .27), Offset(w * (.5 + dx), w * .35), st..color = const Color(0xFFE5733A)..strokeWidth = w * .022);
      }
      final blink = (t > .46 && t < .54);
      for (final cx in [.36, .64]) {
        if (blink) {
          canvas.drawLine(Offset(w * (cx - .05), w * .52), Offset(w * (cx + .05), w * .52), st..color = const Color(0xFF3E2723)..strokeWidth = w * .025);
        } else {
          canvas.drawOval(Rect.fromCenter(center: Offset(w * cx, w * .52), width: w * .12, height: w * .14), f..color = const Color(0xFFFFFFFF));
          canvas.drawCircle(Offset(w * cx + sin(a) * w * .012, w * .52), w * .035, f..color = const Color(0xFF00C853));
        }
      }
      canvas.drawPath(Path()..moveTo(w * .45, w * .62)..lineTo(w * .55, w * .62)..lineTo(w * .5, w * .67)..close(), f..color = const Color(0xFFFF6B9A));
      canvas.drawPath(Path()..moveTo(w * .5, w * .67)..quadraticBezierTo(w * .45, w * .75, w * .40, w * .70), st..color = const Color(0xFF3E2723)..strokeWidth = w * .02);
      canvas.drawPath(Path()..moveTo(w * .5, w * .67)..quadraticBezierTo(w * .55, w * .75, w * .60, w * .70), st);
      for (final dy in [-.02, .04]) {
        canvas.drawLine(Offset(w * .30, w * (.66 + dy)), Offset(w * (.08 - sin(a) * .01), w * (.62 + dy * 2)), st..color = Colors.white70..strokeWidth = w * .015);
        canvas.drawLine(Offset(w * .70, w * (.66 + dy)), Offset(w * (.92 + sin(a) * .01), w * (.62 + dy * 2)), st);
      }
      canvas.restore();
      // ببيونة بنفسجية
      canvas.drawPath(Path()..moveTo(w * .5, w * .86)..lineTo(w * .38, w * .80)..lineTo(w * .38, w * .92)..close(), f..color = const Color(0xFF7C4DFF));
      canvas.drawPath(Path()..moveTo(w * .5, w * .86)..lineTo(w * .62, w * .80)..lineTo(w * .62, w * .92)..close(), f);
      canvas.drawCircle(Offset(w * .5, w * .86), w * .03, f..color = const Color(0xFFFFD54F));
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

const _rc = [Color(0xFF29B6F6), Color(0xFF3DDC97), Color(0xFFFF8FB1)];
const _rt = [
  ['اصنع فيديو تعليمي للأطفال', 'رسوم ملوّنة وقصص ممتعة'],
  ['اصنع فيديو علمي تعليمي', 'شرح مبسّط بتجارب ورسوم'],
  ['اصنع فيديو سوشيال', 'ريلز قصير جاهز للنشر'],
];

// كروت الريلز مع دخول متدرّج: p = تقدّم الدخول ٠..١، t = حركة الأيقونة
Widget reelCard(int k, double p, double t, {bool col = false}) {
  final stag = ((p * 1.6) - k * .3).clamp(0.0, 1.0);
  final e = Curves.easeOutCubic.transform(stag);
  final c = _rc[k];
  final sz = col ? 56.0 : 46.0;
  return Opacity(
    opacity: e,
    child: Transform.translate(
      offset: Offset((1 - e) * 40, 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: col ? 12 : 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withOpacity(.65), width: 1.2),
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [c.withOpacity(.22), _card]),
        ),
        child: Row(children: [
          SizedBox(width: sz, height: sz, child: CustomPaint(painter: LivelyIconPainter(k, t))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_rt[k][0], style: TextStyle(color: Colors.white, fontSize: col ? 18 : 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(_rt[k][1], style: TextStyle(color: Colors.white60, fontSize: col ? 13.5 : 12)),
          ])),
          const Icon(Icons.chevron_left, color: Colors.white38),
        ]),
      ),
    ),
  );
}

class ReelsFrame extends StatelessWidget {
  final String device; // phone | laptop | tv
  final double p, t;
  const ReelsFrame(this.device, {super.key, required this.p, required this.t});
  @override
  Widget build(BuildContext context) {
    final row = device != 'phone';
    final body = Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: row ? 640 : 400), child: Column(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < 3; i++) reelCard(i, p, t, col: row)])));
    final content = Padding(padding: EdgeInsets.fromLTRB(device == 'tv' ? 60 : 20, device == 'tv' ? 20 : 8, device == 'tv' ? 60 : 20, 20), child: body);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          device == 'laptop'
              ? Row(children: [
                  Container(width: 300, decoration: BoxDecoration(color: _panel, border: Border(left: BorderSide(color: kIrisAccent.withOpacity(.25)))), child: SingleChildScrollView(child: const MenuList(compact: true, selected: 'ريلز فيديو'))),
                  Expanded(child: Column(children: [const SizedBox(height: 22), Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: const [Expanded(child: Text('ريلز فيديو', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))), IrisLogo(size: 34)])), Expanded(child: content)])),
                ])
              : SafeArea(child: Column(children: [
                  const SizedBox(height: 26),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: const [Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20), SizedBox(width: 10), Expanded(child: Text('ريلز فيديو', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))), IrisLogo(size: 32)])),
                  Expanded(child: content),
                ])),
          badge('${device == 'phone' ? 'موبايل' : (device == 'laptop' ? 'لابتوب' : 'تلفزيون')} · دخول ${(p * 100).round()}%'),
        ]),
      ),
    );
  }
}

// ===== شاشة الشات التجريبية =====
class ChatTestFrame extends StatelessWidget {
  final int step; // 0 فاضي، 1 كتب، 2 آيرس كتب الرد
  const ChatTestFrame({super.key, required this.step});
  @override
  Widget build(BuildContext context) {
    Widget bub(String t, {bool me = false, String? who}) => Align(
          alignment: me ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(color: me ? kIrisAccent.withOpacity(.22) : _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: me ? kIrisAccent.withOpacity(.5) : Colors.white12)),
            child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
          ),
        );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          SafeArea(
            child: Column(children: [
              const SizedBox(height: 26),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: const [Icon(Icons.menu, color: Colors.white70), SizedBox(width: 12), IrisLogo(size: 34), SizedBox(width: 8), Text('IRIS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3))])),
              const Divider(color: Colors.white12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: step == 0
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [IrisLogo(size: 90), SizedBox(height: 14), Text('أهلاً يا محمود', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)), Text('اكتب أي حاجة', style: TextStyle(color: Colors.white54))])
                      : Column(children: [
                          const SizedBox(height: 10),
                          bub('تست', me: true),
                          if (step == 2)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                bub('ايوه كده يا محمود، التيست اشتغل. جاهزين نربط السيرفرات عشان نولّد الكلام والصور والفيديوهات ونذاكر ونراجع مشاريعك.'),
                              ]),
                            )
                          else
                            Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < 3; i++) Container(width: 7, height: 7, margin: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, color: kIrisAccent.withOpacity(.4 + i * .25)))]))),
                        ]),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(25), border: Border.all(color: kIrisAccent.withOpacity(.4))),
                child: Row(children: [
                  Icon(step == 0 ? Icons.mic : Icons.arrow_upward, color: kIrisAccent),
                  const SizedBox(width: 10),
                  Text(step == 0 ? 'اكتب هنا...' : '', style: const TextStyle(color: Colors.white38)),
                  const Spacer(),
                  const Icon(Icons.add_circle_outline, color: Colors.white54),
                ]),
              ),
            ]),
          ),
          badge('الشات · تجربة ${step + 1}'),
        ]),
      ),
    );
  }
}
