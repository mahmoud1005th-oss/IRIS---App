import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login_page.dart' show kIrisAccent, IrisLogo;

// شاشة Live (واجهة فقط): اللوجو صغير بيلف وهو ساكت. لما آيرس تتكلم اللوجو بيقف
// وبيروح للشمال في نص الشاشة، وخطوط هولوجرام بتطلع منه لفقاعة الكلام.
// مع الكاميرا: سهم هولوجرام وإطار بيشاوروا على الشجرة. مفيش رؤية حقيقية ولا صوت في النسخة دي.
enum LiveState { idle, speaking, camera, share }

const Color _bg = Color(0xFF05080C);
const Color _card = Color(0xFF111A24);
const Color _holo = Color(0xFF6FD3FF);

class LiveView extends StatefulWidget {
  final LiveState initial;
  final VoidCallback? onClose;
  final bool demoScript; // يتنقل لوحده بين الحالات
  final double? freeze; // للصور الثابتة: الزمن بالثواني
  final String name;
  final int camStep; // ٠ شايفة الشجرة؟ · ١ بلاستيك ولا حقيقية؟ · ٢ اشرح أكتر
  const LiveView({super.key, this.initial = LiveState.idle, this.onClose, this.demoScript = true, this.freeze, this.name = 'محمود', this.camStep = 0});
  @override
  State<LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> with TickerProviderStateMixin {
  late LiveState _s = widget.initial;
  bool _menu = false;
  late int _camStep = widget.camStep;
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 12));
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _menuC = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    if (widget.freeze != null) {
      _t.value = (widget.freeze! / 12).clamp(0.0, 1.0);
    } else {
      _t.repeat();
    }
    if (_s != LiveState.idle) _move.value = 1;
  }

  @override
  void dispose() {
    _camTimer?.cancel();
    _t.dispose();
    _move.dispose();
    _menuC.dispose();
    super.dispose();
  }

  Timer? _camTimer;

  void _set(LiveState s) {
    _camTimer?.cancel();
    if (s == LiveState.camera && widget.freeze == null) {
      _camStep = 0;
      _camTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_camStep < 2) setState(() => _camStep++);
      });
    }
    setState(() {
      _s = s;
      _menu = false;
    });
    _menuC.reverse();
    s == LiveState.idle ? _move.reverse() : _move.forward();
  }

  Widget _ctl(IconData i, Color c, VoidCallback f, {bool glow = false}) => GestureDetector(
        onTap: f,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(.10), border: Border.all(color: c.withOpacity(.8), width: 1.6), boxShadow: [BoxShadow(color: c.withOpacity(glow ? .5 : .25), blurRadius: glow ? 22 : 14)]),
          child: Icon(i, color: c, size: 26),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: _bg,
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          return AnimatedBuilder(
            animation: Listenable.merge([_t, _move, _menuC]),
            builder: (_, __) {
              final m = Curves.easeInOutCubic.transform(_move.value);
              final tt = _t.value * 12;
              final centerLogo = Offset(w / 2, h * 0.40);
              final leftLogo = _s == LiveState.camera ? Offset(w * 0.13, h * 0.095) : (_s == LiveState.share ? Offset(w * 0.13, h * 0.095) : Offset(w * 0.17, h * 0.42));
              final pos = Offset.lerp(centerLogo, leftLogo, m)!;
              final size = (_s == LiveState.camera || _s == LiveState.share ? 96.0 - 44 * m : 96.0 - 14 * m);
              final spinning = _s == LiveState.idle;
              final angle = spinning ? tt * 2 * math.pi / 6 : 0.0;
              final speaking = _s == LiveState.speaking;
              final cam = _s == LiveState.camera;
              final share = _s == LiveState.share;
              final bubbleRect = Rect.fromLTWH(w * 0.46, h * 0.17, w * 0.50, h * 0.50);
              return Stack(children: [
                // خلفية HUD خفيفة
                Positioned.fill(child: CustomPaint(painter: _HudBg(tt, pos, m))),
                if (cam) Positioned(left: w * 0.08, right: w * 0.08, top: h * 0.17, height: h * 0.58, child: _CameraView(t: tt, w: w * 0.84)),
                // خطوط الهولوجرام من اللوجو للفقاعة
                if (speaking) Positioned.fill(child: CustomPaint(painter: _BeamPainter(tt, pos, [for (var i = 0; i < 3; i++) _stepRect(bubbleRect, i)]))),
                if (speaking)
                  for (var i = 0; i < 3; i++)
                    Positioned.fromRect(
                      rect: _stepRect(bubbleRect, i),
                      child: _StepBox(n: i + 1, text: const ['افتح الإعدادات', 'اختار "الخصوصية"', 'فعّل البصمة'][i]),
                    ),
                if (speaking) Positioned(left: pos.dx - 46, top: pos.dy + 56, width: 92, child: _Talk(t: tt)),
                if (share) ..._shareOverlay(w, h, tt),
                if (cam) ..._camOverlay(w, h, tt, pos),
                // اللوجو
                Positioned(
                  left: pos.dx - size / 2,
                  top: pos.dy - size / 2,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: kIrisAccent.withOpacity(speaking || cam ? .30 : .16 + .08 * math.sin(tt * 2)), blurRadius: speaking ? 30 : 22)]),
                    child: Transform.rotate(angle: angle, child: IrisLogo(size: size)),
                  ),
                ),
                if (_s == LiveState.idle)
                  Positioned(left: 0, right: 0, top: h * 0.40 + 72, child: Center(child: Text('أنا جاهز دايما وقت ما تكون مستعد', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)))),
                // شريط تنبيه
                Positioned(
                  top: 8,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(color: const Color(0xFF2A2210), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFC857).withOpacity(.5))),
                    child: const Text('اللايف شكل فقط (واجهة) في النسخة دي · مفيش رؤية ولا صوت حقيقي لسه', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFC857), fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ),
                // قايمة الكاميرا
                if (_menuC.value > 0)
                  Positioned(
                    bottom: 98,
                    left: w / 2 - 80,
                    width: 160,
                    child: Opacity(
                      opacity: _menuC.value,
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * Curves.easeOutBack.transform(_menuC.value.clamp(0.0, 1.0)),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF122434), borderRadius: BorderRadius.circular(16), border: Border.all(color: _holo.withOpacity(.35))),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            GestureDetector(onTap: () => _set(LiveState.camera), behavior: HitTestBehavior.opaque, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9), child: Row(children: [Icon(Icons.photo_camera_outlined, color: Colors.white70, size: 20), SizedBox(width: 10), Text('فتح الكاميرا', style: TextStyle(color: Colors.white, fontSize: 14))]))),
                            GestureDetector(onTap: () => _set(LiveState.share), behavior: HitTestBehavior.opaque, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9), child: Row(children: [Icon(Icons.smartphone_rounded, color: Colors.white70, size: 20), SizedBox(width: 10), Text('مشاركة الشاشة', style: TextStyle(color: Colors.white, fontSize: 14))]))),
                          ]),
                        ),
                      ),
                    ),
                  ),
                // أزرار التحكم
                Positioned(
                  bottom: 22,
                  left: 0,
                  right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _ctl(Icons.close_rounded, const Color(0xFFFF5C6C), () => widget.onClose?.call()),
                    _ctl(Icons.videocam_outlined, _holo, () {
                      setState(() => _menu = !_menu);
                      _menu ? _menuC.forward() : _menuC.reverse();
                    }),
                    _ctl(Icons.mic_none_rounded, _holo, () => _set(_s == LiveState.idle ? LiveState.speaking : LiveState.idle), glow: speaking),
                  ]),
                ),
              ]);
            },
          );
        }),
      ),
    );
  }

  static const _q = ['شايفة الشجرة اللي قدامي؟', 'هي بلاستيك ولا طبيعية؟', 'اشرح أكتر'];
  static const _a = [
    'أيوه، شايفة الشجرة قدامك. دي نبتة في أصيص، وأوراقها خضرا وصحتها كويسة.',
    'طبيعية. الورق ليه عروق واضحة وملمسه مش لامع زي البلاستيك، والأطراف فيها اختلاف بسيط.',
    'تمام. النبتة محتاجة نور غير مباشر وسقي كل ٣ أيام تقريباً. لو الورق اصفر يبقى الميّة زيادة. تحب أقولك إزاي تقلبها؟',
  ];

  List<Widget> _shareOverlay(double w, double h, double tt) => [
        Positioned(
          left: w * 0.2,
          right: w * 0.06,
          top: h * 0.09,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF0D2233).withOpacity(.92), borderRadius: BorderRadius.circular(16), border: Border.all(color: _holo.withOpacity(.5))),
            child: const Text('أنا شايفة شاشتك. دوس على "الخصوصية" وأنا أقولك تعمل إيه بعدها.', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          ),
        ),
        Positioned(
          left: w * 0.18,
          right: w * 0.18,
          top: h * 0.24,
          height: h * 0.50,
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFF0B1118), borderRadius: BorderRadius.circular(20), border: Border.all(color: _holo.withOpacity(.6), width: 1.5), boxShadow: [BoxShadow(color: _holo.withOpacity(.2), blurRadius: 22)]),
            child: Column(children: [
              const SizedBox(height: 14),
              const Text('شاشتك (تجريبي)', style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 10),
              for (final r in ['الإعدادات', 'الخصوصية', 'الإشعارات', 'البصمة'])
                Container(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: r == 'الخصوصية' ? _holo.withOpacity(.18) : _card, borderRadius: BorderRadius.circular(10), border: Border.all(color: r == 'الخصوصية' ? _holo : Colors.white10)), child: Row(children: [Text(r, style: const TextStyle(color: Colors.white, fontSize: 13)), const Spacer(), if (r == 'الخصوصية') const Icon(Icons.touch_app, color: _holo, size: 18)])),
            ]),
          ),
        ),
        Positioned(left: w * 0.18, right: w * 0.18, bottom: 108, child: Container(padding: const EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(color: const Color(0xFF1B2B1F), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2EE66B).withOpacity(.5))), child: const Text('مشاركة الشاشة شغالة (شكل تجريبي)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF2EE66B), fontSize: 12.5, fontWeight: FontWeight.w700)))),
      ];

  List<Widget> _camOverlay(double w, double h, double tt, Offset pos) {
    final plant = Rect.fromLTWH(w * 0.36, h * 0.30, w * 0.36, h * 0.36);
    final pulse = 0.5 + 0.5 * math.sin(tt * 3);
    final st = _camStep.clamp(0, 2);
    return [
      Positioned.fill(child: CustomPaint(painter: _ArrowPainter(tt, plant, pulse, st))),
      Positioned(
        left: w * 0.24,
        right: w * 0.06,
        top: h * 0.075,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF0D2233).withOpacity(.92), borderRadius: BorderRadius.circular(16), border: Border.all(color: _holo.withOpacity(.5))),
          child: Text(_a[st], textAlign: TextAlign.start, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5)),
        ),
      ),
      Positioned(left: pos.dx - 36, top: pos.dy + 34, width: 72, child: _Talk(t: tt)),
      Positioned(
        left: w * 0.12,
        right: w * 0.12,
        bottom: 108,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
          child: Text('انت: ${_q[st]}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
      ),
    ];
  }
}

Rect _stepRect(Rect b, int i) => Rect.fromLTWH(b.left + 34 * (i == 1 ? 1 : 0), b.top + 28 + i * 62.0, 150, 38);

class _StepBox extends StatelessWidget {
  final int n;
  final String text;
  const _StepBox({required this.n, required this.text});
  @override
  Widget build(BuildContext context) {
    // فقاعة صغيرة زي رسايل واتساب
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xFF123047), borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(14), bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)), border: Border.all(color: _holo.withOpacity(.7)), boxShadow: [BoxShadow(color: _holo.withOpacity(.25), blurRadius: 12)]),
      alignment: Alignment.centerRight,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$n', style: const TextStyle(color: _holo, fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(width: 7),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

// موجة صغيرة تحت اللوجو: آيرس بتتكلم
class _Talk extends StatelessWidget {
  final double t;
  const _Talk({required this.t});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var i = 0; i < 9; i++) Container(width: 4, height: 6 + 16 * (0.5 + 0.5 * math.sin(t * 7 + i * .9)).abs(), margin: const EdgeInsets.symmetric(horizontal: 1.5), decoration: BoxDecoration(color: kIrisAccent, borderRadius: BorderRadius.circular(2))),
    ]);
  }
}

class _Bubble extends StatelessWidget {
  final double t;
  final List<String> lines;
  const _Bubble({required this.t, required this.lines});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(color: const Color(0xFF0F2336).withOpacity(.92), borderRadius: BorderRadius.circular(18), border: Border.all(color: _holo.withOpacity(.5)), boxShadow: [BoxShadow(color: _holo.withOpacity(.18), blurRadius: 20)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('هشرحلك الخطوات:', style: TextStyle(color: kIrisAccent, fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final l in lines) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(l, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

class _HudBg extends CustomPainter {
  final double t;
  final Offset c;
  final double m;
  _HudBg(this.t, this.c, this.m);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _holo.withOpacity(.10 + .06 * (1 - m));
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(c, 70.0 + i * 34, p);
    }
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = _holo.withOpacity(.35);
    final r = 104.0;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), t * 0.9, 1.0, false, arc);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r + 34), -t * 0.6 + 2, 0.8, false, arc);
  }

  @override
  bool shouldRepaint(_HudBg o) => true;
}

// خطوط هولوجرام بتطلع من اللوجو لكل خطوة في الفقاعة وعليها نبضات ضوء
class _BeamPainter extends CustomPainter {
  final double t;
  final Offset from;
  final List<Rect> boxes;
  _BeamPainter(this.t, this.from, this.boxes);
  @override
  void paint(Canvas canvas, Size s) {
    for (var i = 0; i < boxes.length; i++) {
      final target = Offset(boxes[i].left - 2, boxes[i].center.dy);
      final start = from + const Offset(40, 0);
      // خط مستقيم بسيط: توهج عريض + قلب ساطع + نبضة
      canvas.drawLine(start, target, Paint()..strokeWidth = 10..strokeCap = StrokeCap.round..color = _holo.withOpacity(.20)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      canvas.drawLine(start, target, Paint()..strokeWidth = 2.6..strokeCap = StrokeCap.round..color = _holo);
      canvas.drawLine(start, target, Paint()..strokeWidth = 1..color = Colors.white.withOpacity(.9));
      final f = (t * 0.7 + i * 0.25) % 1.0;
      final p = Offset.lerp(start, target, f)!;
      canvas.drawCircle(p, 9, Paint()..color = _holo.withOpacity(.30));
      canvas.drawCircle(p, 3.2, Paint()..color = Colors.white);
      canvas.drawCircle(target, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(target, 8, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = _holo);
    }
  }

  @override
  bool shouldRepaint(_BeamPainter o) => true;
}

class _CameraView extends StatelessWidget {
  final double t, w;
  const _CameraView({required this.t, required this.w});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _SceneBg())),
        Positioned(top: 10, right: 12, child: Row(children: const [Icon(Icons.circle, color: Color(0xFFFF5C6C), size: 9), SizedBox(width: 5), Text('كاميرا (شكل تجريبي)', style: TextStyle(color: Colors.white70, fontSize: 11))])),
      ]),
    );
  }
}

class _SceneBg extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF16222C), Color(0xFF0B1218)]).createShader(Offset.zero & s));
    final floor = Paint()..color = const Color(0xFF121C25);
    canvas.drawRect(Rect.fromLTWH(0, s.height * 0.78, s.width, s.height * 0.22), floor);
    // أصيص ونبتة
    final cx = s.width * 0.55, base = s.height * 0.80;
    canvas.drawPath(Path()..moveTo(cx - 34, base - 52)..lineTo(cx + 34, base - 52)..lineTo(cx + 26, base)..lineTo(cx - 26, base)..close(), Paint()..color = const Color(0xFF3A2C26));
    final stem = Paint()..color = const Color(0xFF2F5A3E)..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    final leaf = Paint()..color = const Color(0xFF2E6B45);
    final leaf2 = Paint()..color = const Color(0xFF3C8A58);
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + (i - 3) * 0.42;
      final len = s.height * (0.22 + 0.05 * (3 - (i - 3).abs()) / 3);
      final end = Offset(cx + math.cos(a) * len, base - 52 + math.sin(a) * len);
      canvas.drawLine(Offset(cx, base - 52), end, stem);
      canvas.save();
      canvas.translate(end.dx, end.dy);
      canvas.rotate(a + math.pi / 2);
      canvas.drawOval(Rect.fromCenter(center: const Offset(0, -10), width: 34, height: 58), i.isEven ? leaf : leaf2);
      canvas.restore();
    }
    // شكل كنبة بعيد
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.05, s.height * 0.60, s.width * 0.28, s.height * 0.18), const Radius.circular(12)), Paint()..color = const Color(0xFF1A2631));
  }

  @override
  bool shouldRepaint(_SceneBg o) => false;
}

// سهم هولوجرام جاي من فقاعة الرد + إطار بزوايا حوالين النبتة
class _ArrowPainter extends CustomPainter {
  final double t;
  final Rect plant;
  final double pulse;
  final int step;
  _ArrowPainter(this.t, this.plant, this.pulse, this.step);
  @override
  void paint(Canvas canvas, Size s) {
    final r = plant.inflate(6 * pulse);
    final corner = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..color = _holo;
    final glow = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = _holo.withOpacity(.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    const L = 26.0;
    void c(Offset o, double dx, double dy) {
      final p = Path()..moveTo(o.dx + dx * L, o.dy)..lineTo(o.dx, o.dy)..lineTo(o.dx, o.dy + dy * L);
      canvas.drawPath(p, glow);
      canvas.drawPath(p, corner);
    }

    c(r.topLeft, 1, 1);
    c(r.topRight, -1, 1);
    c(r.bottomLeft, 1, -1);
    c(r.bottomRight, -1, -1);
    // السهم من فوق شمال لحد الإطار
    final tip = Offset(r.left - 4, r.top + r.height * 0.25);
    final tail = Offset(s.width * 0.30, s.height * 0.20);
    final path = Path()..moveTo(tail.dx, tail.dy)..quadraticBezierTo(tail.dx, tip.dy, tip.dx - 6, tip.dy);
    canvas.drawPath(path, glow);
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.6..color = _holo);
    final head = Path()..moveTo(tip.dx, tip.dy)..lineTo(tip.dx - 16, tip.dy - 10)..lineTo(tip.dx - 16, tip.dy + 10)..close();
    canvas.drawPath(head, Paint()..color = _holo);
    if (step == 1) {
      for (final f in [const Offset(0.28, 0.30), const Offset(0.70, 0.22)]) {
        final o = Offset(r.left + r.width * f.dx, r.top + r.height * f.dy);
        canvas.drawCircle(o, 22 + 4 * pulse, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFFFC857));
        canvas.drawCircle(o, 3, Paint()..color = const Color(0xFFFFC857));
      }
    }
    // خط مسح بيطلع ويرجع على النبتة
    final y = r.top + r.height * ((t * 0.5) % 1.0);
    canvas.drawLine(Offset(r.left, y), Offset(r.right, y), Paint()..color = _holo.withOpacity(.55)..strokeWidth = 1.6);
  }

  @override
  bool shouldRepaint(_ArrowPainter o) => true;
}
