import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fingerprint_step.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/services/auth_service.dart';
import 'onboarding_ui.dart';
import 'admin_ui.dart';

// شاشة تسجيل الدخول الجديدة - التصميم من فيديوهات محمود (٢٧ نوفمبر)
// موبايل: عمود واحد (Welcome back + إيميل وباسورد + مسح وجه + أزرار المواقع)
// لابتوب/PC وتلفزيون: خلفية مطر متحرك ملء الشاشة، فورم أبيض وأسود بحواف سفلية،
// زرار متوهج، واللوجو/الهولوغرام على الناحية التانية بدل رسمة الأنمي
// (الرسمة ما اتنسختش - حقوق نشر + محمود بيلتزم بأحكام تصوير ذوات الأرواح)
// الألوان: خلفية سوداء، والمميز أزرق سماوي فاتح جاي على رمادي
const Color kIrisAccent = Color(0xFF9DB9CE); // أزرق سماوي فاتح على رمادي
const Color kIrisAccentDeep = Color(0xFF6E8FA8);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _auth = AuthService();
  final LocalAuthentication _biometric = LocalAuthentication();

  bool _keepSignedIn = true;
  bool _obscure = true;
  bool _scanning = false;
  bool _busy = false;
  bool _showRegister = false;
  String? _error;

  late final AnimationController _scanController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  // متحكم المطر والتوهج في شاشة اللابتوب
  late final AnimationController _rainController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // متحكم دوران اللوجو والنبض في شاشة التلفزيون
  late final AnimationController _orbitController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  // متحكم مسحة التبديل القطرية بين البانيلات (مرجع: فيديو Login|Signup Animation)
  late final AnimationController _sweepController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  // الاسم المحفوظ من آخر دخول (بيتحفظ بعد التسجيل/الدخول). لو مفيش: "اهلا بيك"
  String? _savedName;
  bool _bgReady = false;
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final n = p.getString('iris_user_name');
      if (mounted && n != null && n.trim().isNotEmpty) {
        setState(() => _savedName = n.trim());
      }
    }).catchError((_) {});
    // نبدأ الشيمر بعد ما شاشة الدخول تظهر (مش في أول فريم) عشان أول فتح يبقى خفيف
    // أول فريم خفيف: الخلفية بتظهر بتدريج بعد أول رسمة، والحركات المستمرة بتبدأ بعدها
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _bgReady = true);
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _rainController.repeat();
      _orbitController.repeat();
      _shimmer.repeat();
    });
  }

  bool _panelsSwapped = false; // الفورم واللوجو بدّلوا أماكنهم؟
  bool _sweepBusy = false; // مسحة التبديل شغالة؟
  bool _scanDone = false; // المسح البيومتري نجح (الميش يخضر وعلامة الصح)

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _scanController.dispose();
    _rainController.dispose();
    _orbitController.dispose();
    _sweepController.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  bool _covering =
      false; // البانيل الأسود بيتمدد يغطي الشاشة قبل الخطوة التالية

  // رسائل الحقول الناقصة (تحت الحقل الفاضي)
  final Map<TextEditingController, String> _missing = {};

  bool _validate(Map<TextEditingController, String> required) {
    setState(() {
      _missing.clear();
      required.forEach((c, msg) {
        if (c.text.trim().isEmpty) _missing[c] = msg;
      });
      _error = _missing.isEmpty
          ? null
          : "You haven't finished signing in. Fill in the empty fields.";
    });
    return _missing.isEmpty;
  }

  // لو البيانات مش كاملة: مفيش تبديل بانيلات، بس رسالة تحت الحقل الفاضي
  void _trySignIn() {
    if (!_validate({
      _email: 'Email is not filled in',
      _password: 'Password is not filled in',
    })) return;
    if (MediaQuery.of(context).size.width >= 600) {
      _sweepSwap(after: _signInWithEmail);
    } else {
      _signInWithEmail();
    }
  }

  void _tryRegister() {
    if (!_validate({
      _regEmail: 'Email is not filled in',
      _regPassword: 'Password is not filled in',
    })) return;
    _sweepSwap(after: _register);
  }

  // بعد الدخول: البانيل الأسود يغطي الشاشة وبعدين خطوة تسجيل البصمة، وبعدها الصفحة اللي بعدها.
  // لو الدخول كان بالبصمة نفسها بنتخطى خطوة التسجيل
  Future<void> _goNext({bool skipFingerprint = false}) async {
    if (!mounted) return;
    setState(() => _covering = true);
    await Future.delayed(const Duration(milliseconds: 780));
    if (!mounted) return;
    final bool admin = _auth.isAdmin();
    Widget nextPage() => admin ? const AdminUI() : const OnboardingUI();
    final Widget next = skipFingerprint
        ? nextPage()
        : FingerprintStepPage(next: (_) => nextPage());
    Navigator.of(context).pushReplacement(irisSwapRoute(next));
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!supabaseConfigured) {
        // المفاتيح لسه Placeholder - وضع تجريبي: التطبيق يكمل عادي
        _goNext();
        return;
      }
      final ok =
          await _auth.signInWithPassword(_email.text.trim(), _password.text);
      if (ok) {
        _goNext();
      } else {
        setState(
            () => _error = 'Sign in failed. Check your email and password.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!supabaseConfigured) {
        _goNext();
        return;
      }
      final ok = await _auth.signUpWithPassword(
          _regEmail.text.trim(), _regPassword.text);
      if (ok) {
        _goNext();
      } else {
        setState(() => _error = 'Registration failed. Try another email.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // دخول بالبيومتركس: بيستخدم التحقق البيومتري القوي المسجل على الجهاز
  // (بصمة و/أو وش حسب ما الجهاز بيدعم - أندرويد هو اللي بيحدد شكل البرومبت)
  Future<void> _signInWithFace() async {
    setState(() {
      _scanning = true;
      _scanDone = false;
      _error = null;
    });
    bool ok = false;
    try {
      final canCheck = await _biometric.canCheckBiometrics;
      if (!canCheck) {
        ok = true; // الجهاز مش بيدعم بيومتركس - نكمل في الوضع التجريبي
      } else {
        ok = await _biometric.authenticate(
          localizedReason: 'Scan to sign in to I.R.I.S',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      }
    } catch (_) {
      ok = false; // المستخدم لغى أو حصل خطأ
    }
    if (!mounted) return;
    if (ok) {
      // الميش يخضر، علامة الصح تظهر، وبعدين "Welcome back" ونكمل
      setState(() => _scanDone = true);
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      setState(() => _scanning = false);
      _goNext(skipFingerprint: true);
    } else {
      setState(() => _scanning = false);
    }
  }

  // اسم المستخدم من إيميل الحساب (أو الإيميل المكتوب) لشاشة الترحيب بعد المسح
  String? _displayName() {
    final email = _auth.currentEmail ??
        (_email.text.trim().isNotEmpty ? _email.text.trim() : null);
    if (email == null || !email.contains('@')) return null;
    final name = email.split('@').first;
    return name.isEmpty ? null : name;
  }

  Future<void> _signInSocial(Future<void> Function() startOAuth) async {
    setState(() => _error = null);
    if (!supabaseConfigured) {
      _goNext(); // وضع تجريبي لحد ما المفاتيح تتضاف
      return;
    }
    await startOAuth();
  }

  // مسحة التبديل القطرية: بانيل أزرق بحافة مائلة بيعدي على الشاشة (زي الفيديو
  // بتاع محمود، بس أزرق بدل برتقالي)، وفي نصها - لما الشاشة متغطية - البانيلات
  // بتبدل أماكنها. بعد ما تخلص بنكمل الأكشن المطلوب (دخول / تبديل الفورم)
  Future<void> _sweepSwap(
      {bool alsoToggleMode = false, Future<void> Function()? after}) async {
    if (_sweepBusy) return;
    _sweepBusy = true;
    unawaited(_sweepController.forward(from: 0));
    await Future.delayed(const Duration(milliseconds: 380));
    if (mounted) {
      setState(() {
        _panelsSwapped = !_panelsSwapped;
        if (alsoToggleMode) {
          _showRegister = !_showRegister;
          _error = null;
        }
      });
    }
    await Future.delayed(const Duration(milliseconds: 420));
    if (mounted) _sweepController.reset();
    _sweepBusy = false;
    if (after != null && mounted) await after();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // تخطيطات مختلفة: موبايل / لابتوب-PC / تلفزيون
    final bool isWide = width >= 600;
    final bool isTv = width > 1100;
    final double uiScale = isTv ? 1.35 : (isWide ? 1.1 : 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isWide) _buildSplitWide(uiScale, isTv) else _buildMobile(uiScale),
          if (_scanning) _buildScanningOverlay(uiScale),
        ],
      ),
    );
  }

  // ============ تخطيط اللابتوب/التلفزيون: الشاشة نصين ============
  // نص أسود بحافة منحنية متوهجة فيه اللوجو وWelcome back (مطر على اللابتوب ونجوم على التلفزيون)،
  // والنص التاني شبكة أعصاب الشبكية المتحركة والفورم عليها. البانيلين بيبدلوا أماكنهم
  Widget _buildSplitWide(double uiScale, bool isTv) {
    return LayoutBuilder(
      builder: (context, c) {
        final W = c.maxWidth, H = c.maxHeight;
        final s = isTv ? (W / 1280).clamp(0.6, 2.2).toDouble() : uiScale;
        final half = W / 2;
        final apex = W * 0.52;
        final bulge = min(
            H * 0.32, W * 0.17); // سهم القوس: كل ما زاد القوس بقى أقرب لدايرة
        final panelOnLeft = _showRegister == _panelsSwapped;
        final formW = isTv ? half * 0.66 : min(half * 0.78, 400.0 * uiScale);
        final formKey = ValueKey(_showRegister ? 'reg' : 'login');
        return Stack(
          fit: StackFit.expand,
          children: [
            // الخلفية: شبكة أعصاب (نقطة الانطلاق عند الحافة المنحنية)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              left: 0,
              top: 0,
              width: W,
              height: H,
              child: RetinaNetwork(
                animation: _rainController,
                origin: const Offset(0.5, 0.5),
                spread: panelOnLeft ? 0 : pi,
              ),
            ),
            // الفورم
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              left: panelOnLeft ? apex : 0,
              top: 0,
              width: W - apex,
              height: H,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    width: formW + 48 * s,
                    padding: EdgeInsets.all(24 * s),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05080C).withOpacity(0.72),
                      borderRadius: BorderRadius.circular(26 * s),
                      border: Border.all(color: kIrisAccent.withOpacity(0.22)),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: isTv
                          ? (_showRegister
                              ? _tvRegisterForm(s, key: formKey)
                              : _tvLoginForm(s, key: formKey))
                          : (_showRegister
                              ? _registerForm(uiScale, key: formKey)
                              : _loginForm(uiScale, key: formKey)),
                    ),
                  ),
                ),
              ),
            ),
            // النص الأسود بحافة منحنية
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              left: _covering
                  ? (panelOnLeft ? 0 : -bulge)
                  : (panelOnLeft ? 0 : W - apex),
              top: 0,
              width: _covering ? W + bulge : apex,
              height: H,
              child: CustomPaint(
                painter: SidePanelPainter(bulgeRight: panelOnLeft, sag: bulge),
                child: ClipPath(
                  clipper:
                      SidePanelClipper(bulgeRight: panelOnLeft, sag: bulge),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        child: isTv
                            ? AnimatedBuilder(
                                animation: _orbitController,
                                builder: (context, _) => CustomPaint(
                                  painter: _TwinkleStarsPainter(
                                      progress: _orbitController.value),
                                ),
                              )
                            : AnimatedBuilder(
                                animation: _rainController,
                                builder: (context, _) => CustomPaint(
                                  painter: RainPainter(
                                      progress: _rainController.value),
                                ),
                              ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: panelOnLeft ? 0 : bulge * 0.6,
                            right: panelOnLeft ? bulge * 0.6 : 0),
                        child: _tvWelcomePanel(isTv ? s : s * 1.15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _sweepOverlay(),
          ],
        );
      },
    );
  }

  // بانيل الترحيب: مدار نجوم + لوجو بيلف ٣٦٠ درجة بنبض أزرق + نص وزرار
  Widget _tvWelcomePanel(double s) {
    return Container(
      child: AnimatedBuilder(
        animation: _orbitController,
        builder: (context, _) {
          final pulse = 0.5 + 0.5 * sin(_orbitController.value * 2 * pi);
          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 170 * s,
                      height: 170 * s,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  kIrisAccent.withOpacity(0.10 + 0.14 * pulse),
                              blurRadius: (46 + 24 * pulse) * s,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: RotationTransition(
                          turns: _orbitController,
                          child: IrisLogo(size: 170 * s),
                        ),
                      ),
                    ),
                    SizedBox(height: 26 * s),
                    Text(
                      _showRegister ? 'Join I.R.I.S' : 'Welcome back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26 * s,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 10 * s),
                    SizedBox(
                      width: 270 * s,
                      child: Text(
                        _showRegister
                            ? 'Already registered? Log in with your email and password to continue.'
                            : 'New here? Create your account and start your journey with I.R.I.S.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13.5 * s,
                            fontWeight: FontWeight.w600,
                            height: 1.55),
                      ),
                    ),
                    SizedBox(height: 18 * s),
                    SizedBox(
                      width: 150 * s,
                      height: 42 * s,
                      child: OutlinedButton(
                        onPressed: () => _sweepSwap(alsoToggleMode: true),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: Colors.white, width: 1.6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24 * s)),
                        ),
                        child: Text(
                          _showRegister ? 'Login' : 'Sign Up',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5 * s,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tvTitle(String title, String sub, double s) {
    return Column(
      children: [
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 25 * s,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6)),
        SizedBox(height: 4 * s),
        Text(sub,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12 * s)),
      ],
    );
  }

  Widget _tvError(double s) {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 8 * s),
      child: Text(_error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.redAccent, fontSize: 12 * s)),
    );
  }

  // حقل التلفزيون: عنوان بحروف كبيرة فوقه، وصندوق بحافة فاتحة وأيقونة في مربع متدرج
  Widget _tvField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required double s,
    bool password = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white70,
                fontSize: 10.5 * s,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1)),
        SizedBox(height: 5 * s),
        Container(
          height: 46 * s,
          decoration: BoxDecoration(
            color: const Color(0xFF12152A),
            borderRadius: BorderRadius.circular(14 * s),
            border:
                Border.all(color: kIrisAccent.withOpacity(0.55), width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 34 * s,
                height: 34 * s,
                margin: EdgeInsets.only(left: 6 * s, right: 10 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11 * s),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kIrisAccent, kIrisAccentDeep],
                  ),
                ),
                child: Icon(icon, color: Colors.black87, size: 17 * s),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) {
                    if (_missing.remove(controller) != null) setState(() {});
                  },
                  obscureText: password && _obscure,
                  style: TextStyle(color: Colors.white, fontSize: 14 * s),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                        color: Colors.white38,
                        fontSize: 14 * s,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              if (password)
                GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Padding(
                    padding: EdgeInsets.only(right: 12 * s),
                    child: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white70,
                        size: 18 * s),
                  ),
                ),
            ],
          ),
        ),
        if (_missing[controller] != null) ...[
          SizedBox(height: 4 * s),
          Text(_missing[controller]!,
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11.5 * s,
                  fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }

  // زرار متدرج أزرق (بدل البنفسجي-وردي في المرجع)
  Widget _tvGradButton(String label, double s, VoidCallback? onPressed) {
    return Container(
      height: 46 * s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14 * s),
        gradient: const LinearGradient(
            colors: [Color(0xFF3B6A94), Color(0xFF7FA6C6)]),
        boxShadow: [
          BoxShadow(
              color: kIrisAccent.withOpacity(0.4),
              blurRadius: 18 * s,
              offset: Offset(0, 6 * s)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14 * s),
          onTap: onPressed,
          child: Center(
            child: _busy
                ? SizedBox(
                    width: 20 * s,
                    height: 20 * s,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(label,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15 * s,
                        fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _tvOrDivider(double s) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.10))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          child: Text('OR CONTINUE WITH',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9.5 * s,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.10))),
      ],
    );
  }

  // أزرار المواقع في صف واحد بعرض الفورم: أيقونة الموقع واسمه جنب بعض
  Widget _wideSocialRow(double s,
      {bool showLabels = true, bool stacked = false}) {
    Widget b(IconData icon, String label, Future<void> Function() fn) {
      return Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 3 * s),
          child: InkWell(
            onTap: () => _signInSocial(fn),
            borderRadius: BorderRadius.circular(12 * s),
            child: Container(
              height: (stacked ? 54 : 42) * s,
              decoration: BoxDecoration(
                color: const Color(0xFF14172B),
                borderRadius: BorderRadius.circular(12 * s),
                border: Border.all(color: Colors.white12),
              ),
              child: stacked
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(icon, color: Colors.white, size: 18 * s),
                        SizedBox(height: 4 * s),
                        Text(label,
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5 * s,
                                fontWeight: FontWeight.w700)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(icon, color: Colors.white, size: 16 * s),
                        if (showLabels) ...[
                          SizedBox(width: 6 * s),
                          Flexible(
                            child: Text(label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5 * s,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        b(FontAwesomeIcons.google, 'Google', _auth.signInWithGoogle),
        b(FontAwesomeIcons.microsoft, 'Microsoft', _auth.signInWithMicrosoft),
        b(FontAwesomeIcons.apple, 'Apple', _auth.signInWithApple),
        b(FontAwesomeIcons.github, 'GitHub', _auth.signInWithGitHub),
      ],
    );
  }

  Widget _tvLoginForm(double s, {Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tvTitle('Welcome Back',
            'Sign in to continue your journey with I.R.I.S.', s),
        SizedBox(height: 12 * s),
        Container(
          padding: EdgeInsets.all(10 * s),
          decoration: BoxDecoration(
            color: kIrisAccentDeep.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12 * s),
            border: Border.all(color: kIrisAccent.withOpacity(0.35)),
          ),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: 'Sign up first, then sign in. ',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              TextSpan(
                  text: 'Use the same email and password you registered with.'),
            ]),
            style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 10.5 * s,
                height: 1.45),
          ),
        ),
        _tvError(s),
        SizedBox(height: 12 * s),
        _tvField(
            controller: _email,
            label: 'EMAIL',
            hint: 'you@example.com',
            icon: Icons.mail_outline,
            s: s),
        SizedBox(height: 10 * s),
        _tvField(
            controller: _password,
            label: 'PASSWORD',
            hint: 'Enter your password',
            icon: Icons.lock_outline,
            s: s,
            password: true),
        SizedBox(height: 10 * s),
        Row(
          children: [
            SizedBox(
              width: 20 * s,
              height: 20 * s,
              child: Checkbox(
                value: _keepSignedIn,
                onChanged: (v) => setState(() => _keepSignedIn = v ?? true),
                activeColor: kIrisAccent,
                checkColor: Colors.black,
                side: const BorderSide(color: Colors.white38),
              ),
            ),
            SizedBox(width: 8 * s),
            Text('Remember me',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5 * s,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('Forgot password?',
                style: TextStyle(
                    color: kIrisAccent,
                    fontSize: 11.5 * s,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        SizedBox(height: 10 * s),
        _tvGradButton('Login to I.R.I.S', s, _busy ? null : () => _trySignIn()),
        SizedBox(height: 8 * s),
        _tvOrDivider(s),
        SizedBox(height: 8 * s),
        _wideSocialRow(s),
        SizedBox(height: 12 * s),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New to I.R.I.S? ',
                style: TextStyle(color: Colors.white70, fontSize: 11.5 * s)),
            GestureDetector(
              onTap: () => _sweepSwap(alsoToggleMode: true),
              child: Text('Create an account',
                  style: TextStyle(
                      color: kIrisAccent,
                      fontSize: 11.5 * s,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tvRegisterForm(double s, {Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tvTitle('Create Account',
            'Join I.R.I.S - your assistant is waiting for you.', s),
        _tvError(s),
        SizedBox(height: 14 * s),
        _tvField(
            controller: _regName,
            label: 'YOUR NAME',
            hint: 'Your full name',
            icon: Icons.person_outline,
            s: s),
        SizedBox(height: 10 * s),
        _tvField(
            controller: _regEmail,
            label: 'EMAIL',
            hint: 'you@example.com',
            icon: Icons.mail_outline,
            s: s),
        SizedBox(height: 10 * s),
        _tvField(
            controller: _regPassword,
            label: 'PASSWORD',
            hint: 'Create a password',
            icon: Icons.lock_outline,
            s: s,
            password: true),
        SizedBox(height: 12 * s),
        _tvGradButton(
            'Create My Account', s, _busy ? null : () => _tryRegister()),
        SizedBox(height: 12 * s),
        _tvOrDivider(s),
        SizedBox(height: 8 * s),
        _wideSocialRow(s),
        SizedBox(height: 14 * s),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already have an account? ',
                style: TextStyle(color: Colors.white70, fontSize: 11.5 * s)),
            GestureDetector(
              onTap: () => _sweepSwap(alsoToggleMode: true),
              child: Text('Login instead',
                  style: TextStyle(
                      color: kIrisAccent,
                      fontSize: 11.5 * s,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ],
    );
  }

  // ============ تخطيط الموبايل: نص أسود فوق (لوجو + Welcome back) بحافة منحنية،
  // ونص تحت فيه شبكة أعصاب الشبكية المتوهجة والمتحركة والفورم عليها ============
  Widget _buildMobile(double uiScale) {
    Widget label(String t, {Widget? trailing}) => Padding(
          padding: EdgeInsets.only(bottom: 6 * uiScale),
          child: Row(
            children: [
              Text(t,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12.5 * uiScale,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
        );
    InputDecoration deco(String hint, IconData icon,
            {Widget? suffix, String? err}) =>
        InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon,
              color: kIrisAccent.withOpacity(0.8), size: 20 * uiScale),
          hintStyle: TextStyle(color: Colors.white30, fontSize: 14 * uiScale),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFF0E141B).withOpacity(0.88),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * uiScale, vertical: 15 * uiScale),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: kIrisAccent.withOpacity(0.18)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: kIrisAccent.withOpacity(0.18)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kIrisAccent, width: 1.2),
          ),
        );
    return LayoutBuilder(builder: (context, c) {
      final headerH = c.maxHeight * 0.40;
      return Stack(
        fit: StackFit.expand,
        children: [
          // شبكة أعصاب الشبكية في الخلفية (النص التحتاني)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            opacity: _bgReady ? 1 : 0,
            child: RetinaNetwork(animation: _rainController),
          ),
          // الفورم
          Positioned.fill(
            top: headerH - 6,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _covering ? 0 : 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05080C).withOpacity(0.66),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: kIrisAccent.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                          color: kIrisAccent.withOpacity(0.10), blurRadius: 24),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label('Email address'),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                            color: Colors.white, fontSize: 15 * uiScale),
                        onChanged: (_) {
                          if (_missing.remove(_email) != null) setState(() {});
                        },
                        decoration: deco(
                          'name@example.com',
                          Icons.mail_outline,
                        ),
                      ),
                      _missingMsg(_email, uiScale),
                      SizedBox(height: 12 * uiScale),
                      label('Password',
                          trailing: Text('Forgot password?',
                              style: TextStyle(
                                  color: kIrisAccent,
                                  fontSize: 12.5 * uiScale,
                                  fontWeight: FontWeight.w700))),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        style: TextStyle(
                            color: Colors.white, fontSize: 15 * uiScale),
                        onChanged: (_) {
                          if (_missing.remove(_password) != null)
                            setState(() {});
                        },
                        decoration: deco(
                          '••••••••••',
                          Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white38,
                              size: 20 * uiScale,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      _missingMsg(_password, uiScale),
                      SizedBox(height: 8 * uiScale),
                      Row(
                        children: [
                          SizedBox(
                            width: 22 * uiScale,
                            height: 22 * uiScale,
                            child: Checkbox(
                              value: _keepSignedIn,
                              onChanged: (v) =>
                                  setState(() => _keepSignedIn = v ?? true),
                              activeColor: kIrisAccent,
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.white38),
                            ),
                          ),
                          SizedBox(width: 10 * uiScale),
                          Text('Keep me signed in',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5 * uiScale)),
                        ],
                      ),
                      if (_error != null) ...[
                        SizedBox(height: 6 * uiScale),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12.5 * uiScale)),
                      ],
                      SizedBox(height: 14 * uiScale),
                      _morphButton(
                          'Sign in', uiScale, _busy ? null : _trySignIn),
                      SizedBox(height: 14 * uiScale),
                      Center(
                        child: Text('OR CONTINUE WITH',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10 * uiScale,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4)),
                      ),
                      SizedBox(height: 10 * uiScale),
                      _wideSocialRow(uiScale, stacked: true),
                      SizedBox(height: 14 * uiScale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12.5 * uiScale)),
                          GestureDetector(
                            onTap: () {},
                            child: Text('Register here',
                                style: TextStyle(
                                    color: kIrisAccent,
                                    fontSize: 12.5 * uiScale,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // النص الأسود فوق: حافة منحنية متوهجة + لوجو + Welcome back
          AnimatedPositioned(
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeInOutCubic,
            top: 0,
            left: 0,
            right: 0,
            height: _covering
                ? c.maxHeight + CurvedHeaderPainter.sagFor(Size(c.maxWidth, 0))
                : headerH,
            child: CustomPaint(
              painter: const CurvedHeaderPainter(),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: headerH,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: 34 * uiScale, bottom: 20 * uiScale),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          AnimatedBuilder(
                            animation: _orbitController,
                            builder: (context, _) {
                              final pulse = 0.5 +
                                  0.5 * sin(_orbitController.value * 2 * pi);
                              final d = 140 * uiScale;
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: kIrisAccent
                                          .withOpacity(0.10 + 0.14 * pulse),
                                      blurRadius: 34 + 14 * pulse,
                                    ),
                                  ],
                                ),
                                child: RotationTransition(
                                    turns: _orbitController,
                                    child: IrisLogo(size: d)),
                              );
                            },
                          ),
                          SizedBox(height: 22 * uiScale),
                          _ShimmerText(
                              animation: _shimmer,
                              text: _savedName == null
                                  ? 'اهلا بيك'
                                  : 'اهلا يا $_savedName',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30 * uiScale,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 6 * uiScale),
                          _ShimmerText(
                              animation: _shimmer,
                              phase: 0.18,
                              text: 'سجّل دخولك وكمّل مع آيرس',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14 * uiScale)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // زرار تسجيل الدخول: بيتحول لدايرة تحميل لما العملية تشتغل (مرجع: فيديو SLATE الجديد)
  Widget _morphButton(String label, double uiScale, VoidCallback? onPressed) {
    final h = 50 * uiScale;
    return LayoutBuilder(builder: (context, c) {
      return Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
          width: _busy ? h : c.maxWidth,
          height: h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7FA6C6), kIrisAccent, Color(0xFFB9D3E4)]),
            borderRadius: BorderRadius.circular(_busy ? h / 2 : 14),
            boxShadow: [
              BoxShadow(
                  color: kIrisAccent.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_busy ? h / 2 : 14),
              onTap: onPressed,
              child: Center(
                child: _busy
                    ? SizedBox(
                        width: h * 0.46,
                        height: h * 0.46,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.black))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16 * uiScale,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(width: 8 * uiScale),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.black, size: 18 * uiScale),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ============ فورم اللابتوب: عنوان صغير فوق + حقول بحافة سفلية + زرار متوهج ============
  Widget _loginForm(double uiScale, {Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Login',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 24 * uiScale,
                fontWeight: FontWeight.w800)),
        SizedBox(height: 22 * uiScale),
        _underlineField(
            controller: _email,
            label: 'Email *',
            icon: Icons.mail_outline,
            uiScale: uiScale),
        SizedBox(height: 14 * uiScale),
        _underlineField(
            controller: _password,
            label: 'Password *',
            icon: Icons.lock_outline,
            obscure: true,
            uiScale: uiScale),
        if (_error != null) ...[
          SizedBox(height: 10 * uiScale),
          Text(_error!,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.redAccent, fontSize: 12 * uiScale)),
        ],
        SizedBox(height: 26 * uiScale),
        _glowButton(
            label: 'Sign in',
            uiScale: uiScale,
            onPressed: _busy ? null : () => _trySignIn(),
            autofocus: true),
        SizedBox(height: 4 * uiScale),
        _wideSocialRow(uiScale * 0.95, showLabels: false),
        SizedBox(height: 16 * uiScale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Not registered? ',
                style:
                    TextStyle(color: Colors.white70, fontSize: 12.5 * uiScale)),
            GestureDetector(
              onTap: () => _sweepSwap(alsoToggleMode: true),
              child: Text('Create an account',
                  style: TextStyle(
                      color: kIrisAccent,
                      fontSize: 12.5 * uiScale,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _registerForm(double uiScale, {Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Register',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 24 * uiScale,
                fontWeight: FontWeight.w800)),
        SizedBox(height: 20 * uiScale),
        _underlineField(
            controller: _regName,
            label: 'Full Name *',
            icon: Icons.badge_outlined,
            uiScale: uiScale),
        SizedBox(height: 12 * uiScale),
        _underlineField(
            controller: _regEmail,
            label: 'Email *',
            icon: Icons.mail_outline,
            uiScale: uiScale),
        SizedBox(height: 12 * uiScale),
        _underlineField(
            controller: _regPassword,
            label: 'Password *',
            icon: Icons.lock_outline,
            obscure: true,
            uiScale: uiScale),
        if (_error != null) ...[
          SizedBox(height: 10 * uiScale),
          Text(_error!,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.redAccent, fontSize: 12 * uiScale)),
        ],
        SizedBox(height: 24 * uiScale),
        _glowButton(
            label: 'Create',
            uiScale: uiScale,
            onPressed: _busy ? null : () => _tryRegister()),
        SizedBox(height: 14 * uiScale),
        _wideSocialRow(uiScale * 0.95, showLabels: false),
        SizedBox(height: 16 * uiScale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already registered? ',
                style:
                    TextStyle(color: Colors.white70, fontSize: 12.5 * uiScale)),
            GestureDetector(
              onTap: () => _sweepSwap(alsoToggleMode: true),
              child: Text('Sign in',
                  style: TextStyle(
                      color: kIrisAccent,
                      fontSize: 12.5 * uiScale,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }

  // ============ عناصر مشتركة ============
  Widget _primaryButton({
    required String label,
    required double uiScale,
    required VoidCallback? onPressed,
    bool autofocus = false,
  }) {
    return SizedBox(
      height: 50 * uiScale,
      child: ElevatedButton(
        autofocus: autofocus,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kIrisAccent,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Text(label,
                style: TextStyle(
                    fontSize: 16 * uiScale, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // الزرار المتوهج بتاع شاشة اللابتوب
  Widget _glowButton({
    required String label,
    required double uiScale,
    required VoidCallback? onPressed,
    bool autofocus = false,
  }) {
    return Container(
      height: 52 * uiScale,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kIrisAccent.withOpacity(0.55),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        autofocus: autofocus,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kIrisAccent,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Text(label,
                style: TextStyle(
                    fontSize: 16 * uiScale, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _faceScanButton(double uiScale, {bool compact = false}) {
    return SizedBox(
      height: (compact ? 44 : 52) * uiScale,
      child: OutlinedButton.icon(
        onPressed: _signInWithFace,
        icon: Icon(Icons.fingerprint, color: kIrisAccent, size: 22 * uiScale),
        label: Text('Sign in with fingerprint',
            style: TextStyle(color: kIrisAccent, fontSize: 14 * uiScale)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: kIrisAccent.withOpacity(0.6), width: 1.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _orDivider(double uiScale) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * uiScale),
          child: Text('or continue with',
              style: TextStyle(color: Colors.white38, fontSize: 12 * uiScale)),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }

  // أزرار المواقع باللوجوهات الرسمية: جوجل ومايكروسوفت وأبل وجيت هاب
  Widget _socialRow(double uiScale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(
            icon: FontAwesomeIcons.google,
            label: 'Google',
            uiScale: uiScale,
            onTap: () => _signInSocial(_auth.signInWithGoogle)),
        SizedBox(width: 12 * uiScale),
        _socialButton(
            icon: FontAwesomeIcons.microsoft,
            label: 'Microsoft',
            uiScale: uiScale,
            onTap: () => _signInSocial(_auth.signInWithMicrosoft)),
        SizedBox(width: 12 * uiScale),
        _socialButton(
            icon: FontAwesomeIcons.apple,
            label: 'Apple',
            uiScale: uiScale,
            onTap: () => _signInSocial(_auth.signInWithApple)),
        SizedBox(width: 12 * uiScale),
        _socialButton(
            icon: FontAwesomeIcons.github,
            label: 'GitHub',
            uiScale: uiScale,
            onTap: () => _signInSocial(_auth.signInWithGitHub)),
      ],
    );
  }

  Widget _missingMsg(TextEditingController c, double uiScale) {
    final m = _missing[c];
    if (m == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 5 * uiScale, left: 4 * uiScale),
      child: Text(m,
          style: TextStyle(
              color: Colors.redAccent,
              fontSize: 12 * uiScale,
              fontWeight: FontWeight.w600)),
    );
  }

  // حقل بحافة سفلية بس (ستايل شاشة اللابتوب)
  Widget _underlineField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double uiScale,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: (_) {
            if (_missing.remove(controller) != null) setState(() {});
          },
          style: TextStyle(color: Colors.white, fontSize: 15 * uiScale),
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                TextStyle(color: Colors.white54, fontSize: 14 * uiScale),
            floatingLabelStyle: TextStyle(color: kIrisAccent),
            prefixIcon: Icon(icon, color: Colors.white38, size: 20 * uiScale),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: kIrisAccent, width: 1.6),
            ),
          ),
        ),
        _missingMsg(controller, uiScale),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required IconData icon,
    required double uiScale,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: Colors.white70, fontSize: 13 * uiScale)),
        SizedBox(height: 6 * uiScale),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: Colors.white, fontSize: 15 * uiScale),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white38, size: 20 * uiScale),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFF151A1F),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kIrisAccent, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required double uiScale,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 12 * uiScale, vertical: 10 * uiScale),
        decoration: BoxDecoration(
          color: const Color(0xFF151A1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, color: Colors.white, size: 22 * uiScale),
            SizedBox(height: 4 * uiScale),
            Text(label,
                style:
                    TextStyle(color: Colors.white70, fontSize: 11 * uiScale)),
          ],
        ),
      ),
    );
  }

  // مسحة التبديل القطرية: بانيل أزرق بحافة مائلة بيعدي على الشاشة كلها
  // (بلور وراه) وفي نصها - لما بيغطي كل حاجة - البانيلات بتبدل أماكنها
  Widget _sweepOverlay() {
    return AnimatedBuilder(
      animation: _sweepController,
      builder: (context, _) {
        final p = _sweepController.value;
        if (p <= 0 || p >= 1) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final eased = Curves.easeInOut.transform(p);
            final x = -w * 1.25 + eased * w * 2.5;
            return Stack(
              children: [
                Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  width: w * 1.25,
                  child: ClipPath(
                    clipper: const _DiagonalEdgeClipper(),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kIrisAccentDeep.withOpacity(0.96),
                              const Color(0xFF14202E).withOpacity(0.96),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // طبقة المسح البيومتري: ميش على شكل وجه + خط مسح شبكية، وعند النجاح
  // الميش يخضر وعلامة صح تظهر وترحيب باسم المستخدم
  Widget _buildScanningOverlay(double uiScale) {
    final name = _displayName();
    return Container(
      color: Colors.black.withOpacity(0.94),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240 * uiScale,
              height: 240 * uiScale,
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: FaceScanPainter(
                      progress: _scanController.value,
                      success: _scanDone ? 1.0 : 0.0,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24 * uiScale),
            if (!_scanDone) ...[
              Text('Scanning...',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * uiScale,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 8 * uiScale),
              Text('Verify with your fingerprint',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.white38, fontSize: 12 * uiScale)),
              SizedBox(height: 24 * uiScale),
              TextButton(
                onPressed: () => setState(() => _scanning = false),
                child: Text('Use password instead',
                    style:
                        TextStyle(color: kIrisAccent, fontSize: 14 * uiScale)),
              ),
            ] else ...[
              Text(
                name != null ? 'Welcome back, $name!' : 'Welcome back!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: const Color(0xFF2EE66B),
                    fontSize: 20 * uiScale,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Color(0xFF2EE66B), blurRadius: 18),
                    ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// رسام المطر المتحرك - خطوط مائلة بتنزل زي الفيديو
class RainPainter extends CustomPainter {
  final double progress;
  RainPainter({required this.progress});

  static const int _dropCount = 90;
  static final List<List<double>> _drops = _buildDrops();

  // كل قطرة: x نسبي، بداية y نسبية، سرعة، طول، سمك
  static List<List<double>> _buildDrops() {
    final rnd = Random(42);
    return List.generate(
      _dropCount,
      (_) => [
        rnd.nextDouble(), // x
        rnd.nextDouble(), // startY
        0.55 + rnd.nextDouble() * 0.7, // speed
        0.025 + rnd.nextDouble() * 0.05, // length
        0.6 + rnd.nextDouble() * 1.4, // thickness
      ],
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    const slant = 0.06; // ميل بسيط زي الفيديو
    for (final d in _drops) {
      final y = ((d[1] + progress * d[2]) % 1.0) * size.height;
      final x = d[0] * size.width + (y / size.height) * slant * size.width;
      final len = d[3] * size.height;
      paint
        ..color = Colors.white.withOpacity(0.16 + 0.14 * d[4] / 2)
        ..strokeWidth = d[4];
      canvas.drawLine(
        Offset(x, y),
        Offset(x - slant * len * 2, y - len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RainPainter oldDelegate) => true;
}

// نجوم خفيفة ثابتة في خلفية كارت التلفزيون
class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(11);
    final paint = Paint();
    for (int i = 0; i < 60; i++) {
      paint.color = Colors.white.withOpacity(0.05 + rnd.nextDouble() * 0.15);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.6 + rnd.nextDouble() * 1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FaceScanPainter extends CustomPainter {
  final double progress; // حركة خط المسح
  final double success; // 0 بيمسح (أزرق) / 1 اتأكد (أخضر)
  FaceScanPainter({required this.progress, this.success = 0});

  static const Color accent = kIrisAccent;
  static const Color ok = Color(0xFF2EE66B);

  @override
  void paint(Canvas canvas, Size size) {
    final col = Color.lerp(accent, ok, success)!;
    final c = size.center(Offset.zero);
    final rx = size.width * 0.30;
    final ry = size.height * 0.38;

    // الإطار المتوهج
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(28)),
      Paint()
        ..color = col.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final meshPaint = Paint()
      ..color = col.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dotPaint = Paint()..color = col.withOpacity(0.85);

    // خريطة الميش على شكل الوجه: خطوط عرض مقوسة
    final List<Offset> nodes = [];
    for (int i = -3; i <= 3; i++) {
      final t = i / 3.2;
      final yy = c.dy + t * ry;
      final half = rx * sqrt(max(0.0, 1 - t * t));
      final path = Path()
        ..moveTo(c.dx - half, yy)
        ..quadraticBezierTo(c.dx, yy + 8, c.dx + half, yy);
      canvas.drawPath(path, meshPaint);
      for (int j = -2; j <= 2; j++) {
        nodes.add(Offset(c.dx + j * half / 2.2, yy + 4));
      }
    }
    // خطوط طول مقوسة
    for (int j = -3; j <= 3; j++) {
      final t = j / 3.2;
      final xTop = c.dx + t * rx * 0.45;
      final path = Path()
        ..moveTo(xTop, c.dy - ry)
        ..quadraticBezierTo(c.dx + t * rx * 1.15, c.dy, xTop, c.dy + ry);
      canvas.drawPath(path, meshPaint);
    }
    // نقط الميش
    for (final p in nodes) {
      canvas.drawCircle(p, 1.6, dotPaint);
    }
    // العينين (منطقة مسح الشبكية)
    canvas.drawCircle(c + Offset(-rx * 0.38, -ry * 0.18), 4, dotPaint);
    canvas.drawCircle(c + Offset(rx * 0.38, -ry * 0.18), 4, dotPaint);

    if (success < 0.5) {
      // خط المسح بينزل ويطلع
      final y =
          size.height * (progress < 0.5 ? progress * 2 : 2 - progress * 2);
      canvas.drawLine(
        Offset(8, y),
        Offset(size.width - 8, y),
        Paint()
          ..color = col
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    } else {
      // علامة الصح الخضرا المتوهجة في النص
      final check = Path()
        ..moveTo(c.dx - 26, c.dy)
        ..lineTo(c.dx - 6, c.dy + 20)
        ..lineTo(c.dx + 30, c.dy - 22);
      canvas.drawPath(
        check,
        Paint()
          ..color = ok
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FaceScanPainter oldDelegate) => true;
}

// نجوم متلألئة متوهجة بستايل آيرس - خلفية شاشة التلفزيون
class _TwinkleStarsPainter extends CustomPainter {
  final double progress;
  _TwinkleStarsPainter({required this.progress});

  static const int _count = 140;
  static final List<List<double>> _stars = _build();

  // كل نجمة: x، y، حجم، طور الوميض، سرعته، درجة الزرقة
  static List<List<double>> _build() {
    final rnd = Random(11);
    return List.generate(
      _count,
      (_) => [
        rnd.nextDouble(),
        rnd.nextDouble(),
        0.6 + rnd.nextDouble() * 1.8,
        rnd.nextDouble(),
        0.5 + rnd.nextDouble(),
        rnd.nextDouble(),
      ],
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final tw = 0.5 + 0.5 * sin(2 * pi * (progress * s[4] + s[3]));
      final alpha = 0.25 + 0.75 * tw;
      final col = Color.lerp(Colors.white, const Color(0xFF9DB9CE), s[5])!
          .withOpacity(alpha);
      final p = Offset(s[0] * size.width, s[1] * size.height);
      // توهج للنجوم الكبيرة
      if (s[2] > 1.8) {
        canvas.drawCircle(
          p,
          s[2] * 3,
          Paint()
            ..color = col.withOpacity(0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawCircle(p, s[2], Paint()..color = col);
    }
  }

  @override
  bool shouldRepaint(covariant _TwinkleStarsPainter oldDelegate) => true;
}

// حافة مائلة لبانيل مسحة التبديل (الدياجونال بتاع فيديو المرجع)
class _DiagonalEdgeClipper extends CustomClipper<Path> {
  const _DiagonalEdgeClipper();

  @override
  Path getClip(Size size) {
    final slant = size.width * 0.18;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - slant, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// مدار نجوم: قطوع ناقصة مايلة بحبيبات زرقا بتلف حوالين اللوجو (مرجع: المجرة في فيديو التلفزيون)
class _OrbitPainter extends CustomPainter {
  final double progress;
  _OrbitPainter({required this.progress});

  static final List<List<double>> _dots = () {
    final r = Random(5);
    return List.generate(
        70,
        (_) => [
              r.nextDouble(), // الطور
              0.35 + r.nextDouble() * 0.6, // نسبة نصف القطر
              0.6 + r.nextDouble() * 1.8, // حجم
              r.nextDouble(), // درجة الزرقة
            ]);
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rx = size.width * 0.52;
    final ry = size.height * 0.30;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.12);
    for (final k in [0.55, 0.78, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: rx * 2 * k, height: ry * 2 * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = kIrisAccent.withOpacity(0.10),
      );
    }
    for (final d in _dots) {
      final a = 2 * pi * (d[0] + progress * (1.2 - d[1]) * 0.6);
      final p = Offset(cos(a) * rx * d[1], sin(a) * ry * d[1]);
      final col = Color.lerp(const Color(0xFF7FD0E8), kIrisAccent, d[3])!;
      canvas.drawCircle(
          p,
          d[2] * 2.4,
          Paint()
            ..color = col.withOpacity(0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(p, d[2], Paint()..color = col.withOpacity(0.85));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => true;
}

// حافة النص الأسود المنحنية بتوهج أزرق خفيف
class CurvedHeaderPainter extends CustomPainter {
  const CurvedHeaderPainter();

  // قوس دايري متماثل ومتمركز: الحواف عند h - sag والمنتصف عند h
  static double sagFor(Size size) => size.width * 0.30;

  Path _path(Size size) {
    final w = size.width, h = size.height;
    final sag = sagFor(size);
    final r = (w * w / 4 + sag * sag) / (2 * sag);
    return Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - sag)
      ..arcToPoint(Offset(0, h - sag),
          radius: Radius.circular(r), clockwise: true)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = _path(size);
    canvas.drawPath(
        p,
        Paint()
          ..color = kIrisAccent.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawPath(p, Paint()..color = Colors.black);
    canvas.drawPath(
        p,
        Paint()
          ..color = kIrisAccent.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// شبكة أعصاب الشبكية: أوعية متفرعة بتطلع من نقطة (القرص البصري) وتتفرع
// بتوهج أزرق، ونبضات ضوء بتجري عليها.
// الرسم مقسوم لطبقتين: ثابتة (بتتحسب مرة واحدة جوه RepaintBoundary) ونبضات خفيفة متحركة
class RetinaNervePainter extends CustomPainter {
  final double progress;
  final Offset origin; // نقطة الانطلاق (نسبة 0..1)
  final double spread; // اتجاه التفرع: زاوية المنتصف بالراديان
  final bool staticLayer; // true = الخلفية والخطوط، false = النبضات بس
  const RetinaNervePainter({
    this.progress = 0,
    this.origin = const Offset(0.5, 0.26),
    this.spread = pi / 2,
    this.staticLayer = true,
  });

  static final Map<String, List<List<Offset>>> _cache = {};

  // تجهيز مسبق: بنحسب فروع الأعصاب أثناء الإنترو عشان شاشة الدخول ما تحسبهاش وقت الفتح
  static void prewarm() {
    const RetinaNervePainter()._branches;
    const RetinaNervePainter(origin: Offset(0.5, 0.26), spread: pi / 2)
        ._branches;
  }

  List<List<Offset>> get _branches {
    final key = '${origin.dx}_${origin.dy}_$spread';
    return _cache.putIfAbsent(key, () => _build(origin, spread));
  }

  static List<List<Offset>> _build(Offset origin, double mid) {
    final rnd = Random(21);
    final out = <List<Offset>>[];
    void grow(Offset start, double angle, double len, int depth) {
      final pts = <Offset>[start];
      var a = angle;
      var p = start;
      const steps = 9;
      for (var i = 0; i < steps; i++) {
        a += (rnd.nextDouble() - 0.5) * 0.45;
        p = Offset(p.dx + cos(a) * len / steps, p.dy + sin(a) * len / steps);
        pts.add(p);
      }
      out.add(pts);
      if (depth > 0) {
        final n = depth > 2 ? 2 : (rnd.nextBool() ? 2 : 1);
        for (var k = 0; k < n; k++) {
          final off = (k == 0 ? -1 : 1) * (0.35 + rnd.nextDouble() * 0.5);
          grow(p, a + off, len * (0.62 + rnd.nextDouble() * 0.2), depth - 1);
        }
      }
    }

    for (var i = 0; i < 7; i++) {
      final a = mid - 1.3 + 2.6 * i / 6 + (rnd.nextDouble() - 0.5) * 0.1;
      grow(origin, a, 0.34, 4);
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Offset m(Offset o) => Offset(o.dx * size.width, o.dy * size.height);
    if (staticLayer) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1118), Color(0xFF05080C)],
            ).createShader(Offset.zero & size));
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5
        ..color = kIrisAccent.withOpacity(0.10);
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.1
        ..color = kIrisAccent.withOpacity(0.5);
      for (final pts in _branches) {
        final path = Path()..moveTo(m(pts[0]).dx, m(pts[0]).dy);
        for (var i = 1; i < pts.length; i++) {
          final q = m(pts[i]);
          final prev = m(pts[i - 1]);
          path.quadraticBezierTo(
              prev.dx, prev.dy, (prev.dx + q.dx) / 2, (prev.dy + q.dy) / 2);
        }
        canvas.drawPath(path, glow);
        canvas.drawPath(path, line);
      }
      final o = m(origin);
      final r = size.shortestSide * 0.22;
      canvas.drawCircle(
          o,
          r,
          Paint()
            ..shader = RadialGradient(colors: [
              kIrisAccent.withOpacity(0.25),
              Colors.transparent,
            ]).createShader(Rect.fromCircle(center: o, radius: r)));
      return;
    }
    // نبضات الضوء (رخيصة: دواير بس بدون بلور)
    final branches = _branches;
    for (var bi = 0; bi < branches.length; bi++) {
      final pts = branches[bi];
      final t = (progress + bi * 0.137) % 1.0;
      final idx = (t * (pts.length - 1)).floor().clamp(0, pts.length - 2);
      final f = t * (pts.length - 1) - idx;
      final pos = Offset.lerp(m(pts[idx]), m(pts[idx + 1]), f)!;
      canvas.drawCircle(
          pos, 6, Paint()..color = const Color(0xFFBFE3FF).withOpacity(0.18));
      canvas.drawCircle(
          pos, 3.2, Paint()..color = const Color(0xFFBFE3FF).withOpacity(0.35));
      canvas.drawCircle(pos, 1.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant RetinaNervePainter old) =>
      !staticLayer && old.progress != progress;
}

// طبقة شبكة الأعصاب الكاملة (ثابتة + نبضات) جاهزة للاستخدام في أي شاشة
class RetinaNetwork extends StatelessWidget {
  final Animation<double> animation;
  final Offset origin;
  final double spread;
  const RetinaNetwork(
      {super.key,
      required this.animation,
      this.origin = const Offset(0.5, 0.26),
      this.spread = pi / 2});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
              painter: RetinaNervePainter(origin: origin, spread: spread)),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) => CustomPaint(
              painter: RetinaNervePainter(
                  progress: animation.value,
                  origin: origin,
                  spread: spread,
                  staticLayer: false),
            ),
          ),
        ),
      ],
    );
  }
}

// حافة النص الأسود الجانبي: قوس دايري حقيقي بينتفخ ناحية الفورم
// (وتر = ارتفاع الشاشة، وسهم = sag، فكل ما زاد السهم بقى القوس أقرب لدايرة)
Path _sidePanelPath(Size size, bool bulgeRight, double sag) {
  final w = size.width, h = size.height;
  final r = (h * h / 4 + sag * sag) / (2 * sag);
  final path = Path();
  if (bulgeRight) {
    final edge = w - sag;
    path
      ..moveTo(0, 0)
      ..lineTo(edge, 0)
      ..arcToPoint(Offset(edge, h), radius: Radius.circular(r), clockwise: true)
      ..lineTo(0, h)
      ..close();
  } else {
    final x0 = sag;
    path
      ..moveTo(w, 0)
      ..lineTo(x0, 0)
      ..arcToPoint(Offset(x0, h), radius: Radius.circular(r), clockwise: false)
      ..lineTo(w, h)
      ..close();
  }
  return path;
}

class SidePanelClipper extends CustomClipper<Path> {
  final bool bulgeRight;
  final double sag;
  const SidePanelClipper({required this.bulgeRight, required this.sag});
  @override
  Path getClip(Size size) => _sidePanelPath(size, bulgeRight, sag);
  @override
  bool shouldReclip(covariant SidePanelClipper old) =>
      old.bulgeRight != bulgeRight || old.sag != sag;
}

class SidePanelPainter extends CustomPainter {
  final bool bulgeRight;
  final double sag;
  const SidePanelPainter({required this.bulgeRight, required this.sag});
  @override
  void paint(Canvas canvas, Size size) {
    final p = _sidePanelPath(size, bulgeRight, sag);
    canvas.drawPath(
        p,
        Paint()
          ..color = kIrisAccent.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawPath(p, Paint()..color = Colors.black);
    canvas.drawPath(
        p,
        Paint()
          ..color = kIrisAccent.withOpacity(0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant SidePanelPainter old) =>
      old.bulgeRight != bulgeRight || old.sag != sag;
}

// لوجو آيرس: الأصل 1024px واللوجو نفسه بياخد حوالي ثلثين الصورة، فبنكبّره جوه الدايرة
// عشان يملا المساحة بحدة عالية (من غير فلتر أو طبقة تعتيم فوقه)
class IrisLogo extends StatelessWidget {
  final double size;
  const IrisLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Transform.scale(
          scale: 1.42,
          child: Image.asset(
            'assets/logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
          ),
        ),
      ),
    );
  }
}

// انتقال التبديل: البانيل الأسود (اللي غطى الشاشة) بينسحب للناحية التانية
// (تحت في الموبايل / يمين في اللابتوب والتلفزيون) ويكشف الخطوة اللي بعده
Route<void> irisSwapRoute(Widget next) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 760),
    pageBuilder: (_, __, ___) => next,
    transitionsBuilder: (ctx, anim, __, child) {
      final size = MediaQuery.of(ctx).size;
      final wide = size.width >= 700;
      return AnimatedBuilder(
        animation: anim,
        child: child,
        builder: (_, ch) {
          final t = Curves.easeInOutCubic.transform(anim.value);
          final logoOp = (1 - t * 2.2).clamp(0.0, 1.0);
          Widget overlay;
          if (wide) {
            final sag = min(size.height * 0.32, size.width * 0.17);
            final w = (size.width + sag) * (1 - t);
            overlay = Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: w,
              child: CustomPaint(
                painter: SidePanelPainter(bulgeRight: false, sag: sag),
                child: Center(
                    child:
                        Opacity(opacity: logoOp, child: IrisLogo(size: 150))),
              ),
            );
          } else {
            final sag = size.width * 0.30;
            final h = (size.height + sag) * (1 - t);
            overlay = Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: h,
              child: Stack(fit: StackFit.expand, children: [
                Transform.flip(
                    flipY: true,
                    child: CustomPaint(painter: const CurvedHeaderPainter())),
                Align(
                    alignment: const Alignment(0, 0),
                    child:
                        Opacity(opacity: logoOp, child: IrisLogo(size: 104))),
              ]),
            );
          }
          return Stack(fit: StackFit.expand, children: [
            ch!,
            if (anim.value < 1) overlay,
          ]);
        },
      );
    },
  );
}

// ستارة آيرس: شاشة سودا كاملة + لوجو كبير في النص، وبعدين الستارة بتتشال بحافة
// مائلة (قطرية) من تحت لفوق وتكشف الشاشة الرئيسية
Route<void> irisCurtainRoute(Widget next) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 2300),
    pageBuilder: (_, __, ___) => next,
    transitionsBuilder: (ctx, anim, __, child) {
      final size = MediaQuery.of(ctx).size;
      final wide = size.width >= 700;
      return AnimatedBuilder(
        animation: anim,
        child: child,
        builder: (_, ch) {
          final v = anim.value;
          // 0..0.38 اللوجو يظهر ويكبر، 0.55..1 الستارة تتشال
          final appear =
              Curves.easeOutCubic.transform((v / 0.38).clamp(0.0, 1.0));
          final lift = Curves.easeInOutCubic
              .transform(((v - 0.55) / 0.45).clamp(0.0, 1.0));
          final d = (wide ? 260.0 : 200.0);
          return Stack(fit: StackFit.expand, children: [
            ch!,
            if (v < 1)
              IgnorePointer(
                child: ClipPath(
                  clipper: _CurtainClipper(lift),
                  child: ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Opacity(
                        opacity: appear,
                        child: Transform.scale(
                          scale: 0.7 + 0.3 * appear + 0.08 * lift,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        kIrisAccent.withOpacity(0.28 * appear),
                                    blurRadius: 70),
                              ],
                            ),
                            child: IrisLogo(size: d),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (v < 1 && lift > 0)
              IgnorePointer(
                  child: CustomPaint(painter: _CurtainEdgePainter(lift))),
          ]);
        },
      );
    },
  );
}

// خط الحافة المائلة: بيتحرك من تحت لفوق (lift 0 = الشاشة متغطية كلها)
List<Offset> _curtainLine(Size s, double lift) {
  final slant = s.height * 0.22;
  final base = (1 - lift) * (s.height + slant);
  return [Offset(0, base - slant), Offset(s.width, base)];
}

class _CurtainClipper extends CustomClipper<Path> {
  final double lift;
  const _CurtainClipper(this.lift);
  @override
  Path getClip(Size s) {
    final l = _curtainLine(s, lift);
    return Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width, l[1].dy)
      ..lineTo(0, l[0].dy)
      ..close();
  }

  @override
  bool shouldReclip(covariant _CurtainClipper old) => old.lift != lift;
}

class _CurtainEdgePainter extends CustomPainter {
  final double lift;
  const _CurtainEdgePainter(this.lift);
  @override
  void paint(Canvas canvas, Size s) {
    final l = _curtainLine(s, lift);
    canvas.drawLine(
        l[0],
        l[1],
        Paint()
          ..color = kIrisAccent.withOpacity(0.7)
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawLine(
        l[0],
        l[1],
        Paint()
          ..color = kIrisAccent
          ..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(covariant _CurtainEdgePainter old) => old.lift != lift;
}


// نص بيعدي عليه شعاع لمعان (شيمر) عشان الشاشة تبقى حية
class _ShimmerText extends StatelessWidget {
  final Animation<double> animation;
  final String text;
  final TextStyle style;
  final double phase;
  const _ShimmerText(
      {required this.animation,
      required this.text,
      required this.style,
      this.phase = 0});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = ((animation.value + phase) % 1.0) * 2.6 - 0.8;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => LinearGradient(
            begin: Alignment(-1 + t, 0),
            end: Alignment(-0.2 + t, 0),
            colors: [
              style.color ?? Colors.white,
              const Color(0xFF9DB9CE),
              Colors.white,
              const Color(0xFF9DB9CE),
              style.color ?? Colors.white,
            ],
            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            tileMode: TileMode.clamp,
          ).createShader(r),
          child: Text(text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: style.copyWith(color: Colors.white)),
        );
      },
    );
  }
}
