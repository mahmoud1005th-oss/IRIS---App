import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'login_page.dart' show kIrisAccent, IrisLogo;
import 'batch3_preview.dart' show badge;

const Color _bg = Color(0xFF05080C);
const Color _card = Color(0xFF111A24);
const Color _ok = Color(0xFF2EE66B);
const Color _gold = Color(0xFFFFC857);

Widget _btn(String t, {Color? c, bool on = true}) => Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: on ? (c ?? kIrisAccent) : Colors.white10, borderRadius: BorderRadius.circular(24)),
      child: Text(t, style: TextStyle(color: on ? Colors.black : Colors.white38, fontWeight: FontWeight.w800, fontSize: 16)),
    );

// ===== شاشة الريلز الإعلاني (Promo) =====
// press: 0 عادي، 1 ضغط على "آيرس يكتب السكريبت" بتأثير زجاجي، 2 بعد الاختيار
class PromoReelFrame extends StatelessWidget {
  final int mode; // 0 اكتب السكريبت بنفسي، 1 آيرس يكتبه
  final bool pressing;
  final int sec;
  const PromoReelFrame({super.key, this.mode = 0, this.pressing = false, this.sec = 15});

  Widget _seg(String t, bool sel, {bool press = false}) => Expanded(
        child: Stack(alignment: Alignment.center, children: [
          Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: sel ? kIrisAccent.withOpacity(.22) : _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? kIrisAccent : Colors.white12, width: sel ? 1.8 : 1)),
            child: Text(t, style: TextStyle(color: Colors.white, fontWeight: sel ? FontWeight.w800 : FontWeight.w500, fontSize: 13.5)),
          ),
          if (press)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [Colors.white.withOpacity(.38), Colors.white.withOpacity(.08)], radius: .9),
                      border: Border.all(color: Colors.white.withOpacity(.5)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Opacity(opacity: .22, child: const IrisLogo(size: 34))),
                  ),
                ),
              ),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final ai = mode == 1;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  const Text('ريلز إعلاني', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: _gold.withOpacity(.16), border: Border.all(color: _gold), borderRadius: BorderRadius.circular(10)), child: const Text('مدفوع', style: TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w800))),
                  const Spacer(),
                  const IrisLogo(size: 32),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _seg('أكتب السكريبت بنفسي', !ai),
                  const SizedBox(width: 10),
                  _seg('آيرس يكتبه من المنتج', ai, press: pressing),
                ]),
                const SizedBox(height: 14),
                Text(ai ? 'اسم المنتج ووصفه' : 'السكريبت', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  height: 84,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: kIrisAccent.withOpacity(.5))),
                  child: Text(ai ? 'عسل سدر طبيعي من مزرعتنا، عبوة ٥٠٠ جم، توصيل لكل مصر' : 'اكتب كلام الإعلان هنا...', style: TextStyle(color: ai ? Colors.white : Colors.white38, fontSize: 14.5, height: 1.6)),
                ),
                if (ai)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: const [Icon(Icons.auto_awesome, color: kIrisAccent, size: 16), SizedBox(width: 6), Expanded(child: Text('آيرس هيكتب السكريبت ويعرضه عليك قبل التوليد', style: TextStyle(color: Colors.white54, fontSize: 12)))]),
                  ),
                const SizedBox(height: 10),
                Row(children: [
                  Container(
                    height: 54, padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: kIrisAccent.withOpacity(.6))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 32, height: 32, decoration: BoxDecoration(color: kIrisAccent.withOpacity(.2), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.add_photo_alternate_outlined, color: kIrisAccent, size: 20)),
                      const SizedBox(width: 10),
                      Text(ai ? 'أضف صورة المنتج' : 'أضف صورة', style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  for (final c in [Color(0xFFE08E45), Color(0xFF6FB1E4)])
                    Container(width: 54, height: 54, margin: const EdgeInsetsDirectional.only(end: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [c, c.withOpacity(.4)]), border: Border.all(color: Colors.white24)), child: const Align(alignment: Alignment.topLeft, child: Padding(padding: EdgeInsets.all(3), child: Icon(Icons.cancel, color: Colors.white70, size: 15)))),
                ]),
                const SizedBox(height: 10),
                const Text('مدة الفيديو', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  height: 110,
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
                  child: Stack(alignment: Alignment.center, children: [
                    Container(height: 40, margin: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: kIrisAccent.withOpacity(.16), borderRadius: BorderRadius.circular(12), border: Border.all(color: kIrisAccent.withOpacity(.6)))),
                    ListWheelScrollView.useDelegate(
                      controller: FixedExtentScrollController(initialItem: (sec ~/ 5) - 1),
                      itemExtent: 40,
                      diameterRatio: 1.5,
                      perspective: .004,
                      physics: const NeverScrollableScrollPhysics(),
                      childDelegate: ListWheelChildListDelegate(children: [
                        for (final s in [5, 10, 15, 20, 25, 30])
                          Center(child: Text('$s ثانية', style: TextStyle(color: s == sec ? Colors.white : Colors.white38, fontSize: s == sec ? 22 : 17, fontWeight: s == sec ? FontWeight.w800 : FontWeight.w500))),
                      ]),
                    ),
                  ]),
                ),
                const Spacer(),
                Container(
                  height: 48, alignment: Alignment.center,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: _gold, width: 1.5), color: _gold.withOpacity(.12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.lock_outline, color: _gold, size: 18), SizedBox(width: 8), Text('ادفع لصناعة الاعلان الخاص بك', style: TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 14.5))]),
                ),
                const SizedBox(height: 6),
                const Center(child: Text('الإعلان بيتصنع بعد الدفع بس', style: TextStyle(color: Colors.white30, fontSize: 11))),
              ]),
            ),
          ),
          badge('ريلز إعلاني${pressing ? ' · ضغط زجاجي' : ''}'),
        ]),
      ),
    );
  }
}

// ===== التلفزيون =====
class _TvBack extends StatelessWidget {
  const _TvBack();
  @override
  Widget build(BuildContext context) {
    final cols = [
      [Color(0xFF7B2D26), Color(0xFFE08E45)], [Color(0xFF1F4E79), Color(0xFF6FB1E4)], [Color(0xFF3A1F5C), Color(0xFFB57BEE)],
      [Color(0xFF1E5B3A), Color(0xFF7FD69A)], [Color(0xFF5C1F3F), Color(0xFFEE7BAA)], [Color(0xFF3F4F1F), Color(0xFFCADB6B)],
    ];
    return Container(
      color: const Color(0xFF0F0F0F),
      padding: const EdgeInsets.all(28),
      child: GridView.count(crossAxisCount: 3, crossAxisSpacing: 18, mainAxisSpacing: 18, childAspectRatio: 1.9, physics: const NeverScrollableScrollPhysics(), children: [
        for (final c in cols) Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: c, begin: Alignment.topLeft, end: Alignment.bottomRight))),
      ]),
    );
  }
}

Widget _panel(Widget child, {double w = 520, Color c = kIrisAccent}) => ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: w,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: BoxDecoration(color: const Color(0xFF05080C).withOpacity(.40), borderRadius: BorderRadius.circular(26), border: Border.all(color: c.withOpacity(.4))),
        child: child,
      ),
    );

Widget _you(String t) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person, color: Colors.white54, size: 16), const SizedBox(width: 6), Text(t, style: const TextStyle(color: Colors.white, fontSize: 17))]),
    );

class TvReelFlowFrame extends StatelessWidget {
  final int step; // 0 قال، 1 بيعمل، 2 تم وحُفظ على الموبايل
  const TvReelFlowFrame({super.key, required this.step});
  @override
  Widget build(BuildContext context) {
    final c = step == 2 ? _ok : kIrisAccent;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          const Positioned.fill(child: _TvBack()),
          Positioned(
            bottom: 34,
            left: 0,
            right: 0,
            child: Center(
              child: _panel(c: c, Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const IrisLogo(size: 36),
                  const SizedBox(width: 10),
                  Text('TV IRIS', style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ]),
                const SizedBox(height: 8),
                if (step == 0) ...[
                  _you('TV IRIS، اعمللي ريلز واحفظه على موبايلي'),
                  const Text('تمام يا محمود، ريلز عن إيه؟', style: TextStyle(color: kIrisAccent, fontSize: 17, fontWeight: FontWeight.w600)),
                ],
                if (step == 1) ...[
                  const Text('بعمل الريلز دلوقتي...', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: .62, minHeight: 7, backgroundColor: Colors.white12, color: kIrisAccent)),
                ],
                if (step == 2) ...[
                  const Icon(Icons.check_circle, color: _ok, size: 30),
                  const SizedBox(height: 4),
                  const Text('خلص، واتحفظ على موبايلك', style: TextStyle(color: _ok, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Text('هتلاقيه في آيرس · مكتبتي', style: TextStyle(color: Colors.white60, fontSize: 13)),
                ],
                const SizedBox(height: 8),
                Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(.18), border: Border.all(color: c, width: 2)), child: Icon(step == 2 ? Icons.phone_android : (step == 1 ? Icons.hourglass_top : Icons.mic), color: c, size: 24)),
              ])),
            ),
          ),
          badge('تلفزيون · ${['قول الأمر', 'بيتعمل', 'اتحفظ على الموبايل'][step]}'),
        ]),
      ),
    );
  }
}

class PhoneSavedFrame extends StatelessWidget {
  const PhoneSavedFrame({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          body: Stack(children: [
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 30, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _ok.withOpacity(.6))),
                  child: Row(children: const [IrisLogo(size: 36), SizedBox(width: 10), Expanded(child: Text('IRIS · ريلز جديد من التلفزيون جاهز', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)))]),
                ),
                const SizedBox(height: 18),
                const Text('مكتبتي', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Expanded(child: Row(children: [
                  Expanded(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF1F4E79), Color(0xFF6FB1E4)], begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: _ok, width: 2)), child: const Align(alignment: Alignment.topLeft, child: Padding(padding: EdgeInsets.all(8), child: Text('جديد', style: TextStyle(color: _ok, fontWeight: FontWeight.w800)))))),
                  const SizedBox(width: 10),
                  Expanded(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _card))),
                ])),
                const SizedBox(height: 12),
                _btn('شغّل الريلز'),
              ]),
            )),
            badge('موبايل · الريلز اتحفظ'),
          ]),
        ),
      );
}

// ===== ذاكرة لكل جهاز: رسم + رسالة التلفزيون =====
class MemoryDiagramFrame extends StatelessWidget {
  const MemoryDiagramFrame({super.key});
  Widget _dev(IconData ic, String n) => Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: kIrisAccent.withOpacity(.5))),
        child: Column(children: [
          Icon(ic, color: kIrisAccent, size: 34),
          const SizedBox(height: 6),
          Text(n, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('محادثات الجهاز ده بس', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          const Icon(Icons.lock_outline, color: Colors.white38, size: 16),
        ]),
      );
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          body: Stack(children: [
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: _ok.withOpacity(.7), width: 1.6), gradient: LinearGradient(colors: [_ok.withOpacity(.20), _card])),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [IrisLogo(size: 48), SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الذاكرة الأساسية · مشتركة', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), Text('اسمك، تفضيلاتك، مشاريعك، حساباتك', style: TextStyle(color: Colors.white60, fontSize: 13))])]),
                ),
                SizedBox(height: 34, child: CustomPaint(size: const Size(600, 34), painter: _Fork())),
                Row(mainAxisSize: MainAxisSize.min, children: [_dev(Icons.phone_android, 'الموبايل'), const SizedBox(width: 30), _dev(Icons.laptop, 'اللابتوب'), const SizedBox(width: 30), _dev(Icons.tv, 'التلفزيون')]),
              ]),
            ),
            badge('نظام الذاكرة'),
          ]),
        ),
      );
}

class _Fork extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = kIrisAccent.withOpacity(.6)..strokeWidth = 2..style = PaintingStyle.stroke;
    final cx = s.width / 2;
    c.drawLine(Offset(cx, 0), Offset(cx, s.height / 2), p);
    c.drawLine(Offset(cx - 235, s.height / 2), Offset(cx + 235, s.height / 2), p);
    for (final x in [-235.0, 0.0, 235.0]) c.drawLine(Offset(cx + x, s.height / 2), Offset(cx + x, s.height), p);
  }
  @override
  bool shouldRepaint(_) => false;
}

class TvMemoryPromptFrame extends StatelessWidget {
  final int step; // 0 قال، 1 السؤال، 2 اختار الموبايل
  const TvMemoryPromptFrame({super.key, required this.step});
  Widget _opt(IconData ic, String t, {bool sel = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(color: sel ? kIrisAccent.withOpacity(.3) : Colors.white10, borderRadius: BorderRadius.circular(18), border: Border.all(color: sel ? kIrisAccent : Colors.white24, width: sel ? 2 : 1)),
        child: Column(children: [Icon(ic, color: sel ? kIrisAccent : Colors.white70, size: 28), const SizedBox(height: 4), Text(t, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))]),
      );
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(children: [
            const Positioned.fill(child: _TvBack()),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: _panel(w: 700, Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: const [IrisLogo(size: 34), SizedBox(width: 10), Text('TV IRIS', style: TextStyle(color: kIrisAccent, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2))]),
                  const SizedBox(height: 8),
                  if (step == 0) ...[_you('TV IRIS، كمّل معايا في مشروع التخرج'), const Text('ثواني...', style: TextStyle(color: kIrisAccent, fontSize: 17))],
                  if (step >= 1) ...[
                    const Text('فاكر مشروع التخرج؟ عايز نتكلم فيه هنا على التلفزيون،\nولا على موبايلك أو اللابتوب عشان خصوصية أكتر؟', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.6)),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [_opt(Icons.tv, 'هنا على التلفزيون'), const SizedBox(width: 12), _opt(Icons.phone_android, 'على موبايلي', sel: step == 2), const SizedBox(width: 12), _opt(Icons.laptop, 'على اللابتوب')]),
                  ],
                  if (step == 2) ...[const SizedBox(height: 10), const Text('تمام، فتحتهالك على موبايلك', style: TextStyle(color: _ok, fontSize: 16, fontWeight: FontWeight.w700))],
                ])),
              ),
            ),
            badge('تلفزيون · ${['قول الأمر', 'سؤال الخصوصية', 'اختار الموبايل'][step]}'),
          ]),
        ),
      );
}

// ===== ربط التلفزيون بجوجل الرسمي =====
class GoogleLinkFrame extends StatelessWidget {
  final int step; // 0 موبايل: افتح جوجل، 1 تلفزيون: وصل تسجيل جوجل بالكود
  const GoogleLinkFrame({super.key, required this.step});
  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          body: Stack(children: [
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Column(children: [
                Row(children: List.generate(4, (i) => Expanded(child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: i < 3 ? kIrisAccent : Colors.white12, borderRadius: BorderRadius.circular(2)))))),
                const SizedBox(height: 24),
                const Text('سجّل دخول التلفزيون بحساب جوجل', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('بتسجّل من صفحة جوجل الرسمية على موبايلك. آيرس مش بيشوف ولا بيكتب الباسورد', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6)),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Column(children: [
                    Row(children: const [Text('G', style: TextStyle(color: Color(0xFF4285F4), fontSize: 30, fontWeight: FontWeight.w900)), SizedBox(width: 10), Text('Sign in with Google', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600))]),
                    const SizedBox(height: 12),
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(10)), child: Row(children: const [CircleAvatar(radius: 14, backgroundColor: Color(0xFF7C4DFF), child: Text('M', style: TextStyle(color: Colors.white))), SizedBox(width: 10), Text('mahmoud@gmail.com', style: TextStyle(color: Colors.black87))])),
                  ]),
                ),
                const Spacer(),
                _btn('كمّل'),
              ]),
            )),
            badge('موبايل · ٣ · جوجل الرسمي'),
          ]),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
            IrisLogo(size: 90), SizedBox(height: 22),
            Text('تم تسجيل الدخول بحساب جوجل من موبايلك', style: TextStyle(color: _ok, fontSize: 30, fontWeight: FontWeight.w800)),
            SizedBox(height: 10),
            Icon(Icons.verified_user, color: _ok, size: 72),
            SizedBox(height: 12),
            Text('mahmoud@gmail.com · تلفزيون الصالة مربوط', style: TextStyle(color: Colors.white60, fontSize: 18)),
          ])),
          badge('تلفزيون · متصل'),
        ]),
      ),
    );
  }
}

// ===== زر Live جنب خانة الكتابة =====
class LiveChatFrame extends StatelessWidget {
  final int step; // 0 عادي، 1 Live شغال، 2 بعد الخروج
  const LiveChatFrame({super.key, required this.step});

  Widget _livePill(bool on) => Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: on ? const LinearGradient(colors: [Color(0xFFFF5C7A), Color(0xFFFF9F4A)]) : null,
          color: on ? null : _card,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: on ? Colors.transparent : kIrisAccent.withOpacity(.6)),
          boxShadow: on ? [BoxShadow(color: const Color(0xFFFF5C7A).withOpacity(.5), blurRadius: 16)] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(on ? Icons.stop_rounded : Icons.graphic_eq, color: on ? Colors.white : kIrisAccent, size: 22),
          const SizedBox(width: 6),
          Text(on ? 'إنهاء' : 'Live', style: TextStyle(color: on ? Colors.white : kIrisAccent, fontWeight: FontWeight.w900, fontSize: 15)),
        ]),
      );

  Widget _wave() {
    final hs = <double>[10, 22, 36, 54, 30, 70, 44, 24, 60, 38, 18, 48, 28, 12];
    return Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
      for (var i = 0; i < hs.length; i++)
        Container(width: 6, height: hs[i], margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: Color.lerp(kIrisAccent, const Color(0xFFB57BEE), i / hs.length), borderRadius: BorderRadius.circular(3))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    Widget bub(String t, {bool me = false}) => Align(
          alignment: me ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(color: me ? kIrisAccent.withOpacity(.22) : _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: me ? kIrisAccent.withOpacity(.5) : Colors.white12)),
            child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
          ),
        );
    final live = step == 1;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          SafeArea(
            child: Column(children: [
              const SizedBox(height: 26),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [const Icon(Icons.menu, color: Colors.white70), const SizedBox(width: 12), const IrisLogo(size: 34), const SizedBox(width: 8), const Text('IRIS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3)), const Spacer(), if (live) Row(children: const [Icon(Icons.circle, color: Color(0xFFFF5C7A), size: 10), SizedBox(width: 5), Text('مباشر', style: TextStyle(color: Color(0xFFFF5C7A), fontWeight: FontWeight.w800))])])),
              const Divider(color: Colors.white12),
              Expanded(
                child: live
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 190, height: 190, alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [kIrisAccent.withOpacity(.35), kIrisAccent.withOpacity(.05), Colors.transparent]), border: Border.all(color: kIrisAccent.withOpacity(.25))),
                          child: Container(width: 120, height: 120, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: _card, border: Border.all(color: kIrisAccent, width: 2), boxShadow: [BoxShadow(color: kIrisAccent.withOpacity(.5), blurRadius: 30)]), child: const IrisLogo(size: 72)),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(height: 80, child: _wave()),
                        const SizedBox(height: 18),
                        const Text('بسمعك يا محمود...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text('اتكلم عادي، واضغط "إنهاء" وقت ما تحب', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ])
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: step == 0
                            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [IrisLogo(size: 90), SizedBox(height: 14), Text('أهلاً يا محمود', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)), Text('اكتب أو اضغط Live وكلمني', style: TextStyle(color: Colors.white54))])
                            : Column(children: [
                                const SizedBox(height: 10),
                                Center(child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), child: const Text('انتهت المحادثة المباشرة · ٢:١٠ دقيقة', style: TextStyle(color: Colors.white54, fontSize: 12)))),
                                bub('ذاكرلي درس الفيزياء بسرعة', me: true),
                                bub('أكيد يا محمود. خلصنا الفصل الأول، ونكمل الثاني بعدين.'),
                                const SizedBox(height: 4),
                                const Text('الكلام اتحفظ هنا كنص', style: TextStyle(color: Colors.white38, fontSize: 12)),
                              ]),
                      ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: Row(children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(25), border: Border.all(color: kIrisAccent.withOpacity(live ? .15 : .4))),
                      child: Row(children: [
                        Icon(Icons.mic, color: live ? Colors.white24 : kIrisAccent),
                        const SizedBox(width: 10),
                        Text(live ? 'الكتابة متوقفة وقت Live' : 'اكتب هنا...', style: const TextStyle(color: Colors.white38)),
                        const Spacer(),
                        Icon(Icons.add_circle_outline, color: live ? Colors.white24 : Colors.white54),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _livePill(live),
                ]),
              ),
            ]),
          ),
          badge(['الشات · زر Live', 'Live شغال', 'بعد الخروج'][step]),
        ]),
      ),
    );
  }
}


// ===== صفحة الدفع =====
class PayFrame extends StatelessWidget {
  final bool egypt;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final int step; // 0 اختيار الطريقة، 1 تحويل لصفحة مزوّد دفع مستضافة، 2 تأكيد
  const PayFrame({super.key, required this.step, this.egypt = true, this.onNext, this.onBack});

  Widget _m(IconData ic, String t, String sub, {bool sel = false, String? tag, Color c = kIrisAccent}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: sel ? c.withOpacity(.14) : _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: sel ? c : Colors.white12, width: sel ? 2 : 1)),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: c.withOpacity(.2), borderRadius: BorderRadius.circular(12)), child: Icon(ic, color: c, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 11.5, height: 1.4)),
            if (tag != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(tag, style: const TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w700))),
          ])),
          Icon(sel ? Icons.check_circle : Icons.radio_button_unchecked, color: sel ? c : Colors.white30),
        ]),
      );

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
        child: Row(children: [GestureDetector(onTap: onBack, child: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20)), const SizedBox(width: 10), Expanded(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))), const IrisLogo(size: 30)]),
      );

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (step == 0) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _head('الدفع'),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          Container(
            padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: Row(children: const [Icon(Icons.movie_creation_outlined, color: kIrisAccent), SizedBox(width: 10), Expanded(child: Text('ريلز إعلاني · ١٥ ثانية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), Text('[السعر: يحدده المالك]', style: TextStyle(color: _gold, fontSize: 12))]),
          ),
          const Text('اختار طريقة الدفع', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _m(Icons.credit_card, 'بطاقة ائتمان / فيزا', 'هتتحول لصفحة دفع آمنة عند مزوّد الدفع، آيرس مش بيشوف رقم البطاقة', sel: true),
          _m(Icons.account_balance_wallet_outlined, 'PayPal', 'الدفع لإيميل المالك', tag: '[إيميل PayPal: owner@example.com · يحدده المالك]', c: const Color(0xFF6FB1E4)),
          if (egypt) ...[
          Padding(padding: const EdgeInsets.only(top: 4, bottom: 8), child: Row(children: const [Icon(Icons.flag_outlined, color: Colors.white54, size: 16), SizedBox(width: 6), Text('متاحة لمستخدمين دولة مصر (حسب الدولة في الإعداد)', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700))])),
          _m(Icons.phone_android, 'فودافون كاش', 'تحويل على رقم المالك', tag: '[الرقم: 01XXXXXXXXX · يحدده المالك]', c: const Color(0xFFFF5C5C)),
          _m(Icons.bolt, 'إنستاباي', 'تحويل على عنوان المالك', tag: '[العنوان: name@instapay · يحدده المالك]', c: const Color(0xFFB57BEE)),
          _m(Icons.sim_card_outlined, 'اتصالات كاش', 'تحويل على رقم المالك', tag: '[الرقم: 011XXXXXXXX · يحدده المالك]', c: const Color(0xFF7FD69A)),
          _m(Icons.sim_card_outlined, 'أورنج كاش', 'تحويل على رقم المالك', tag: '[الرقم: 012XXXXXXXX · يحدده المالك]', c: const Color(0xFFFF9F4A)),
          ] else Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: const [Icon(Icons.public, color: Colors.white38, size: 16), SizedBox(width: 6), Expanded(child: Text('طرق الدفع المحلية مش ظاهرة لدولتك (حسب الدولة في الإعداد)', style: TextStyle(color: Colors.white38, fontSize: 12)))])),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 14), child: GestureDetector(onTap: onNext, child: _btn('كمّل للدفع'))),
      ]);
    } else if (step == 1) {
      body = Column(children: [
        _head('صفحة الدفع الآمنة'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
          child: Row(children: const [Icon(Icons.lock, color: _ok, size: 16), SizedBox(width: 8), Expanded(child: Text('pay.provider.example  ·  [مزوّد الدفع: يحدده المالك]', textDirection: TextDirection.ltr, style: TextStyle(color: Colors.white70, fontSize: 12)))]),
        ),
        const SizedBox(height: 14),
        Expanded(child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pay with card', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w800), textDirection: TextDirection.ltr),
            const SizedBox(height: 14),
            for (final l in ['Card number', 'MM / YY', 'CVC'])
              Container(margin: const EdgeInsets.only(bottom: 10), height: 44, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(8)), child: Text(l, style: const TextStyle(color: Colors.black38), textDirection: TextDirection.ltr)),
            const Spacer(),
            GestureDetector(onTap: onNext, child: Container(height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)), child: const Text('Pay (تجريبي)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
          ]),
        )),
        const Padding(padding: EdgeInsets.fromLTRB(24, 10, 24, 16), child: Text('الصفحة دي بتفتح عند مزوّد الدفع، وبعد الدفع بترجعك لآيرس. بيانات البطاقة مش بتتكتب جوه التطبيق', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5))),
      ]);
    } else {
      body = Column(children: [
        const Spacer(),
        Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: _ok.withOpacity(.15), border: Border.all(color: _ok, width: 3)), child: const Icon(Icons.check_rounded, color: _ok, size: 70)),
        const SizedBox(height: 22),
        const Text('تم الدفع (تجريبي)', style: TextStyle(color: _ok, fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('آيرس بدأ يجهّز الإعلان بتاعك', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('هتوصلك إشعار لما يخلص', style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 18),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
          child: Row(children: const [Icon(Icons.receipt_long, color: kIrisAccent), SizedBox(width: 10), Expanded(child: Text('ريلز إعلاني · ١٥ ثانية · بطاقة', style: TextStyle(color: Colors.white70, fontSize: 13)))]),
        ),
        const Spacer(),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: GestureDetector(onTap: onNext, child: _btn('رجوع للرئيسية', c: _ok))),
      ]);
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(backgroundColor: _bg, body: Stack(children: [SafeArea(child: body), badge('الدفع · ${egypt ? 'مصر' : 'دولة أخرى'} · ${['اختيار الطريقة', 'صفحة مزوّد الدفع', 'تأكيد'][step]}')])),
    );
  }
}


// ===== اختيار الدولة في التسجيل =====
class CountryPickFrame extends StatelessWidget {
  final bool open;
  const CountryPickFrame({super.key, this.open = true});
  @override
  Widget build(BuildContext context) {
    final cs = [['مصر', 'EG', true], ['السعودية', 'SA', false], ['الإمارات', 'AE', false], ['الكويت', 'KW', false], ['الولايات المتحدة', 'US', false], ['المملكة المتحدة', 'GB', false]];
    Widget f(String l, String v, {bool focus = false}) => Container(
          margin: const EdgeInsets.only(bottom: 10), height: 52, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: focus ? kIrisAccent : Colors.white12, width: focus ? 2 : 1)),
          child: Row(children: [Text(l, style: const TextStyle(color: Colors.white54, fontSize: 13)), const Spacer(), Text(v, style: const TextStyle(color: Colors.white, fontSize: 14.5))]),
        );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Center(child: IrisLogo(size: 64)),
              const SizedBox(height: 14),
              const Center(child: Text('إنشاء حساب', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
              const SizedBox(height: 18),
              f('الاسم', 'محمود'),
              f('الإيميل', 'mahmoud@gmail.com'),
              f('الدولة', open ? 'اختار دولتك' : 'مصر · EG', focus: open),
              if (open)
                Container(
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: kIrisAccent.withOpacity(.4))),
                  child: Column(children: [
                    for (final c in cs)
                      Container(
                        height: 46, padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(color: c[2] == true ? kIrisAccent.withOpacity(.18) : null, border: const Border(bottom: BorderSide(color: Colors.white10))),
                        child: Row(children: [Container(width: 34, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 3), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)), child: Text(c[1] as String, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800))), const SizedBox(width: 10), Text(c[0] as String, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)), const Spacer(), if (c[2] == true) const Icon(Icons.check, color: kIrisAccent, size: 20)]),
                      ),
                    const Padding(padding: EdgeInsets.all(10), child: Text('... وباقي دول العالم', style: TextStyle(color: Colors.white38, fontSize: 12))),
                  ]),
                )
              else
                const Padding(padding: EdgeInsets.only(top: 4), child: Text('الدولة بتحدد طرق الدفع المتاحة ليك (مثلاً فودافون كاش وإنستاباي لمصر بس)', style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5))),
              const Spacer(),
              _btn('إنشاء الحساب'),
            ]),
          )),
          badge('التسجيل · الدولة'),
        ]),
      ),
    );
  }
}
