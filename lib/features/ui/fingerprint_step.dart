import 'dart:math';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart'
    show kIrisAccent, RetinaNetwork, IrisLogo, CurvedHeaderPainter;

// خطوة تسجيل البصمة (V3.4): بعد تسجيل الدخول (إيميل/باسورد أو جوجل/مايكروسوفت/أبل/جيت هاب)
// وقبل الصفحة اللي بعدها. المستخدم يلمس البصمة، لو اتأكدت الأيقونة تنور أخضر
// ويظهر "خصوصيتك الآن محمية" وزرار دخول.
// ملاحظة: أندرويد مش بيسمح لأي تطبيق يسجّل بصمة جديدة بنفسه؛ التطبيق بيتحقق من بصمة
// مسجلة في إعدادات الجهاز (local_auth) ويفعّل استخدامها جوه آيرس.
class FingerprintStepPage extends StatefulWidget {
  final WidgetBuilder next;
  const FingerprintStepPage({super.key, required this.next});

  @override
  State<FingerprintStepPage> createState() => _FingerprintStepPageState();
}

class _FingerprintStepPageState extends State<FingerprintStepPage>
    with TickerProviderStateMixin {
  static const Color kOk = Color(0xFF2EE66B);
  static const String kPrefKey = 'fingerprint_enabled';

  final LocalAuthentication _bio = LocalAuthentication();
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();
  late final AnimationController _ok = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  bool _busy = false;
  bool _done = false;
  String? _msg;
  bool _canSkip = false;

  @override
  void dispose() {
    _pulse.dispose();
    _ok.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy || _done) return;
    setState(() {
      _busy = true;
      _msg = null;
    });
    bool ok = false;
    try {
      final can = await _bio.canCheckBiometrics;
      if (!can) {
        // الجهاز مفيهوش حساس/بصمة مسجلة: نسيب المستخدم يتخطى
        if (mounted) {
          setState(() {
            _msg =
                'مفيش بصمة مسجلة على الجهاز. سجّلها من إعدادات الموبايل وجرّب تاني';
            _canSkip = true;
          });
        }
      } else {
        ok = await _bio.authenticate(
          localizedReason: 'سجّل بصمة صباعك لحماية حسابك في I.R.I.S',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (!ok && mounted) {
          setState(() {
            _msg = 'البصمة ماتأكدتش، جرّب تاني';
            _canSkip = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _msg = 'مقدرناش نقرا البصمة، جرّب تاني';
          _canSkip = true;
        });
      }
    }
    if (!mounted) return;
    if (ok) {
      try {
        final p = await SharedPreferences.getInstance();
        await p.setBool(kPrefKey, true);
      } catch (_) {}
      setState(() => _done = true);
      _ok.forward();
    }
    if (mounted) setState(() => _busy = false);
  }

  void _enter() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (ctx, __, ___) => widget.next(ctx),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ));
  }

  Widget _scanIcon(double d) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _ok]),
      builder: (context, _) {
        final okP = Curves.easeOut.transform(_ok.value);
        final col = Color.lerp(kIrisAccent, kOk, okP)!;
        final pulse = 0.5 + 0.5 * sin(_pulse.value * 2 * pi);
        return GestureDetector(
          onTap: _register,
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(d * 0.2),
              border: Border.all(color: col.withOpacity(0.9), width: 2.5),
              color: col.withOpacity(0.06),
              boxShadow: [
                BoxShadow(
                    color: col.withOpacity(_done ? 0.45 : 0.12 + 0.12 * pulse),
                    blurRadius: _done ? 40 : 24),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.fingerprint, size: d * 0.62, color: col),
                if (_busy && !_done)
                  Positioned(
                    top: d * 0.12 + (d * 0.76) * pulse,
                    left: d * 0.12,
                    right: d * 0.12,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(color: col, boxShadow: [
                        BoxShadow(color: col, blurRadius: 8),
                      ]),
                    ),
                  ),
                if (_done)
                  Positioned(
                    right: d * 0.08,
                    bottom: d * 0.08,
                    child: Transform.scale(
                      scale: okP,
                      child: Container(
                        width: d * 0.26,
                        height: d * 0.26,
                        decoration: const BoxDecoration(
                            color: kOk, shape: BoxShape.circle),
                        child: Icon(Icons.check,
                            color: Colors.black, size: d * 0.18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content(double k) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _scanIcon(150 * k),
        SizedBox(height: 22 * k),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _done
              ? Text('خصوصيتك الآن محمية',
                  key: const ValueKey('ok'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: kOk,
                      fontSize: 21 * k,
                      fontWeight: FontWeight.w800,
                      shadows: const [Shadow(color: kOk, blurRadius: 16)]))
              : Text('المس البصمة عشان تضيفها · اختياري',
                  key: const ValueKey('hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 14.5 * k)),
        ),
        if (_msg != null && !_done) ...[
          SizedBox(height: 10 * k),
          Text(_msg!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent, fontSize: 12.5 * k)),
        ],
        SizedBox(height: 26 * k),
        SizedBox(
          width: double.infinity,
          height: 52 * k,
          child: ElevatedButton(
            onPressed: _done ? _enter : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kOk,
              disabledBackgroundColor: kIrisAccent.withOpacity(0.18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26 * k)),
            ),
            child: Text('ادخل  ·  Enter',
                style: TextStyle(
                    color: _done ? Colors.black : Colors.white38,
                    fontSize: 17 * k,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        if (!_done)
          TextButton(
            onPressed: _enter,
            child: Text('مش دلوقتي · تخطي',
                style: TextStyle(color: kIrisAccent, fontSize: 13.5 * k)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 700;
          const title = 'ضيف بصمتك عشان تحمي خصوصيتك';
          if (wide) {
            final k = (c.maxWidth / 1000).clamp(1.0, 1.6).toDouble();
            return Stack(fit: StackFit.expand, children: [
              RetinaNetwork(
                  animation: _pulse,
                  origin: const Offset(0.5, 0.5),
                  spread: pi),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 460 * k),
                  child: Container(
                    padding: EdgeInsets.all(28 * k),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05080C).withOpacity(0.78),
                      borderRadius: BorderRadius.circular(26 * k),
                      border: Border.all(color: kIrisAccent.withOpacity(0.22)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IrisLogo(size: 84 * k),
                        SizedBox(height: 16 * k),
                        Text(title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20 * k,
                                fontWeight: FontWeight.w800,
                                height: 1.4)),
                        SizedBox(height: 22 * k),
                        _content(k),
                      ],
                    ),
                  ),
                ),
              ),
            ]);
          }
          final headerH = (c.maxHeight * 0.36).clamp(240.0, 380.0);
          return Stack(fit: StackFit.expand, children: [
            RetinaNetwork(animation: _pulse),
            Positioned.fill(
              top: headerH - 4,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 24, 26, 18),
                  child: _content(1.0),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerH,
              child: CustomPaint(
                painter: const CurvedHeaderPainter(),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 30),
                    child: Column(
                      children: [
                        IrisLogo(size: 92),
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28),
                          child: Text(title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}
