import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login_page.dart' show kIrisAccent, IrisLogo;
import 'menu_preview.dart' show MenuList;
import 'batch3_preview.dart' show reelCard;
import 'batch3b_preview.dart' show PayFrame;
import 'flows_preview.dart' show PhoneWatchPreview;
import 'live_view.dart';

const Color _bg = Color(0xFF05080C);
const Color _card = Color(0xFF111A24);
const Color _gold = Color(0xFFFFC857);
const Color _live = Color(0xFFFF5C7A);

const String kTestReply =
    'يا هلا يا محمود! التيست اشتغل تمام وأنا جنبك. جاهز أساعدك في الكتابة والصور والفيديوهات والمذاكرة ومراجعة مشاريعك. قولي نبدأ بإيه؟';

const String kVoiceDemoText =
    'اهلا يا آيرس، عايز أعرف أخبار الذكاء الاصطناعي النهاردة.';

const String kVoiceReply =
    'وصلتني رسالتك الصوتية. فهم الصوت الحقيقي لسه مش شغال في النسخة دي، هيشتغل لما نوصل السيرفر.';
const String kNoTranscript =
    'التفريغ النصي لسه مش متاح، محتاج خدمة تفريغ صوت على السيرفر.';
const String kThreadKey = 'iris_thread_v1';
// للاختبار بس: بيخلي التسجيل وهمي من غير مايك
bool kFakeRecordingForTests = false;

const String kWebReply =
    'خلصت يا محمود! جمعتلك الخلاصة بشكل بسيط. (ده عرض تجريبي للشكل بس، مفيش بحث حقيقي لسه)';

void _soon(BuildContext c, String what) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text('$what: قريباً (واجهة فقط في النسخة دي)',
        textDirection: TextDirection.rtl),
    duration: const Duration(seconds: 2),
  ));
}

class _Msg {
  final String text;
  final bool me;
  final int? voiceSec; // لو رسالة صوتية
  final String? path; // ملف التسجيل على التليفون
  bool showText = false; // نص الرسالة الصوتية ظاهر تحتها (CC)
  int status; // ٠ اتبعتت ✓ · ١ وصلت ✓✓ · ٢ اتقرت ✓✓ (أزرق)
  _Msg(this.text, this.me, {this.voiceSec, this.path, this.status = 0});
  Map<String, dynamic> toJson() =>
      {'t': text, 'me': me, 'v': voiceSec, 'p': path};
  static _Msg fromJson(Map<String, dynamic> j) =>
      _Msg(j['t'] as String? ?? '', j['me'] as bool? ?? false,
          voiceSec: j['v'] as int?, path: j['p'] as String?, status: 2);
}

enum IrisMode { auto, flashLite, flash, proLite }

const _modeInfo = <IrisMode, List<String>>{
  IrisMode.auto: ['Auto', 'تلقائي حسب نوع السؤال'],
  IrisMode.flashLite: ['Flash Lite', 'أسرع رد، للأسئلة الخفيفة'],
  IrisMode.flash: ['Flash', 'متوازن بين السرعة والجودة'],
  IrisMode.proLite: ['Pro Lite', 'أعمق تفكير، للأسئلة الصعبة'],
};

const List<String> kWebSteps = [
  'أنا بدوّر في موقع Wikipedia دلوقتي...',
  'أنا بدوّر في موقع BBC عربي دلوقتي...',
  'بقرا من موقع Reuters...',
  'بجمّع اللي لقيته وبرتّبه ليك...',
];

// شعاع ليزر بيمسح السطر القديم ويكتب الجديد في نفس المكان (واجهة فقط)
class LaserSwapLine extends StatefulWidget {
  final List<String> lines;
  final Duration step;
  final double? freezeAt; // للصور الثابتة: نقطة زمنية بالثواني
  const LaserSwapLine(
      {super.key,
      required this.lines,
      this.step = const Duration(milliseconds: 1900),
      this.freezeAt});
  @override
  State<LaserSwapLine> createState() => _LaserSwapLineState();
}

class _LaserSwapLineState extends State<LaserSwapLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: widget.step * widget.lines.length);

  @override
  void initState() {
    super.initState();
    if (widget.freezeAt != null) {
      _c.value = (widget.freezeAt! * 1000 / _c.duration!.inMilliseconds)
          .clamp(0.0, 1.0);
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final n = widget.lines.length;
        final pos = (_c.value * n).clamp(0.0, n - 0.0001);
        final i = pos.floor();
        final f = pos - i;
        // أول ٣٠٪ كتابة، ٥٠٪ ثابت، آخر ٢٠٪ مسح (إلا السطر الأخير يفضل)
        final last = i == n - 1;
        double from = 0, to = 1; // نطاق الظهور
        bool writing = false, erasing = false;
        if (f < 0.3) {
          writing = true;
          to = f / 0.3;
        } else if (f > 0.8 && !last) {
          erasing = true;
          from = (f - 0.8) / 0.2;
        }
        return SizedBox(
          height: 22,
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final tp = TextPainter(
                text: TextSpan(
                    text: widget.lines[i],
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
                textDirection: TextDirection.rtl)
              ..layout();
            final tw = math.min(tp.width + 4, w);
            // RTL: الشعاع بيمشي من اليمين للشمال على عرض النص نفسه
            final laserX =
                writing ? w - tw * to : (erasing ? w - tw * from : -10.0);
            return Stack(children: [
              ClipRect(
                clipper: _SpanClipper(
                    writing ? w - tw * to : 0.0, erasing ? w - tw * from : w),
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(widget.lines[i],
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600))),
              ),
              if (writing || erasing)
                Positioned(
                  left: laserX - 1,
                  top: 2,
                  bottom: 2,
                  child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FB),
                          boxShadow: [
                            BoxShadow(
                                color: kIrisAccent.withOpacity(.9),
                                blurRadius: 10,
                                spreadRadius: 1)
                          ])),
                ),
            ]);
          }),
        );
      },
    );
  }
}

class _SpanClipper extends CustomClipper<Rect> {
  final double a, b; // إحداثيات بالبكسل
  _SpanClipper(this.a, this.b);
  @override
  Rect getClip(Size s) => Rect.fromLTRB(a, 0, b, s.height);
  @override
  bool shouldReclip(_SpanClipper o) => o.a != a || o.b != b;
}

// علامات الرسالة زي واتساب
class Ticks extends StatelessWidget {
  final int status;
  const Ticks(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final col = status >= 2 ? const Color(0xFF53BDEB) : Colors.white54;
    return Icon(status == 0 ? Icons.check : Icons.done_all,
        size: 16, color: col);
  }
}

// مؤشر "بفكر": لوجو صغير بيلف مع نقط
class ThinkingChip extends StatelessWidget {
  final Animation<double> anim;
  final Widget? below;
  const ThinkingChip({super.key, required this.anim, this.below});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Transform.rotate(
              angle: anim.value * 2 * math.pi, child: const IrisLogo(size: 22)),
          const SizedBox(width: 9),
          for (var i = 0; i < 3; i++)
            Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kIrisAccent.withOpacity(.25 +
                        .75 *
                            (0.5 +
                                0.5 *
                                    math.sin(anim.value * 2 * math.pi * 2 -
                                        i * 1.0))))),
          const SizedBox(width: 6),
          const Text('بفكر',
              style: TextStyle(color: Colors.white54, fontSize: 12.5)),
        ]),
      ),
    );
  }
}

// الشاشة الرئيسية: شات + قائمة جانبية + زر Live
class IrisHome extends StatefulWidget {
  final String? gender;
  final String? language;
  final String? country;
  final String? name;
  const IrisHome(
      {super.key, this.gender, this.language, this.country, this.name});
  @override
  State<IrisHome> createState() => _IrisHomeState();
}

class _IrisHomeState extends State<IrisHome> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  String _phase = ''; // '' | thinking | web
  bool _liveOn = false;
  int _liveSec = 0;
  Timer? _liveTimer;
  bool _rec = false;
  int _recSec = 0;
  Timer? _recTimer;
  IrisMode _mode = IrisMode.auto;
  bool _menuOpen = false;
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController _menuC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 280));
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 28))
        ..repeat();
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..forward();
  late final AnimationController _think = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();
  late final AnimationController _wave = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _recorder = AudioRecorder();
  AudioPlayer? _player;
  _Msg? _playing;
  final FlutterTts _tts = FlutterTts();
  _Msg? _speaking;
  String _gender = 'male';
  bool _ttsReady = false;
  String? _recPath;

  @override
  void initState() {
    super.initState();
    _loadThread();
    _initTts();
  }

  // صوت آيرس: على التليفون نفسه (من غير إنترنت ومن غير حجم زيادة). الذكر/الأنثى حسب اختيار الدخول
  Future<void> _initTts() async {
    try {
      final sp = await SharedPreferences.getInstance();
      if (widget.gender != null) {
        await sp.setString('iris_gender', widget.gender!);
      }
      _gender = widget.gender ?? sp.getString('iris_gender') ?? 'male';
      await _tts.awaitSpeakCompletion(true);
      var ok = false;
      for (final l in ['ar-EG', 'ar-SA', 'ar']) {
        final r = await _tts.isLanguageAvailable(l);
        if (r == true || r == 1) {
          await _tts.setLanguage(l);
          ok = true;
          break;
        }
      }
      try {
        final vs = (await _tts.getVoices as List?) ?? [];
        final ar = vs
            .where((v) => '${v['locale']}'.toLowerCase().startsWith('ar'))
            .map((v) => Map<String, String>.from(v as Map))
            .toList()
          ..sort((a, b) => a['name']!.compareTo(b['name']!));
        Map<String, String>? pick;
        final want = _gender == 'female' ? 'female' : 'male';
        for (final v in ar) {
          final n = v['name']!.toLowerCase();
          if (n.contains(want) && !(want == 'male' && n.contains('female')))
            pick = v;
        }
        if (pick == null && ar.length > 1)
          pick = _gender == 'female' ? ar[1] : ar[0];
        if (pick != null) await _tts.setVoice(pick);
      } catch (_) {}
      await _tts.setPitch(_gender == 'female' ? 1.15 : 0.8);
      await _tts.setSpeechRate(0.45);
      _ttsReady = ok;
    } catch (_) {}
  }

  Future<void> _speak(_Msg m) async {
    try {
      if (_speaking == m) {
        await _tts.stop();
        if (mounted) setState(() => _speaking = null);
        return;
      }
      await _tts.stop();
      setState(() => _speaking = m);
      await _tts.speak(m.text);
      if (mounted && _speaking == m) setState(() => _speaking = null);
    } catch (_) {
      if (mounted) {
        setState(() => _speaking = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('الصوت مش متاح على الموبايل ده',
                textDirection: TextDirection.rtl)));
      }
    }
  }

  // محادثة واحدة مستمرة: بتتحفظ على التليفون وبترجع كل مرة تفتح التطبيق
  Future<void> _loadThread() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(kThreadKey);
      if (raw == null || !mounted) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => _Msg.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      setState(() => _msgs.insertAll(0, list));
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scroll.hasClients)
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    } catch (_) {}
  }

  Future<void> _saveThread() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
          kThreadKey, jsonEncode(_msgs.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _togglePlay(_Msg m) async {
    if (m.path == null) return;
    try {
      _player ??= AudioPlayer();
      if (_playing == m) {
        await _player!.stop();
        setState(() => _playing = null);
        return;
      }
      await _player!.stop();
      setState(() => _playing = m);
      _player!.onPlayerComplete.first.then((_) {
        if (mounted && _playing == m) setState(() => _playing = null);
      });
      await _player!.play(DeviceFileSource(m.path!));
    } catch (_) {
      if (mounted) setState(() => _playing = null);
    }
  }

  String get _country {
    if (widget.country != null) return widget.country!;
    return WidgetsBinding.instance.platformDispatcher.locale.countryCode ?? '';
  }

  String get _name => widget.name ?? 'محمود';

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _pulse.dispose();
    _menuC.dispose();
    _spin.dispose();
    _enter.dispose();
    _think.dispose();
    _wave.dispose();
    _liveTimer?.cancel();
    _recTimer?.cancel();
    _tts.stop();
    _player?.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
    _menuOpen ? _menuC.forward() : _menuC.reverse();
  }

  bool _isWebQ(String t) =>
      RegExp(r'ابحث|دور|اخبار|أخبار|سعر|الطقس|search|news',
              caseSensitive: false)
          .hasMatch(t);

  Future<void> _deliver(_Msg m, {bool web = false}) async {
    setState(() => _msgs.add(m));
    _saveThread();
    _toBottom();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => m.status = 1);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      m.status = 2;
      _phase = web ? 'web' : 'thinking';
    });
    _toBottom();
    await Future.delayed(web
        ? Duration(milliseconds: 1900 * kWebSteps.length + 400)
        : const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _phase = '';
      _msgs.add(_Msg(
          m.voiceSec != null ? kVoiceReply : (web ? kWebReply : kTestReply),
          false));
    });
    _saveThread();
    _toBottom();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    _deliver(_Msg(t, true), web: _isWebQ(t));
  }

  Future<void> _startRec() async {
    String? path;
    if (!kFakeRecordingForTests) {
      try {
        if (!await _recorder.hasPermission()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'محتاج إذن المايك عشان أسجل. فعّله من إعدادات التطبيق',
                    textDirection: TextDirection.rtl)));
          }
          return;
        }
        final dir = await getApplicationDocumentsDirectory();
        path =
            '${dir.path}/iris_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('مقدرتش أشغل المايك',
                  textDirection: TextDirection.rtl)));
        }
        return;
      }
    }
    _recPath = path;
    setState(() {
      _rec = true;
      _recSec = 0;
    });
    _recTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() => _recSec++));
  }

  Future<void> _stopRec({required bool send}) async {
    _recTimer?.cancel();
    final s = math.max(_recSec, 1);
    setState(() => _rec = false);
    String? path = _recPath;
    if (!kFakeRecordingForTests) {
      try {
        path = await _recorder.stop() ?? path;
      } catch (_) {}
    }
    if (!send) {
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      return;
    }
    _deliver(_Msg('', true, voiceSec: s, path: path));
  }

  void _toBottom() => Future.delayed(const Duration(milliseconds: 80), () {
        if (_scroll.hasClients &&
            _scroll.position.maxScrollExtent > _scroll.offset + 1)
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
      });

  void _toggleLive() {
    if (_liveOn) {
      _liveTimer?.cancel();
      _pulse.stop();
      final d = _liveSec;
      setState(() {
        _liveOn = false;
        _msgs.add(_Msg(
            'انتهت المحادثة المباشرة · ${d ~/ 60}:${(d % 60).toString().padLeft(2, '0')}',
            false));
      });
      _toBottom();
    } else {
      setState(() {
        _liveOn = true;
        _liveSec = 0;
      });
      _pulse.repeat();
      _liveTimer = Timer.periodic(
          const Duration(seconds: 1), (_) => setState(() => _liveSec++));
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

  Widget _voiceBars(int sec,
          {Color? col, bool playing = false, VoidCallback? onPlay}) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPlay,
            child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: col ?? Colors.white,
                size: 26)),
        for (var i = 0; i < 16; i++)
          Container(
              width: 3,
              height: 5 + 12 * (0.5 + 0.5 * math.sin(i * 1.3 + sec)).abs(),
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              decoration: BoxDecoration(
                  color: (col ?? Colors.white).withOpacity(.75),
                  borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text('${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]);

  Widget _bubble(_Msg m) {
    if (m.voiceSec != null) return _voiceBubble(m);
    final bub = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
          color: m.me ? kIrisAccent.withOpacity(.22) : _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: m.me ? kIrisAccent.withOpacity(.5) : Colors.white12)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.6)),
            if (m.me)
              Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Ticks(m.status)),
          ]),
    );
    if (m.me) return Align(alignment: Alignment.centerRight, child: bub);
    // رد آيرس: أيقونة سماعة جنب الفقاعة في الناحية الفاضية، بتقرا الرد بصوت عالي
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            Flexible(child: bub),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _speak(m),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _speaking == m
                        ? kIrisAccent.withOpacity(.18)
                        : Colors.transparent,
                    border: Border.all(
                        color: _speaking == m ? kIrisAccent : Colors.white38,
                        width: 1.2)),
                child: Icon(
                    _speaking == m
                        ? Icons.stop_rounded
                        : Icons.volume_up_rounded,
                    size: 16,
                    color: _speaking == m ? kIrisAccent : Colors.white60),
              ),
            ),
          ]),
    );
  }

  // رسالة صوتية: فقاعة صغيرة، وزرار CC جنبها في الناحية الفاضية، والنص بيظهر تحتها
  Widget _voiceBubble(_Msg m) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(
                  onTap: () => setState(() => m.showText = !m.showText),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: m.showText
                            ? kIrisAccent.withOpacity(.18)
                            : Colors.transparent,
                        border: Border.all(
                            color: m.showText ? kIrisAccent : Colors.white38,
                            width: 1.2)),
                    child: Text('CC',
                        style: TextStyle(
                            color: m.showText ? kIrisAccent : Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            height: 1.1)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 5, 12, 4),
                  decoration: BoxDecoration(
                      color: kIrisAccent.withOpacity(.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kIrisAccent.withOpacity(.5))),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _voiceBars(m.voiceSec!,
                            playing: _playing == m,
                            onPlay: () => _togglePlay(m)),
                        Ticks(m.status),
                      ]),
                ),
              ]),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topRight,
                child: m.showText
                    ? Container(
                        margin: const EdgeInsets.only(top: 6),
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12)),
                        child: const Text(kNoTranscript,
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                height: 1.5)),
                      )
                    : const SizedBox.shrink(),
              ),
            ]),
      ),
    );
  }

  Widget _liveBody() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final t = _pulse.value;
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 190 + 14 * math.sin(t * 2 * math.pi),
            height: 190 + 14 * math.sin(t * 2 * math.pi),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  kIrisAccent.withOpacity(.35),
                  kIrisAccent.withOpacity(.05),
                  Colors.transparent
                ]),
                border: Border.all(color: kIrisAccent.withOpacity(.25))),
            child: Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _card,
                    border: Border.all(color: kIrisAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: kIrisAccent.withOpacity(.5), blurRadius: 30)
                    ]),
                child: const IrisLogo(size: 72)),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 80,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < 14; i++)
                    Container(
                        width: 6,
                        height: 14 +
                            52 *
                                (0.5 + 0.5 * math.sin(t * 2 * math.pi + i * .8))
                                    .abs(),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                            color: Color.lerp(
                                kIrisAccent, const Color(0xFFB57BEE), i / 14),
                            borderRadius: BorderRadius.circular(3))),
                ]),
          ),
          const SizedBox(height: 18),
          Text('بسمعك يا $_name...',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('الوضع المباشر شكل فقط حالياً، السيرفر لسه متوصلش',
              style: TextStyle(color: Colors.white54, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(
              '${_liveSec ~/ 60}:${(_liveSec % 60).toString().padLeft(2, '0')}',
              style:
                  const TextStyle(color: _live, fontWeight: FontWeight.w800)),
        ]);
      },
    );
  }

  // اللوجو في نص الشات: باهت جداً قبل أول رسالة وبيلف في الخلفية؛
  // أول ما التطبيق يفتح بيلف بسرعة وبيكبر شوية وبعدين يهدى
  Widget _bgLogo(bool dim) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_spin, _enter]),
          builder: (_, __) {
            final e = Curves.easeOutCubic.transform(_enter.value);
            final angle = 2 * math.pi * (_spin.value + 1.4 * (1 - e));
            final scale = 0.8 + 0.25 * e;
            return Opacity(
              opacity: (dim ? 0.13 : 0.06) + 0.0 * e,
              child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                      angle: angle, child: const IrisLogo(size: 230))),
            );
          },
        ),
      ),
    );
  }

  Widget _modeButton() {
    return GestureDetector(
      onTap: _toggleMenu,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kIrisAccent.withOpacity(.45))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('التخصيص',
              style: TextStyle(color: Colors.white54, fontSize: 11.5)),
          const SizedBox(width: 7),
          Text(_modeInfo[_mode]![0],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          AnimatedBuilder(
            animation: _menuC,
            builder: (_, __) => Transform.rotate(
                angle: math.pi * Curves.easeInOutCubic.transform(_menuC.value),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: kIrisAccent, size: 20)),
          ),
        ]),
      ),
    );
  }

  Widget _modeMenu() {
    return AnimatedBuilder(
      animation: _menuC,
      builder: (_, __) {
        final t = Curves.easeOutCubic.transform(_menuC.value);
        if (_menuC.value == 0) return const SizedBox.shrink();
        return Positioned(
          top: 56,
          left: 14,
          child: Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, -10 * (1 - t)),
              child: Transform.scale(
                scale: 0.94 + 0.06 * t,
                alignment: Alignment.topLeft,
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0E151D),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kIrisAccent.withOpacity(.35)),
                      boxShadow: [
                        BoxShadow(
                            color: kIrisAccent.withOpacity(.14 * t),
                            blurRadius: 28)
                      ]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < IrisMode.values.length; i++)
                      Opacity(
                        opacity: Interval(0.1 + i * 0.12, 0.6 + i * 0.12,
                                curve: Curves.easeOut)
                            .transform(_menuC.value),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() => _mode = IrisMode.values[i]);
                            _toggleMenu();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                                color: _mode == IrisMode.values[i]
                                    ? kIrisAccent.withOpacity(.14)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_modeInfo[IrisMode.values[i]]![0],
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(_modeInfo[IrisMode.values[i]]![1],
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11.5)),
                                    ]),
                              ),
                              if (_mode == IrisMode.values[i])
                                const Icon(Icons.check_rounded,
                                    color: kIrisAccent, size: 20),
                            ]),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _inputRow() {
    if (_rec) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: Row(children: [
          GestureDetector(
              onTap: () => _stopRec(send: false),
              child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: _card,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24)),
                  child:
                      const Icon(Icons.delete_outline, color: Colors.white70))),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: _live.withOpacity(.6))),
              child: AnimatedBuilder(
                animation: _wave,
                builder: (_, __) => Row(children: [
                  Icon(Icons.circle,
                      color: _live.withOpacity(.4 +
                          .6 *
                              (0.5 +
                                  0.5 * math.sin(_wave.value * 2 * math.pi))),
                      size: 11),
                  const SizedBox(width: 8),
                  Text(
                      '${_recSec ~/ 60}:${(_recSec % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var i = 0; i < 26; i++)
                            Container(
                                width: 3,
                                height: 6 +
                                    20 *
                                        (0.5 +
                                                0.5 *
                                                    math.sin(_wave.value *
                                                            2 *
                                                            math.pi +
                                                        i * .7))
                                            .abs(),
                                decoration: BoxDecoration(
                                    color: kIrisAccent,
                                    borderRadius: BorderRadius.circular(2))),
                        ]),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: () => _stopRec(send: true),
              child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                      color: kIrisAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_upward, color: Colors.black))),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                    color: kIrisAccent.withOpacity(_liveOn ? .15 : .4))),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: !_liveOn,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          _liveOn ? 'الكتابة متوقفة وقت Live' : 'اكتب هنا...',
                      hintStyle: const TextStyle(color: Colors.white38)),
                  onSubmitted: (_) => _send(),
                ),
              ),
              GestureDetector(
                  onTap: _liveOn ? null : _send,
                  child: Icon(Icons.arrow_upward,
                      color: _liveOn ? Colors.white24 : kIrisAccent)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _liveOn ? null : _startRec,
          child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: _card,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: kIrisAccent.withOpacity(_liveOn ? .15 : .6))),
              child: Icon(Icons.mic_none_rounded,
                  color: _liveOn ? Colors.white24 : kIrisAccent, size: 24)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _toggleLive,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: _liveOn
                  ? const LinearGradient(
                      colors: [Color(0xFFFF5C7A), Color(0xFFFF9F4A)])
                  : null,
              color: _liveOn ? null : _card,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                  color: _liveOn
                      ? Colors.transparent
                      : kIrisAccent.withOpacity(.6)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_liveOn ? Icons.stop_rounded : Icons.graphic_eq,
                  color: _liveOn ? Colors.white : kIrisAccent, size: 22),
              const SizedBox(width: 6),
              Text(_liveOn ? 'إنهاء' : 'Live',
                  style: TextStyle(
                      color: _liveOn ? Colors.white : kIrisAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _greeting() => const SizedBox.expand();

  @override
  Widget build(BuildContext context) {
    final empty = _msgs.isEmpty && !_liveOn;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _bg,
        drawer: Drawer(
          backgroundColor: const Color(0xFF0B1118),
          width: 320,
          child: SafeArea(
              child: SingleChildScrollView(child: MenuList(onSelect: _onMenu))),
        ),
        body: SafeArea(
          child: Stack(children: [
            Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(children: [
                  GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const Icon(Icons.menu, color: Colors.white70)),
                  const SizedBox(width: 12),
                  const IrisLogo(size: 30),
                  const SizedBox(width: 7),
                  const Text('IRIS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3)),
                  const Spacer(),
                  if (_liveOn)
                    Row(children: const [
                      Icon(Icons.circle, color: _live, size: 10),
                      SizedBox(width: 5),
                      Text('مباشر',
                          style: TextStyle(
                              color: _live, fontWeight: FontWeight.w800))
                    ])
                  else
                    _modeButton(),
                ]),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: _liveOn
                    ? LiveView(onClose: _toggleLive, name: _name)
                    : Stack(children: [
                        _bgLogo(empty),
                        if (empty)
                          _greeting()
                        else
                          ListView(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            children: [
                              for (final m in _msgs) _bubble(m),
                              if (_phase == 'thinking')
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: ThinkingChip(anim: _think)),
                              if (_phase == 'web')
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 250,
                                    margin: const EdgeInsets.only(top: 6),
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 6, 10, 6),
                                    decoration: BoxDecoration(
                                        color: _card.withOpacity(.9),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color:
                                                kIrisAccent.withOpacity(.25))),
                                    child: Row(children: [
                                      AnimatedBuilder(
                                          animation: _think,
                                          builder: (_, __) => Transform.rotate(
                                              angle: _think.value * 2 * math.pi,
                                              child: const IrisLogo(size: 20))),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                          child:
                                              LaserSwapLine(lines: kWebSteps)),
                                    ]),
                                  ),
                                ),
                            ],
                          ),
                      ]),
              ),
              _inputRow(),
            ]),
            if (_menuOpen)
              Positioned.fill(
                  child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _toggleMenu)),
            _modeMenu(),
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
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward();
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();
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
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 20)),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('ريلز فيديو',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800))),
                const IrisLogo(size: 32),
              ]),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([_enter, _loop]),
                builder: (_, __) => ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      for (var i = 0; i < 3; i++)
                        GestureDetector(
                            onTap: () => _soon(context, 'توليد الفيديو'),
                            child: reelCard(i, _enter.value, _loop.value)),
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
  late final FixedExtentScrollController _wheel =
      FixedExtentScrollController(initialItem: 2);

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
          decoration: BoxDecoration(
              color: sel ? kIrisAccent.withOpacity(.22) : _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: sel ? kIrisAccent : Colors.white12,
                  width: sel ? 1.8 : 1)),
          child: Text(t,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 13.5)),
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
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 20)),
                const SizedBox(width: 10),
                const Text('ريلز إعلاني',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: _gold.withOpacity(.16),
                        border: Border.all(color: _gold),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('مدفوع',
                        style: TextStyle(
                            color: _gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w800))),
                const Spacer(),
                const IrisLogo(size: 32),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _seg('أكتب السكريبت بنفسي', 0),
                const SizedBox(width: 10),
                _seg('آيرس يكتبه من المنتج', 1)
              ]),
              const SizedBox(height: 14),
              Text(ai ? 'اسم المنتج ووصفه' : 'السكريبت',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kIrisAccent.withOpacity(.5))),
                child: TextField(
                  controller: _txt,
                  maxLines: 4,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14.5, height: 1.6),
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: ai
                          ? 'مثال: عسل سدر طبيعي، عبوة ٥٠٠ جم'
                          : 'اكتب كلام الإعلان هنا...',
                      hintStyle: const TextStyle(color: Colors.white38)),
                ),
              ),
              if (ai)
                const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('آيرس هيكتب السكريبت ويعرضه عليك قبل التوليد',
                        style: TextStyle(color: Colors.white54, fontSize: 12))),
              const SizedBox(height: 10),
              Row(children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _images = (_images + 1).clamp(0, 4)),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kIrisAccent.withOpacity(.6))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: kIrisAccent.withOpacity(.2),
                              borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.add_photo_alternate_outlined,
                              color: kIrisAccent, size: 20)),
                      const SizedBox(width: 10),
                      Text(ai ? 'أضف صورة المنتج' : 'أضف صورة',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                for (var i = 0; i < _images; i++)
                  GestureDetector(
                    onTap: () => setState(() => _images--),
                    child: Container(
                        width: 54,
                        height: 54,
                        margin: const EdgeInsetsDirectional.only(end: 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(colors: [
                              i.isEven
                                  ? const Color(0xFFE08E45)
                                  : const Color(0xFF6FB1E4),
                              Colors.black26
                            ]),
                            border: Border.all(color: Colors.white24)),
                        child: const Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(Icons.cancel,
                                    color: Colors.white70, size: 15)))),
                  ),
              ]),
              const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                      'رفع الصور شكل فقط حالياً (مفيش اختيار صورة حقيقي)',
                      style: TextStyle(color: Colors.white30, fontSize: 11))),
              const SizedBox(height: 10),
              const Text('مدة الفيديو',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                height: 132,
                decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12)),
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: kIrisAccent.withOpacity(.16),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: kIrisAccent.withOpacity(.6)))),
                  ListWheelScrollView.useDelegate(
                    controller: _wheel,
                    itemExtent: 40,
                    diameterRatio: 1.5,
                    perspective: .004,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => setState(() => _idx = i),
                    childDelegate: ListWheelChildListDelegate(children: [
                      for (var i = 0; i < _secs.length; i++)
                        Center(
                            child: Text('${_secs[i]} ثانية',
                                style: TextStyle(
                                    color: i == _idx
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: i == _idx ? 22 : 17,
                                    fontWeight: i == _idx
                                        ? FontWeight.w800
                                        : FontWeight.w500))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PayPage(country: widget.country))),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: _gold, width: 1.5),
                      color: _gold.withOpacity(.12)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lock_outline, color: _gold, size: 18),
                        SizedBox(width: 8),
                        Text('ادفع لصناعة الاعلان الخاص بك',
                            style: TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5))
                      ]),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                  child: Text('الإعلان بيتصنع بعد الدفع بس',
                      style: TextStyle(color: Colors.white30, fontSize: 11))),
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
      onBack: () =>
          _step == 0 ? Navigator.pop(context) : setState(() => _step--),
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
                const Text(
                    'عرض تجريبي: الأرقام شكل فقط، مفيش قراءة حقيقية من الساعة',
                    style: TextStyle(color: _gold, fontSize: 11.5)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => _step == 0
                              ? Navigator.pop(context)
                              : setState(() => _step--),
                          child: Text(_step == 0 ? 'رجوع' : 'السابق'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: _step < 4
                              ? () => setState(() => _step++)
                              : () => Navigator.pop(context),
                          child: Text(_step < 4 ? 'التالي' : 'تم'))),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
