import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login_page.dart' show kIrisAccent, IrisLogo;
import 'menu_preview.dart' show MenuList;
import 'batch3_preview.dart' show reelCard;
import 'batch3b_preview.dart' show PayFrame;
import 'flows_preview.dart' show PhoneWatchPreview;

const Color _bg = Color(0xFF05080C);
const Color _card = Color(0xFF111A24);
const Color _gold = Color(0xFFFFC857);
const Color _live = Color(0xFFFF5C7A);

const String kTestReply =
    'ايوه كده يا محمود، التيست اشتغل. جاهزين نربط السيرفرات عشان نولّد الكلام والصور والفيديوهات ونذاكر ونراجع مشاريعك.';

void _soon(BuildContext c, String what) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text('$what: قريباً (واجهة فقط في النسخة دي)', textDirection: TextDirection.rtl),
    duration: const Duration(seconds: 2),
  ));
}

class _Msg {
  final String text;
  final bool me;
  _Msg(this.text, this.me);
}

// الشاشة الرئيسية: شات + قائمة جانبية + زر Live
class IrisHome extends StatefulWidget {
  final String? gender;
  final String? language;
  final String? country;
  const IrisHome({super.key, this.gender, this.language, this.country});
  @override
  State<IrisHome> createState() => _IrisHomeState();
}

class _IrisHomeState extends State<IrisHome> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  bool _typing = false;
  bool _liveOn = false;
  int _liveSec = 0;
  Timer? _liveTimer;
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _country {
    if (widget.country != null) return widget.country!;
    return WidgetsBinding.instance.platformDispatcher.locale.countryCode ?? '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _pulse.dispose();
    _liveTimer?.cancel();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add(_Msg(t, true));
      _typing = true;
    });
    _ctrl.clear();
    _toBottom();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _msgs.add(_Msg(kTestReply, false));
      });
      _toBottom();
    });
  }

  void _toBottom() => Future.delayed(const Duration(milliseconds: 80), () {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  void _toggleLive() {
    if (_liveOn) {
      _liveTimer?.cancel();
      _pulse.stop();
      final d = _liveSec;
      setState(() {
        _liveOn = false;
        _msgs.add(_Msg('انتهت المحادثة المباشرة · ${d ~/ 60}:${(d % 60).toString().padLeft(2, '0')}', false));
      });
      _toBottom();
    } else {
      setState(() {
        _liveOn = true;
        _liveSec = 0;
      });
      _pulse.repeat();
      _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _liveSec++));
    }
  }

  void _onMenu(String t) {
    Navigator.pop(context);
    Widget? page;
    if (t == 'ريلز فيديو') page = const ReelsPage();
    if (t.contains('Promo')) page = PromoPage(country: _country);
    if (t == 'تركيز الطاقة') page = const WatchFlowPage();
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    } else {
      _soon(context, t);
    }
  }

  Widget _bubble(_Msg m) => Align(
        alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(color: m.me ? kIrisAccent.withOpacity(.22) : _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: m.me ? kIrisAccent.withOpacity(.5) : Colors.white12)),
          child: Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
        ),
      );

  Widget _liveBody() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final t = _pulse.value;
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 190 + 14 * math.sin(t * 2 * math.pi), height: 190 + 14 * math.sin(t * 2 * math.pi), alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [kIrisAccent.withOpacity(.35), kIrisAccent.withOpacity(.05), Colors.transparent]), border: Border.all(color: kIrisAccent.withOpacity(.25))),
            child: Container(width: 120, height: 120, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: _card, border: Border.all(color: kIrisAccent, width: 2), boxShadow: [BoxShadow(color: kIrisAccent.withOpacity(.5), blurRadius: 30)]), child: const IrisLogo(size: 72)),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 80,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
              for (var i = 0; i < 14; i++)
                Container(width: 6, height: 14 + 52 * (0.5 + 0.5 * math.sin(t * 2 * math.pi + i * .8)).abs(), margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: Color.lerp(kIrisAccent, const Color(0xFFB57BEE), i / 14), borderRadius: BorderRadius.circular(3))),
            ]),
          ),
          const SizedBox(height: 18),
          const Text('بسمعك يا محمود...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('الوضع المباشر شكل فقط حالياً، السيرفر لسه متوصلش', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('${_liveSec ~/ 60}:${(_liveSec % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: _live, fontWeight: FontWeight.w800)),
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _bg,
        drawer: Drawer(
          backgroundColor: const Color(0xFF0B1118),
          width: 320,
          child: SafeArea(child: SingleChildScrollView(child: MenuList(onSelect: _onMenu))),
        ),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(children: [
                GestureDetector(onTap: () => _scaffoldKey.currentState?.openDrawer(), child: const Icon(Icons.menu, color: Colors.white70)),
                const SizedBox(width: 12),
                const IrisLogo(size: 34),
                const SizedBox(width: 8),
                const Text('IRIS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const Spacer(),
                if (_liveOn) Row(children: const [Icon(Icons.circle, color: _live, size: 10), SizedBox(width: 5), Text('مباشر', style: TextStyle(color: _live, fontWeight: FontWeight.w800))]),
              ]),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: _liveOn
                  ? _liveBody()
                  : (_msgs.isEmpty
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [IrisLogo(size: 90), SizedBox(height: 14), Text('أهلاً يا محمود', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)), Text('اكتب أي كلمة أو اضغط Live', style: TextStyle(color: Colors.white54))])
                      : ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          children: [
                            for (final m in _msgs) _bubble(m),
                            if (_typing) Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)), child: const Text('...', style: TextStyle(color: kIrisAccent, fontSize: 18)))),
                          ],
                        )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(25), border: Border.all(color: kIrisAccent.withOpacity(_liveOn ? .15 : .4))),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          enabled: !_liveOn,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(border: InputBorder.none, hintText: _liveOn ? 'الكتابة متوقفة وقت Live' : 'اكتب هنا...', hintStyle: const TextStyle(color: Colors.white38)),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      GestureDetector(onTap: _liveOn ? null : _send, child: Icon(Icons.arrow_upward, color: _liveOn ? Colors.white24 : kIrisAccent)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleLive,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: _liveOn ? const LinearGradient(colors: [Color(0xFFFF5C7A), Color(0xFFFF9F4A)]) : null,
                      color: _liveOn ? null : _card,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: _liveOn ? Colors.transparent : kIrisAccent.withOpacity(.6)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_liveOn ? Icons.stop_rounded : Icons.graphic_eq, color: _liveOn ? Colors.white : kIrisAccent, size: 22),
                      const SizedBox(width: 6),
                      Text(_liveOn ? 'إنهاء' : 'Live', style: TextStyle(color: _liveOn ? Colors.white : kIrisAccent, fontWeight: FontWeight.w900, fontSize: 15)),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ريلز فيديو: ٣ صفوف مدمجة بأيقونات متحركة
class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});
  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  @override
  void dispose() {
    _enter.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20)),
                const SizedBox(width: 10),
                const Expanded(child: Text('ريلز فيديو', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))),
                const IrisLogo(size: 32),
              ]),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([_enter, _loop]),
                builder: (_, __) => ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                  for (var i = 0; i < 3; i++) GestureDetector(onTap: () => _soon(context, 'توليد الفيديو'), child: reelCard(i, _enter.value, _loop.value)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ريلز إعلاني (مدفوع): واجهة فقط
class PromoPage extends StatefulWidget {
  final String country;
  const PromoPage({super.key, required this.country});
  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  int _mode = 0;
  int _images = 0;
  int _idx = 2;
  final _txt = TextEditingController();
  static const _secs = [5, 10, 15, 20, 25, 30];
  late final FixedExtentScrollController _wheel = FixedExtentScrollController(initialItem: 2);

  @override
  void dispose() {
    _txt.dispose();
    _wheel.dispose();
    super.dispose();
  }

  Widget _seg(String t, int m) {
    final sel = _mode == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: sel ? kIrisAccent.withOpacity(.22) : _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? kIrisAccent : Colors.white12, width: sel ? 1.8 : 1)),
          child: Text(t, style: TextStyle(color: Colors.white, fontWeight: sel ? FontWeight.w800 : FontWeight.w500, fontSize: 13.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = _mode == 1;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: ListView(children: [
              Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20)),
                const SizedBox(width: 10),
                const Text('ريلز إعلاني', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: _gold.withOpacity(.16), border: Border.all(color: _gold), borderRadius: BorderRadius.circular(10)), child: const Text('مدفوع', style: TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w800))),
                const Spacer(),
                const IrisLogo(size: 32),
              ]),
              const SizedBox(height: 16),
              Row(children: [_seg('أكتب السكريبت بنفسي', 0), const SizedBox(width: 10), _seg('آيرس يكتبه من المنتج', 1)]),
              const SizedBox(height: 14),
              Text(ai ? 'اسم المنتج ووصفه' : 'السكريبت', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: kIrisAccent.withOpacity(.5))),
                child: TextField(
                  controller: _txt,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.6),
                  decoration: InputDecoration(border: InputBorder.none, hintText: ai ? 'مثال: عسل سدر طبيعي، عبوة ٥٠٠ جم' : 'اكتب كلام الإعلان هنا...', hintStyle: const TextStyle(color: Colors.white38)),
                ),
              ),
              if (ai) const Padding(padding: EdgeInsets.only(top: 8), child: Text('آيرس هيكتب السكريبت ويعرضه عليك قبل التوليد', style: TextStyle(color: Colors.white54, fontSize: 12))),
              const SizedBox(height: 10),
              Row(children: [
                GestureDetector(
                  onTap: () => setState(() => _images = (_images + 1).clamp(0, 4)),
                  child: Container(
                    height: 54, padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: kIrisAccent.withOpacity(.6))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 32, height: 32, decoration: BoxDecoration(color: kIrisAccent.withOpacity(.2), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.add_photo_alternate_outlined, color: kIrisAccent, size: 20)),
                      const SizedBox(width: 10),
                      Text(ai ? 'أضف صورة المنتج' : 'أضف صورة', style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                for (var i = 0; i < _images; i++)
                  GestureDetector(
                    onTap: () => setState(() => _images--),
                    child: Container(width: 54, height: 54, margin: const EdgeInsetsDirectional.only(end: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [i.isEven ? const Color(0xFFE08E45) : const Color(0xFF6FB1E4), Colors.black26]), border: Border.all(color: Colors.white24)), child: const Align(alignment: Alignment.topLeft, child: Padding(padding: EdgeInsets.all(3), child: Icon(Icons.cancel, color: Colors.white70, size: 15)))),
                  ),
              ]),
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('رفع الصور شكل فقط حالياً (مفيش اختيار صورة حقيقي)', style: TextStyle(color: Colors.white30, fontSize: 11))),
              const SizedBox(height: 10),
              const Text('مدة الفيديو', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                height: 132,
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
                child: Stack(alignment: Alignment.center, children: [
                  Container(height: 40, margin: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: kIrisAccent.withOpacity(.16), borderRadius: BorderRadius.circular(12), border: Border.all(color: kIrisAccent.withOpacity(.6)))),
                  ListWheelScrollView.useDelegate(
                    controller: _wheel,
                    itemExtent: 40,
                    diameterRatio: 1.5,
                    perspective: .004,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => setState(() => _idx = i),
                    childDelegate: ListWheelChildListDelegate(children: [
                      for (var i = 0; i < _secs.length; i++)
                        Center(child: Text('${_secs[i]} ثانية', style: TextStyle(color: i == _idx ? Colors.white : Colors.white38, fontSize: i == _idx ? 22 : 17, fontWeight: i == _idx ? FontWeight.w800 : FontWeight.w500))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PayPage(country: widget.country))),
                child: Container(
                  height: 50, alignment: Alignment.center,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), border: Border.all(color: _gold, width: 1.5), color: _gold.withOpacity(.12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.lock_outline, color: _gold, size: 18), SizedBox(width: 8), Text('ادفع لصناعة الاعلان الخاص بك', style: TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 14.5))]),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('الإعلان بيتصنع بعد الدفع بس', style: TextStyle(color: Colors.white30, fontSize: 11))),
            ]),
          ),
        ),
      ),
    );
  }
}

// الدفع: طرق الدفع حسب الدولة. واجهة فقط، مفيش دفع حقيقي
class PayPage extends StatefulWidget {
  final String country;
  const PayPage({super.key, required this.country});
  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  int _step = 0;
  @override
  Widget build(BuildContext context) {
    return PayFrame(
      step: _step,
      egypt: widget.country == 'EG',
      onBack: () => _step == 0 ? Navigator.pop(context) : setState(() => _step--),
      onNext: () {
        if (_step < 2) {
          setState(() => _step++);
        } else {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
    );
  }
}

// الساعة الذكية: واجهة فقط، بيانات تجريبية
class WatchFlowPage extends StatefulWidget {
  const WatchFlowPage({super.key});
  @override
  State<WatchFlowPage> createState() => _WatchFlowPageState();
}

class _WatchFlowPageState extends State<WatchFlowPage> {
  int _step = 0;
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(children: [
          Expanded(child: PhoneWatchPreview(step: _step)),
          Container(
            color: const Color(0xFF0B1118),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('عرض تجريبي: الأرقام شكل فقط، مفيش قراءة حقيقية من الساعة', style: TextStyle(color: _gold, fontSize: 11.5)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => _step == 0 ? Navigator.pop(context) : setState(() => _step--), child: Text(_step == 0 ? 'رجوع' : 'السابق'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(onPressed: _step < 4 ? () => setState(() => _step++) : () => Navigator.pop(context), child: Text(_step < 4 ? 'التالي' : 'تم'))),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
