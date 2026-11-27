import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
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
  )..repeat();

  // متحكم دوران اللوجو والنبض في شاشة التلفزيون
  late final AnimationController _orbitController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

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
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    if (_auth.isAdmin()) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminUI()));
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingUI()));
    }
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

  Future<void> _signInWithFace() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final canCheck = await _biometric.canCheckBiometrics;
      if (!canCheck) {
        _goNext(); // الجهاز مش بيدعم بصمة - نكمل عادي
        return;
      }
      final ok = await _biometric.authenticate(
        localizedReason: 'Scan to sign in to I.R.I.S',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (ok) _goNext();
    } catch (_) {
      // المستخدم لغى أو حصل خطأ - نقفل شاشة المسح بس
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _signInSocial(Future<void> Function() startOAuth) async {
    setState(() => _error = null);
    if (!supabaseConfigured) {
      _goNext(); // وضع تجريبي لحد ما المفاتيح تتضاف
      return;
    }
    await startOAuth();
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
          if (isTv)
            _buildTvLayout(uiScale)
          else if (isWide)
            _buildRainLayout(uiScale, isTv)
          else
            _buildMobile(uiScale),
          if (_scanning) _buildScanningOverlay(uiScale),
        ],
      ),
    );
  }

  // ============ تخطيط التلفزيون: كارت متوهج بجزأين + لوجو بيلف ٣٦٠ درجة بنبض أزرق ============
  // مرجع التصميم: فيديو التلفزيون اللي محمود بعته - البنفسجي بقى أزرق،
  // والدوامة ورا كلمة Welcome اتبدلت بلوجو آيرس بيدور مع نبض أزرق
  Widget _buildTvLayout(double uiScale) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxWidth / 2;
        return Stack(
          fit: StackFit.expand,
          children: [
            // نجوم متلألئة متوهجة بستايل آيرس في الخلفية (بدل المطر)
            AnimatedBuilder(
              animation: _orbitController,
              builder: (context, _) => CustomPaint(
                size: constraints.biggest,
                painter:
                    _TwinkleStarsPainter(progress: _orbitController.value),
              ),
            ),
            // بانيل الترحيب (بيتنقل بين اليمين والشمال)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              left: _showRegister ? 0 : half,
              top: 0,
              width: half,
              height: constraints.maxHeight,
              child: _tvWelcomePanel(uiScale),
            ),
            // الفورم: نص الشاشة بالكامل بخلفية نصف شفافة
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              left: _showRegister ? half : 0,
              top: 0,
              width: half,
              height: constraints.maxHeight,
              child: Container(
                color: const Color(0xFF0B0E14).withOpacity(0.82),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (child, anim) {
                    final curved = CurvedAnimation(
                        parent: anim, curve: Curves.easeInOut);
                    return AnimatedBuilder(
                      animation: curved,
                      builder: (_, c) => ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: (1 - curved.value) * 8,
                          sigmaY: (1 - curved.value) * 8,
                        ),
                        child:
                            Opacity(opacity: curved.value, child: c),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(
                              _showRegister ? 0.15 : -0.15, 0),
                          end: Offset.zero,
                        ).animate(curved),
                        child: child,
                      ),
                    );
                  },
                  child: _showRegister
                      ? _tvRegisterForm(uiScale,
                          key: const ValueKey('tvreg'))
                      : _tvLoginForm(uiScale,
                          key: const ValueKey('tvlogin')),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // بانيل الترحيب في التلفزيون: اللوجو بيلف ٣٦٠ درجة مع نبض أزرق
  Widget _tvWelcomePanel(double uiScale) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            kIrisAccentDeep.withOpacity(0.25),
            const Color(0xFF0B0E14).withOpacity(0.75),
          ],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _orbitController,
          builder: (context, _) {
            final pulse =
                0.5 + 0.5 * sin(_orbitController.value * 2 * pi);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 180 * uiScale / 1.2,
                  height: 180 * uiScale / 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kIrisAccent
                            .withOpacity(0.35 + 0.35 * pulse),
                        blurRadius: 50 + 30 * pulse,
                        spreadRadius: 4 + 6 * pulse,
                      ),
                    ],
                  ),
                  child: RotationTransition(
                    turns: _orbitController,
                    child: ClipOval(
                      child: Image.asset('assets/logo.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
                SizedBox(height: 28 * uiScale / 1.2),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30 * uiScale / 1.2,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color:
                            kIrisAccent.withOpacity(0.6 + 0.4 * pulse),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10 * uiScale / 1.2),
                Text(
                  _showRegister
                      ? 'Already have an account?\nLog in with your email and password.'
                      : 'Sign up here to create your account\nand start your journey with I.R.I.S',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13 * uiScale / 1.2,
                      height: 1.5),
                ),
                SizedBox(height: 22 * uiScale / 1.2),
                SizedBox(
                  width: 170 * uiScale / 1.2,
                  height: 46 * uiScale / 1.2,
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _showRegister = !_showRegister;
                      _error = null;
                    }),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: kIrisAccent, width: 1.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      _showRegister ? 'Login' : 'Sign Up',
                      style: TextStyle(
                          color: kIrisAccent,
                          fontSize: 15 * uiScale / 1.2,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tvLoginForm(double uiScale, {Key? key}) {
    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(
          horizontal: 44 * uiScale / 1.35, vertical: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome Back',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24 * uiScale / 1.2,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Sign in to continue your journey with I.R.I.S',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12 * uiScale / 1.2)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 12)),
            ),
          ],
          SizedBox(height: 16 * uiScale / 1.35),
          _underlineField(
              controller: _email,
              label: 'Email',
              icon: Icons.mail_outline,
              uiScale: uiScale / 1.2),
          SizedBox(height: 14 * uiScale / 1.35),
          _underlineField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: true,
              uiScale: uiScale / 1.2),
          SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _keepSignedIn,
                  onChanged: (v) =>
                      setState(() => _keepSignedIn = v ?? true),
                  activeColor: kIrisAccent,
                  checkColor: Colors.black,
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Remember me',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Text('Forgot password?',
                    style:
                        TextStyle(color: kIrisAccent, fontSize: 12)),
              ),
            ],
          ),
          SizedBox(height: 18 * uiScale / 1.35),
          _glowButton(
              label: 'Login',
              uiScale: uiScale / 1.2,
              onPressed: _busy ? null : _signInWithEmail,
              autofocus: true),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _signInWithFace,
              icon: const Icon(Icons.face_unlock_outlined,
                  color: kIrisAccent, size: 18),
              label: const Text('Face scan',
                  style: TextStyle(color: kIrisAccent, fontSize: 12)),
            ),
          ),
          _orDivider(uiScale / 1.2),
          const SizedBox(height: 10),
          _socialRow(uiScale / 1.2),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('New to I.R.I.S? ',
                  style:
                      TextStyle(color: Colors.white54, fontSize: 12)),
              GestureDetector(
                onTap: () => setState(() {
                  _showRegister = true;
                  _error = null;
                }),
                child: const Text('Create an account',
                    style: TextStyle(
                        color: kIrisAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tvRegisterForm(double uiScale, {Key? key}) {
    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(
          horizontal: 44 * uiScale / 1.35, vertical: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create Account',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24 * uiScale / 1.2,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Join I.R.I.S - your assistant is waiting for you',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12 * uiScale / 1.2)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 12)),
            ),
          ],
          SizedBox(height: 16 * uiScale / 1.35),
          _underlineField(
              controller: _regName,
              label: 'Your Name',
              icon: Icons.badge_outlined,
              uiScale: uiScale / 1.2),
          SizedBox(height: 14 * uiScale / 1.35),
          _underlineField(
              controller: _regEmail,
              label: 'Email',
              icon: Icons.mail_outline,
              uiScale: uiScale / 1.2),
          SizedBox(height: 14 * uiScale / 1.35),
          _underlineField(
              controller: _regPassword,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: true,
              uiScale: uiScale / 1.2),
          SizedBox(height: 20 * uiScale / 1.35),
          _glowButton(
              label: 'Create My Account',
              uiScale: uiScale / 1.2,
              onPressed: _busy ? null : _register),
          const SizedBox(height: 12),
          _socialRow(uiScale / 1.2),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? ',
                  style:
                      TextStyle(color: Colors.white54, fontSize: 12)),
              GestureDetector(
                onTap: () => setState(() {
                  _showRegister = false;
                  _error = null;
                }),
                child: const Text('Login instead',
                    style: TextStyle(
                        color: kIrisAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ تخطيط اللابتوب/التلفزيون: مطر متحرك + فورم أبيض وأسود ============
  Widget _buildRainLayout(double uiScale, bool isTv) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // خلفية المطر المتحركة
        AnimatedBuilder(
          animation: _rainController,
          builder: (context, _) => CustomPaint(
            painter: RainPainter(progress: _rainController.value),
          ),
        ),
        // توهج خفيف في النص
        Center(
          child: Container(
            width: 500 * uiScale,
            height: 500 * uiScale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kIrisAccent.withOpacity(0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // المحتوى: فورم شمال، لوجو/هولوغرام يمين
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(32 * uiScale),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 380 * uiScale),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder: (child, anim) {
                        final curved = CurvedAnimation(
                            parent: anim, curve: Curves.easeInOut);
                        return AnimatedBuilder(
                          animation: curved,
                          builder: (_, c) => ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(
                              sigmaX: (1 - curved.value) * 8,
                              sigmaY: (1 - curved.value) * 8,
                            ),
                            child:
                                Opacity(opacity: curved.value, child: c),
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin:
                                  Offset(_showRegister ? 0.12 : -0.12, 0),
                              end: Offset.zero,
                            ).animate(curved),
                            child: child,
                          ),
                        );
                      },
                      child: _showRegister
                          ? _registerForm(uiScale,
                              key: const ValueKey('reg'))
                          : _loginForm(uiScale,
                              key: const ValueKey('login')),
                    ),
                  ),
                ),
              ),
            ),
            // اللوجو والهولوغرام بدل الرسمة
            Expanded(
              flex: 4,
              child: Center(
                child: AnimatedBuilder(
                  animation: _rainController,
                  builder: (context, _) {
                    final pulse =
                        0.5 + 0.5 * sin(_rainController.value * 2 * pi);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 220 * uiScale,
                          height: 220 * uiScale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kIrisAccent
                                    .withOpacity(0.25 + 0.2 * pulse),
                                blurRadius: 80,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/logo.png',
                                fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(height: 24 * uiScale),
                        Text(
                          'I.R.I.S',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26 * uiScale,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8 * uiScale,
                            shadows: [
                              Shadow(
                                color: kIrisAccent.withOpacity(0.8),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8 * uiScale),
                        Text(
                          'Infinity Retinal Intelligence System',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12 * uiScale,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============ تخطيط الموبايل: عمود واحد ============
  Widget _buildMobile(double uiScale) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipOval(
                child: Image.asset('assets/logo.png',
                    width: 72 * uiScale, height: 72 * uiScale),
              ),
            ),
            SizedBox(height: 20 * uiScale),
            Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28 * uiScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8 * uiScale),
            Text(
              'Sign in to continue to I.R.I.S',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white54, fontSize: 14 * uiScale),
            ),
            SizedBox(height: 28 * uiScale),
            _buildField(
              controller: _email,
              label: 'Email address',
              hint: 'name@yourstore.com',
              obscure: false,
              icon: Icons.mail_outline,
              uiScale: uiScale,
            ),
            SizedBox(height: 16 * uiScale),
            _buildField(
              controller: _password,
              label: 'Password',
              hint: '••••••••',
              obscure: _obscure,
              icon: Icons.lock_outline,
              uiScale: uiScale,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                  size: 20 * uiScale,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            SizedBox(height: 8 * uiScale),
            Row(
              children: [
                SizedBox(
                  width: 24 * uiScale,
                  height: 24 * uiScale,
                  child: Checkbox(
                    value: _keepSignedIn,
                    onChanged: (v) =>
                        setState(() => _keepSignedIn = v ?? true),
                    activeColor: kIrisAccent,
                    checkColor: Colors.black,
                    side: const BorderSide(color: Colors.white38),
                  ),
                ),
                SizedBox(width: 8 * uiScale),
                Text('Keep me signed in',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13 * uiScale)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text('Forgot password?',
                      style: TextStyle(
                          color: kIrisAccent, fontSize: 13 * uiScale)),
                ),
              ],
            ),
            if (_error != null) ...[
              SizedBox(height: 8 * uiScale),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.redAccent, fontSize: 13 * uiScale)),
            ],
            SizedBox(height: 16 * uiScale),
            _primaryButton(
              label: 'Sign in',
              uiScale: uiScale,
              onPressed: _busy ? null : _signInWithEmail,
            ),
            SizedBox(height: 12 * uiScale),
            _faceScanButton(uiScale),
            SizedBox(height: 24 * uiScale),
            _orDivider(uiScale),
            SizedBox(height: 20 * uiScale),
            _socialRow(uiScale),
            SizedBox(height: 24 * uiScale),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ",
                    style: TextStyle(
                        color: Colors.white54, fontSize: 13 * uiScale)),
                GestureDetector(
                  onTap: () {},
                  child: Text('Register here',
                      style: TextStyle(
                          color: kIrisAccent,
                          fontSize: 13 * uiScale,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============ فورم اللابتوب: حواف سفلية أبيض وأسود ============
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
                fontSize: 28 * uiScale,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 32 * uiScale),
        _underlineField(
            controller: _email,
            label: 'Email *',
            icon: Icons.mail_outline,
            uiScale: uiScale),
        SizedBox(height: 20 * uiScale),
        _underlineField(
            controller: _password,
            label: 'Password *',
            icon: Icons.lock_outline,
            obscure: true,
            uiScale: uiScale),
        if (_error != null) ...[
          SizedBox(height: 12 * uiScale),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.redAccent, fontSize: 12 * uiScale)),
        ],
        SizedBox(height: 32 * uiScale),
        _glowButton(
            label: 'Sign In',
            uiScale: uiScale,
            onPressed: _busy ? null : _signInWithEmail,
            autofocus: true),
        SizedBox(height: 12 * uiScale),
        Center(
          child: TextButton.icon(
            onPressed: _signInWithFace,
            icon: Icon(Icons.face_unlock_outlined,
                color: kIrisAccent, size: 20 * uiScale),
            label: Text('Face scan',
                style:
                    TextStyle(color: kIrisAccent, fontSize: 13 * uiScale)),
          ),
        ),
        SizedBox(height: 8 * uiScale),
        _socialRow(uiScale),
        SizedBox(height: 20 * uiScale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Not registered? ',
                style: TextStyle(
                    color: Colors.white54, fontSize: 13 * uiScale)),
            GestureDetector(
              onTap: () => setState(() {
                _showRegister = true;
                _error = null;
              }),
              child: Text('Create',
                  style: TextStyle(
                      color: kIrisAccent,
                      fontSize: 13 * uiScale,
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
                fontSize: 28 * uiScale,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 28 * uiScale),
        _underlineField(
            controller: _regName,
            label: 'Full Name *',
            icon: Icons.badge_outlined,
            uiScale: uiScale),
        SizedBox(height: 16 * uiScale),
        _underlineField(
            controller: _regEmail,
            label: 'Email *',
            icon: Icons.mail_outline,
            uiScale: uiScale),
        SizedBox(height: 16 * uiScale),
        _underlineField(
            controller: _regPassword,
            label: 'Password *',
            icon: Icons.lock_outline,
            obscure: true,
            uiScale: uiScale),
        if (_error != null) ...[
          SizedBox(height: 12 * uiScale),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.redAccent, fontSize: 12 * uiScale)),
        ],
        SizedBox(height: 28 * uiScale),
        _glowButton(
            label: 'Create',
            uiScale: uiScale,
            onPressed: _busy ? null : _register),
        SizedBox(height: 16 * uiScale),
        _socialRow(uiScale),
        SizedBox(height: 20 * uiScale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already registered? ',
                style: TextStyle(
                    color: Colors.white54, fontSize: 13 * uiScale)),
            GestureDetector(
              onTap: () => setState(() {
                _showRegister = false;
                _error = null;
              }),
              child: Text('Sign In',
                  style: TextStyle(
                      color: kIrisAccent,
                      fontSize: 13 * uiScale,
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
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
        icon: Icon(Icons.face_unlock_outlined,
            color: kIrisAccent, size: 22 * uiScale),
        label: Text('Sign in with face scan',
            style: TextStyle(color: kIrisAccent, fontSize: 14 * uiScale)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: kIrisAccent.withOpacity(0.6), width: 1.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
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
              style: TextStyle(
                  color: Colors.white38, fontSize: 12 * uiScale)),
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

  // حقل بحافة سفلية بس (ستايل شاشة اللابتوب)
  Widget _underlineField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double uiScale,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.white, fontSize: 15 * uiScale),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white54, fontSize: 14 * uiScale),
        floatingLabelStyle: TextStyle(color: kIrisAccent),
        prefixIcon:
            Icon(icon, color: Colors.white38, size: 20 * uiScale),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: kIrisAccent, width: 1.6),
        ),
      ),
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
            style: TextStyle(
                color: Colors.white70, fontSize: 13 * uiScale)),
        SizedBox(height: 6 * uiScale),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: Colors.white, fontSize: 15 * uiScale),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon:
                Icon(icon, color: Colors.white38, size: 20 * uiScale),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFF151A1F),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: kIrisAccent, width: 1.4),
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
                style: TextStyle(
                    color: Colors.white70, fontSize: 11 * uiScale)),
          ],
        ),
      ),
    );
  }

  // طبقة المسح بالوجه - مربع متوهج وخط بينزل ويطلع
  Widget _buildScanningOverlay(double uiScale) {
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220 * uiScale,
              height: 220 * uiScale,
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) {
                  return CustomPaint(
                    painter:
                        FaceScanPainter(progress: _scanController.value),
                  );
                },
              ),
            ),
            SizedBox(height: 24 * uiScale),
            Text('Scanning...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * uiScale,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 8 * uiScale),
            Text('Simulated scan - use your device biometrics',
                style: TextStyle(
                    color: Colors.white38, fontSize: 12 * uiScale)),
            SizedBox(height: 24 * uiScale),
            TextButton(
              onPressed: () => setState(() => _scanning = false),
              child: Text('Use password instead',
                  style: TextStyle(
                      color: kIrisAccent, fontSize: 14 * uiScale)),
            ),
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
  final double progress;
  FaceScanPainter({required this.progress});

  static const Color accent = kIrisAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));

    // الإطار المتوهج
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // خط المسح بينزل ويطلع
    final y =
        size.height * (progress < 0.5 ? progress * 2 : 2 - progress * 2);
    final scanPaint = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), scanPaint);

    // شكل وجه مبسط في النص
    final facePaint = Paint()
      ..color = accent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width * 0.22, facePaint);
    canvas.drawCircle(
        c + Offset(-size.width * 0.08, -size.height * 0.04),
        3,
        facePaint..style = PaintingStyle.fill);
    canvas.drawCircle(c + Offset(size.width * 0.08, -size.height * 0.04),
        3, facePaint);
    canvas.drawArc(
      Rect.fromCircle(
          center: c + Offset(0, size.height * 0.05),
          radius: size.width * 0.1),
      0.3,
      2.5,
      false,
      facePaint..style = PaintingStyle.stroke,
    );
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
      final col =
          Color.lerp(Colors.white, const Color(0xFF9DB9CE), s[5])!
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
