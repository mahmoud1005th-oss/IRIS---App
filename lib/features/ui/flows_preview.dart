import 'dart:math';
import 'package:flutter/material.dart';
import 'login_page.dart' show kIrisAccent, IrisLogo;
import 'menu_preview.dart' show MenuList;

// معاينة تصميم فقط (V3.5): شاشة الريلز، ربط التلفزيون، ربط الساعة.
const Color _bg = Color(0xFF05080C);
const Color _panel = Color(0xFF0B1118);
const Color _card = Color(0xFF111A24);
const Color _ok = Color(0xFF2EE66B);
const Color _warn = Color(0xFFFFC857);

Widget _badge(String t) => Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: _warn.withOpacity(.15), border: Border.all(color: _warn), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: const TextStyle(color: _warn, fontWeight: FontWeight.w700, fontSize: 11)),
      ),
    );

Widget _screen(Widget child, String badge, {bool back = true, String? title, Widget? footer}) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 22),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(children: [
                    if (back) const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
                    if (back) const SizedBox(width: 10),
                    Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                    const IrisLogo(size: 32),
                  ]),
                ),
              Expanded(child: child),
              if (footer != null) footer,
            ]),
          ),
          _badge(badge),
        ]),
      ),
    );

Widget _btn(String t, {bool on = true, Color? c}) => Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: on ? (c ?? kIrisAccent) : Colors.white10, borderRadius: BorderRadius.circular(24)),
      child: Text(t, style: TextStyle(color: on ? Colors.black : Colors.white38, fontWeight: FontWeight.w800, fontSize: 16)),
    );

Widget _mem() => Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: kIrisAccent.withOpacity(.10), border: Border.all(color: kIrisAccent.withOpacity(.3))),
      child: Row(children: const [
        Icon(Icons.memory, color: kIrisAccent, size: 16),
        SizedBox(width: 8),
        Expanded(child: Text('ذاكرة آيرس واحدة على كل الأجهزة، من غير محادثة جديدة', style: TextStyle(color: Colors.white70, fontSize: 11.5))),
      ]),
    );

// ===== أيقونات مرسومة بسيطة (خطوط بلون الأكسنت) =====
class ReelIconPainter extends CustomPainter {
  final int kind; // 0 طفل بيرسم، 1 أنبوب اختبار + ترس، 2 قطة
  final Color c;
  ReelIconPainter(this.kind, this.c);

  Path _gear(Offset ctr, double r, int teeth) {
    final p = Path();
    for (var i = 0; i < teeth * 2; i++) {
      final a0 = (i / (teeth * 2)) * 2 * pi;
      final a1 = ((i + 1) / (teeth * 2)) * 2 * pi;
      final rr = i.isEven ? r : r * .76;
      p.lineTo(ctr.dx + cos(a0) * rr, ctr.dy + sin(a0) * rr);
      p.lineTo(ctr.dx + cos(a1) * rr, ctr.dy + sin(a1) * rr);
    }
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final st = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = c.withOpacity(.18);
    if (kind == 0) {
      // ورقة رسم
      final paper = RRect.fromRectAndRadius(Rect.fromLTWH(w * .50, w * .30, w * .42, w * .5), Radius.circular(w * .04));
      canvas.drawRRect(paper, fill);
      canvas.drawRRect(paper, st);
      // رسمة بسيطة على الورقة: بيت وشمس
      canvas.drawRect(Rect.fromLTWH(w * .58, w * .56, w * .16, w * .12), st);
      canvas.drawPath(Path()..moveTo(w * .56, w * .56)..lineTo(w * .66, w * .46)..lineTo(w * .76, w * .56), st);
      canvas.drawCircle(Offset(w * .82, w * .40), w * .035, st);
      // طفل بدون وش: راس دايرة فاضية، جسم، دراع ماسك قلم
      canvas.drawCircle(Offset(w * .26, w * .30), w * .10, st);
      canvas.drawLine(Offset(w * .26, w * .40), Offset(w * .26, w * .64), st);
      canvas.drawLine(Offset(w * .26, w * .64), Offset(w * .16, w * .84), st);
      canvas.drawLine(Offset(w * .26, w * .64), Offset(w * .36, w * .84), st);
      canvas.drawLine(Offset(w * .26, w * .48), Offset(w * .50, w * .52), st);
      canvas.drawLine(Offset(w * .26, w * .48), Offset(w * .15, w * .58), st);
      // القلم
      canvas.drawLine(Offset(w * .50, w * .52), Offset(w * .56, w * .50), st..strokeWidth = w * .06);
    } else if (kind == 1) {
      // أنبوب اختبار مائل
      canvas.save();
      canvas.translate(w * .40, w * .50);
      canvas.rotate(-0.35);
      final tube = Path()
        ..moveTo(-w * .09, -w * .36)
        ..lineTo(-w * .09, w * .20)
        ..arcToPoint(Offset(w * .09, w * .20), radius: Radius.circular(w * .09), clockwise: false)
        ..lineTo(w * .09, -w * .36);
      canvas.drawPath(tube, st);
      canvas.drawLine(Offset(-w * .13, -w * .36), Offset(w * .13, -w * .36), st);
      final liquid = Path()
        ..moveTo(-w * .09, w * .0)
        ..lineTo(w * .09, w * .0)
        ..lineTo(w * .09, w * .20)
        ..arcToPoint(Offset(-w * .09, w * .20), radius: Radius.circular(w * .09), clockwise: true)
        ..close();
      canvas.drawPath(liquid, fill..color = c.withOpacity(.4));
      canvas.drawCircle(Offset(-w * .02, w * .08), w * .015, Paint()..color = c);
      canvas.drawCircle(Offset(w * .03, w * .13), w * .02, Paint()..color = c);
      canvas.restore();
      // ترس بجنبه
      final g = _gear(Offset(w * .72, w * .44), w * .17, 8);
      canvas.drawPath(g, fill..color = c.withOpacity(.18));
      canvas.drawPath(g, st..strokeWidth = w * .04);
      canvas.drawCircle(Offset(w * .72, w * .44), w * .06, st);
    } else {
      // قطة: راس بودن وودان مدببة وشنب
      final head = Path()
        ..moveTo(w * .20, w * .78)
        ..quadraticBezierTo(w * .12, w * .55, w * .17, w * .20)
        ..lineTo(w * .36, w * .38)
        ..quadraticBezierTo(w * .50, w * .33, w * .64, w * .38)
        ..lineTo(w * .83, w * .20)
        ..quadraticBezierTo(w * .88, w * .55, w * .80, w * .78)
        ..quadraticBezierTo(w * .50, w * .96, w * .20, w * .78);
      canvas.drawPath(head, fill..color = c.withOpacity(.18));
      canvas.drawPath(head, st..strokeWidth = w * .045);
      final dot = Paint()..color = c;
      canvas.drawOval(Rect.fromCenter(center: Offset(w * .36, w * .56), width: w * .07, height: w * .10), dot);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * .64, w * .56), width: w * .07, height: w * .10), dot);
      canvas.drawPath(Path()..moveTo(w * .46, w * .66)..lineTo(w * .54, w * .66)..lineTo(w * .50, w * .70)..close(), dot);
      canvas.drawPath(Path()..moveTo(w * .50, w * .70)..quadraticBezierTo(w * .46, w * .77, w * .41, w * .73), st..strokeWidth = w * .03);
      canvas.drawPath(Path()..moveTo(w * .50, w * .70)..quadraticBezierTo(w * .54, w * .77, w * .59, w * .73), st);
      for (final dy in [-.02, .04]) {
        canvas.drawLine(Offset(w * .30, w * (.68 + dy)), Offset(w * .08, w * (.64 + dy * 2)), st);
        canvas.drawLine(Offset(w * .70, w * (.68 + dy)), Offset(w * .92, w * (.64 + dy * 2)), st);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

Widget _reelCard(int k, String t, String sub, {bool row = true}) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kIrisAccent.withOpacity(.4)),
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [kIrisAccent.withOpacity(.14), _card]),
      ),
      child: row
          ? Row(children: [
              SizedBox(width: 84, height: 84, child: CustomPaint(painter: ReelIconPainter(k, kIrisAccent))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(t, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
              ])),
              const Icon(Icons.chevron_left, color: Colors.white38),
            ])
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 120, height: 120, child: CustomPaint(painter: ReelIconPainter(k, kIrisAccent))),
              const SizedBox(height: 14),
              Text(t, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.3)),
              const SizedBox(height: 6),
              Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ]),
    );

const _reels = [
  ['اعمل فيديو تعليمي للأطفال', 'رسوم بسيطة وقصص ممتعة'],
  ['اعمل فيديو علمي تعليمي', 'شرح مبسّط بتجارب ورسوم'],
  ['اعمل فيديو سوشيال', 'ريلز قصير جاهز للنشر'],
];

class PhoneReelsPreview extends StatelessWidget {
  const PhoneReelsPreview({super.key});
  @override
  Widget build(BuildContext context) => _screen(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: [
            for (var i = 0; i < 3; i++) ...[Expanded(child: _reelCard(i, _reels[i][0], _reels[i][1])), const SizedBox(height: 12)],
          ]),
        ),
        'الموبايل: ريلز فيديو',
        title: 'ريلز فيديو',
      );
}

class LaptopReelsPreview extends StatelessWidget {
  const LaptopReelsPreview({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          body: Row(children: [
            Container(
              width: 300,
              decoration: BoxDecoration(color: _panel, border: Border(left: BorderSide(color: kIrisAccent.withOpacity(.25)))),
              child: SingleChildScrollView(child: const MenuList(compact: true, selected: 'ريلز فيديو')),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
                  child: Row(children: const [
                    Expanded(child: Text('ريلز فيديو', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
                    IrisLogo(size: 34),
                  ]),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                    child: Row(children: [
                      for (var i = 0; i < 3; i++) ...[Expanded(child: _reelCard(i, _reels[i][0], _reels[i][1], row: false)), if (i < 2) const SizedBox(width: 16)],
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );
}

// ===== ربط التلفزيون =====
Widget _bubble(String t, {bool me = false}) => Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 270),
        decoration: BoxDecoration(
            color: me ? kIrisAccent.withOpacity(.22) : _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: me ? kIrisAccent.withOpacity(.5) : Colors.white12)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.5)),
      ),
    );

Widget _field(String hint, {bool dots = false, IconData ic = Icons.mail_outline, Color? b}) => Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: b ?? Colors.white12)),
      child: Row(children: [
        Icon(ic, color: Colors.white38, size: 18),
        const SizedBox(width: 8),
        Text(dots ? '••••••••••' : hint, style: TextStyle(color: dots || hint.contains('@') ? Colors.white : Colors.white38, fontSize: dots ? 18 : 14)),
      ]),
    );

Widget _stepper(int n, int of) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(children: [
        for (var i = 0; i < of; i++)
          Expanded(child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: i < n ? kIrisAccent : Colors.white12, borderRadius: BorderRadius.circular(2)))),
      ]),
    );

Widget _bigIcon(IconData ic, {Color c = kIrisAccent, double size = 72}) => Container(
      width: size + 40,
      height: size + 40,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(.12), border: Border.all(color: c, width: 2.5), boxShadow: [BoxShadow(color: c.withOpacity(.3), blurRadius: 26)]),
      child: Icon(ic, color: c, size: size),
    );

class PhoneTvLinkPreview extends StatelessWidget {
  final int step; // 0 محادثة، 1 نزّل التطبيق، 2 افتح + كود، 3 الإيميل والباسورد، 4 متصل
  const PhoneTvLinkPreview({super.key, required this.step});
  @override
  Widget build(BuildContext context) {
    final names = ['١ · قول لآيرس', '٢ · نزّل التطبيق', '٣ · افتح التطبيق + الكود', '٤ · حسابك للتلفزيون', '٥ · تم الربط'];
    Widget body;
    switch (step) {
      case 0:
        body = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _bubble('عايز أوصل التلفزيون', me: true),
            _bubble('تمام يا محمود. هنربط تلفزيونك بآيرس خطوة خطوة.'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: kIrisAccent.withOpacity(.5))),
              child: Row(children: [
                const Icon(Icons.cast_connected, color: kIrisAccent, size: 30),
                const SizedBox(width: 12),
                const Expanded(child: Text('وضع الربط\nاربط التلفزيون بآيرس', style: TextStyle(color: Colors.white, fontSize: 14.5, height: 1.5))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: kIrisAccent, borderRadius: BorderRadius.circular(16)), child: const Text('افتح', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800))),
              ]),
            ),
            const Spacer(),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(24)),
              child: Row(children: const [Icon(Icons.mic, color: kIrisAccent), SizedBox(width: 10), Text('اتكلم مع آيرس...', style: TextStyle(color: Colors.white38))]),
            ),
          ]),
        );
        break;
      case 1:
        body = Column(children: [
          _stepper(1, 4),
          const Spacer(),
          _bigIcon(Icons.tv),
          const SizedBox(height: 20),
          const Text('نزّل تطبيق آيرس على التلفزيون الأول', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 30), child: Text('افتح متجر التطبيقات في التلفزيون وابحث عن «IRIS» ونزّله', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5))),
          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), child: _btn('نزّلت التطبيق')),
        ]);
        break;
      case 2:
        body = Column(children: [
          _stepper(2, 4),
          const SizedBox(height: 10),
          const Text('افتح التطبيق على التلفزيون', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('هيطلب منك كود، اكتب الكود ده فيه', style: TextStyle(color: Colors.white54, fontSize: 13.5)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: kIrisAccent)),
            child: const Text('483 921', style: TextStyle(color: kIrisAccent, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: 6)),
          ),
          const SizedBox(height: 8),
          const Text('الكود بيتغير كل دقيقتين', style: TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: _btn('فتحت التطبيق وكتبت الكود')),
          const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 20), child: Text('لسه ما نزّلتهوش؟ رجوع', textAlign: TextAlign.center, style: TextStyle(color: kIrisAccent, fontSize: 13))),
        ]);
        break;
      case 3:
        body = Column(children: [
          _stepper(3, 4),
          const SizedBox(height: 10),
          const Text('اكتب حسابك للتلفزيون', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text('بتكتب من الموبايل، والتلفزيون بيستلم بشكل مشفّر. مفيش كتابة بالريموت', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5))),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
            _field('mahmoud@gmail.com', b: kIrisAccent),
            _field('', dots: true, ic: Icons.lock_outline),
          ])),
          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), child: _btn('ابعت للتلفزيون')),
        ]);
        break;
      default:
        body = Column(children: [
          _stepper(4, 4),
          const Spacer(),
          _bigIcon(Icons.verified_user, c: _ok),
          const SizedBox(height: 20),
          const Text('تم الاتصال', style: TextStyle(color: _ok, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('تلفزيون الصالة مربوط بآيرس', style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('قول «TV IRIS» قدام التلفزيون وجرّب', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), child: _btn('تمام', c: _ok)),
        ]);
    }
    return _screen(body, 'موبايل ${names[step]}', title: step == 0 ? 'آيرس' : 'وضع الربط', footer: _mem());
  }
}

// شاشة التلفزيون (تطبيق آيرس على التلفزيون)
class TvLinkScreenPreview extends StatelessWidget {
  final int step; // 0 بيطلب كود، 1 بيستلم الحساب، 2 متصل
  const TvLinkScreenPreview({super.key, required this.step});
  @override
  Widget build(BuildContext context) {
    final ok = step == 2;
    final col = ok ? _ok : kIrisAccent;
    final titles = ['اكتب الكود اللي ظاهر في آيرس على موبايلك', 'بنستلم حسابك من الموبايل...', 'تم الاتصال'];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const IrisLogo(size: 90),
              const SizedBox(height: 24),
              Text(titles[step], style: TextStyle(color: ok ? _ok : Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 22),
              if (step == 0)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < 6; i++)
                    Container(
                      width: 62,
                      height: 78,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: i < 3 ? kIrisAccent : Colors.white24, width: i == 3 ? 2.5 : 1.2)),
                      child: Text(i < 3 ? '•' : '', style: const TextStyle(color: Colors.white, fontSize: 34)),
                    ),
                ])
              else
                Icon(ok ? Icons.verified_user : Icons.sync, color: col, size: 80),
              const SizedBox(height: 18),
              Text(step == 0 ? 'الكود موجود في آيرس على موبايلك' : (ok ? 'جاهز: قول «TV IRIS»' : 'الباسورد مش بيظهر على الشاشة'), style: const TextStyle(color: Colors.white54, fontSize: 18)),
            ]),
          ),
          _badge('تلفزيون ${['١', '٢', '٣'][step]}'),
        ]),
      ),
    );
  }
}

// ===== الساعة الذكية =====
class PhoneWatchPreview extends StatelessWidget {
  final int step; // 0 إضافة ساعة، 1 بلوتوث النظام، 2 تم الربط، 3 حالتي والنبض، 4 وضع رياضة
  const PhoneWatchPreview({super.key, required this.step});

  Widget _stat(IconData ic, String v, String l, {Color c = kIrisAccent}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
          child: Column(children: [
            Icon(ic, color: c, size: 22),
            const SizedBox(height: 6),
            Text(v, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(l, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final names = ['١ · إضافة ساعة', '٢ · بلوتوث الهاتف', '٣ · تم الربط', '٤ · حالتي', '٥ · وضع الرياضة'];
    Widget body;
    if (step == 0) {
      Widget opt(IconData ic, String t, String s, bool sel) => Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: sel ? kIrisAccent : Colors.white12, width: sel ? 2 : 1)),
            child: Row(children: [
              Icon(ic, color: sel ? kIrisAccent : Colors.white54, size: 30),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                Text(s, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ])),
              if (sel) const Icon(Icons.check_circle, color: kIrisAccent),
            ]),
          );
      body = Column(children: [
        const SizedBox(height: 14),
        _bigIcon(Icons.watch_outlined, size: 56),
        const SizedBox(height: 16),
        const Text('ضيف أي ساعة بلوتوث', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        opt(Icons.bluetooth, 'بلوتوث', 'أي ساعة بلوتوث تتقرن', true),
        opt(Icons.qr_code_2, 'مسح كود QR', 'لو الساعة بتعرضه', false),
        opt(Icons.apps, 'من تطبيق الساعة', 'Samsung Health / Wear OS', false),
        const Spacer(),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFFC857).withOpacity(.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFC857).withOpacity(.5))),
          child: const Row(children: [Icon(Icons.info_outline, color: Color(0xFFFFC857), size: 18), SizedBox(width: 8), Expanded(child: Text('الاقتران يشتغل مع أي ساعة. قراءة النبض والنوم بتعتمد على قناة الساعة نفسها، ولو مش متاحة آيرس هيقولك بصراحة', style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.5)))]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: _btn('كمّل بالبلوتوث')),
      ]);
    } else if (step == 1) {
      Widget dev(IconData ic, String n, {bool sel = false, String? st}) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: sel ? kIrisAccent.withOpacity(.14) : _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? kIrisAccent : Colors.white12)),
            child: Row(children: [
              Icon(ic, color: sel ? kIrisAccent : Colors.white54),
              const SizedBox(width: 12),
              Expanded(child: Text(n, style: const TextStyle(color: Colors.white, fontSize: 15))),
              if (st != null) Text(st, style: const TextStyle(color: kIrisAccent, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ]),
          );
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
          child: Row(children: const [Icon(Icons.settings, color: Colors.white54, size: 18), SizedBox(width: 8), Text('إعدادات البلوتوث (شاشة نظام الهاتف)', style: TextStyle(color: Colors.white54, fontSize: 12.5))]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 6), child: Row(children: const [Expanded(child: Text('Bluetooth', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700))), Icon(Icons.toggle_on, color: kIrisAccent, size: 40)])),
        const Padding(padding: EdgeInsets.fromLTRB(18, 8, 18, 6), child: Text('الأجهزة المتاحة', style: TextStyle(color: Colors.white38, fontSize: 12))),
        dev(Icons.watch_outlined, "Mahmoud's Watch", sel: true, st: 'جاري الاقتران...'),
        dev(Icons.watch_outlined, 'Galaxy Fit / Mi Band / Amazfit'),
        dev(Icons.headphones, 'سماعة'),
        dev(Icons.speaker, 'سبيكر'),
        const Spacer(),
        const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 14), child: Text('آيرس بيفتح الإعداد ده، وبعد الاقتران بيرجّعك للتطبيق لوحده', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12))),
      ]);
    } else if (step == 2) {
      body = Column(children: [
        const Spacer(),
        _bigIcon(Icons.watch, c: _ok, size: 64),
        const SizedBox(height: 20),
        const Text('تم ربط الساعة', style: TextStyle(color: _ok, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text("Mahmoud's Watch · البطارية 82%", style: TextStyle(color: Colors.white70, fontSize: 14)),
        const Spacer(),
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: _btn('شوف حالتي', c: _ok)),
      ]);
    } else if (step == 3) {
      body = ListView(padding: const EdgeInsets.fromLTRB(12, 6, 12, 8), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.favorite, color: Color(0xFFFF6B7A), size: 28),
              const SizedBox(width: 8),
              const Text('78', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
              const Text(' نبضة/د', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _ok.withOpacity(.15), borderRadius: BorderRadius.circular(12)), child: const Text('هادئ', style: TextStyle(color: _ok, fontSize: 12.5, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 8),
            SizedBox(height: 56, width: double.infinity, child: CustomPaint(painter: _EcgPainter(kIrisAccent))),
          ]),
        ),
        const SizedBox(height: 8),
        Row(children: [_stat(Icons.directions_walk, '6,420', 'خطوة'), _stat(Icons.local_fire_department_outlined, '312', 'سعرة'), _stat(Icons.bedtime_outlined, '7س 10د', 'نوم')]),
        const SizedBox(height: 10),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('أوضاع الرياضة في ساعتك', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final x in [['جري', Icons.directions_run], ['مشي', Icons.directions_walk], ['سباحة', Icons.pool], ['دراجة', Icons.pedal_bike], ['يوجا', Icons.self_improvement], ['كمال أجسام', Icons.fitness_center], ['+90', Icons.more_horiz]])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: kIrisAccent.withOpacity(.4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(x[1] as IconData, color: kIrisAccent, size: 18), const SizedBox(width: 6), Text(x[0] as String, style: const TextStyle(color: Colors.white, fontSize: 13))]),
            ),
        ]),
      ]);
    } else {
      body = Column(children: [
        const SizedBox(height: 6),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(22), border: Border.all(color: _ok.withOpacity(.6)), gradient: LinearGradient(colors: [_ok.withOpacity(.14), _card], begin: Alignment.topRight, end: Alignment.bottomLeft)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.directions_run, color: _ok, size: 26),
              const SizedBox(width: 8),
              const Text('وضع الجري', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _ok.withOpacity(.2), borderRadius: BorderRadius.circular(12)), child: const Text('● شغّال', style: TextStyle(color: _ok, fontSize: 12, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 10),
            const Text('00:18:42', style: TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: 2)),
            const SizedBox(height: 10),
            Row(children: [_stat(Icons.favorite, '142', 'نبض', c: const Color(0xFFFF6B7A)), _stat(Icons.straighten, '3.1', 'كم'), _stat(Icons.speed, '6:02', 'د/كم')]),
          ]),
        ),
        const SizedBox(height: 12),
        // آيرس معاك
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kIrisAccent.withOpacity(.10), borderRadius: BorderRadius.circular(18), border: Border.all(color: kIrisAccent.withOpacity(.45))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const IrisLogo(size: 40),
            const SizedBox(width: 12),
            const Expanded(child: Text('كمّل يا محمود، نبضك ممتاز. فاضل ٢ كم على هدفك. خد نفس عميق وثبّت سرعتك.', style: TextStyle(color: Colors.white, fontSize: 14.5, height: 1.55))),
          ]),
        ),
        const Spacer(),
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Row(children: [
          Expanded(child: Container(height: 48, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: kIrisAccent)), child: const Text('إيقاف مؤقت', style: TextStyle(color: kIrisAccent, fontWeight: FontWeight.w800)))),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 48, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.redAccent), child: const Text('إنهاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
        ])),
      ]);
    }
    return _screen(body, 'ساعة ${names[step]}', title: ['الساعة الذكية', 'الساعة الذكية', 'الساعة الذكية', 'حالتي', 'الرياضة'][step], footer: _mem());
  }
}

class _EcgPainter extends CustomPainter {
  final Color c;
  _EcgPainter(this.c);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()..moveTo(0, s.height / 2);
    final n = 4;
    for (var i = 0; i < n; i++) {
      final x = s.width * i / n;
      final w = s.width / n;
      p.lineTo(x + w * .25, s.height / 2);
      p.lineTo(x + w * .32, s.height * .72);
      p.lineTo(x + w * .42, s.height * .02);
      p.lineTo(x + w * .52, s.height * .98);
      p.lineTo(x + w * .60, s.height / 2);
      p.lineTo(x + w, s.height / 2);
    }
    canvas.drawPath(p, Paint()..color = c.withOpacity(.4)..style = PaintingStyle.stroke..strokeWidth = 5..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(p, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_) => false;
}
