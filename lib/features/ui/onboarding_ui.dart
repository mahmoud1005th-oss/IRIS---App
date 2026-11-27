import 'package:flutter/material.dart';
import 'v34_home.dart';
import 'dart:math';
import 'login_page.dart'
    show
        kIrisAccent,
        RetinaNetwork,
        CurvedHeaderPainter,
        IrisLogo,
        SidePanelPainter,
        SidePanelClipper,
        irisCurtainRoute;

// شاشة اللغة والدولة والجنس بعد تسجيل الدخول (V3.3): نفس هوية شاشة الدخول -
// نص أسود فوق بلوجو آيرس بحافة منحنية، وتحته شبكة أعصاب الشبكية المتحركة.
// خفيفة: الخلفية الثابتة مرسومة مرة واحدة والنبضات بس هي اللي بتتحرك، واللغة والدولة
// بيتختاروا من قايمة بحث (ListView.builder) بدل عناصر كتير على الشاشة.
class _Opt {
  final String code, native, english, flag;
  const _Opt(this.code, this.native, this.english, [this.flag = '']);
}

const List<_Opt> kLanguages = [
  _Opt('ar', 'العربية', 'Arabic'),
  _Opt('en', 'English', 'English'),
  _Opt('fr', 'Français', 'French'),
  _Opt('es', 'Español', 'Spanish'),
  _Opt('de', 'Deutsch', 'German'),
  _Opt('tr', 'Türkçe', 'Turkish'),
  _Opt('ur', 'اردو', 'Urdu'),
  _Opt('hi', 'हिन्दी', 'Hindi'),
  _Opt('bn', 'বাংলা', 'Bengali'),
  _Opt('fa', 'فارسی', 'Persian'),
  _Opt('ru', 'Русский', 'Russian'),
  _Opt('pt', 'Português', 'Portuguese'),
  _Opt('it', 'Italiano', 'Italian'),
  _Opt('id', 'Bahasa Indonesia', 'Indonesian'),
  _Opt('zh', '中文', 'Chinese'),
  _Opt('ja', '日本語', 'Japanese'),
  _Opt('ko', '한국어', 'Korean'),
  _Opt('nl', 'Nederlands', 'Dutch'),
];

const List<_Opt> kCountries = [
  _Opt('EG', 'مصر', 'Egypt', '🇪🇬'),
  _Opt('SA', 'السعودية', 'Saudi Arabia', '🇸🇦'),
  _Opt('AE', 'الإمارات', 'United Arab Emirates', '🇦🇪'),
  _Opt('KW', 'الكويت', 'Kuwait', '🇰🇼'),
  _Opt('QA', 'قطر', 'Qatar', '🇶🇦'),
  _Opt('BH', 'البحرين', 'Bahrain', '🇧🇭'),
  _Opt('OM', 'عُمان', 'Oman', '🇴🇲'),
  _Opt('JO', 'الأردن', 'Jordan', '🇯🇴'),
  _Opt('LB', 'لبنان', 'Lebanon', '🇱🇧'),
  _Opt('SY', 'سوريا', 'Syria', '🇸🇾'),
  _Opt('IQ', 'العراق', 'Iraq', '🇮🇶'),
  _Opt('PS', 'فلسطين', 'Palestine', '🇵🇸'),
  _Opt('YE', 'اليمن', 'Yemen', '🇾🇪'),
  _Opt('SD', 'السودان', 'Sudan', '🇸🇩'),
  _Opt('LY', 'ليبيا', 'Libya', '🇱🇾'),
  _Opt('TN', 'تونس', 'Tunisia', '🇹🇳'),
  _Opt('DZ', 'الجزائر', 'Algeria', '🇩🇿'),
  _Opt('MA', 'المغرب', 'Morocco', '🇲🇦'),
  _Opt('TR', 'Türkiye', 'Turkey', '🇹🇷'),
  _Opt('IR', 'ایران', 'Iran', '🇮🇷'),
  _Opt('PK', 'پاکستان', 'Pakistan', '🇵🇰'),
  _Opt('IN', 'भारत', 'India', '🇮🇳'),
  _Opt('BD', 'বাংলাদেশ', 'Bangladesh', '🇧🇩'),
  _Opt('ID', 'Indonesia', 'Indonesia', '🇮🇩'),
  _Opt('US', 'United States', 'United States', '🇺🇸'),
  _Opt('GB', 'United Kingdom', 'United Kingdom', '🇬🇧'),
  _Opt('CA', 'Canada', 'Canada', '🇨🇦'),
  _Opt('FR', 'France', 'France', '🇫🇷'),
  _Opt('DE', 'Deutschland', 'Germany', '🇩🇪'),
  _Opt('ES', 'España', 'Spain', '🇪🇸'),
  _Opt('IT', 'Italia', 'Italy', '🇮🇹'),
  _Opt('NL', 'Nederland', 'Netherlands', '🇳🇱'),
  _Opt('RU', 'Россия', 'Russia', '🇷🇺'),
  _Opt('BR', 'Brasil', 'Brazil', '🇧🇷'),
  _Opt('PT', 'Portugal', 'Portugal', '🇵🇹'),
  _Opt('MX', 'México', 'Mexico', '🇲🇽'),
  _Opt('CN', '中国', 'China', '🇨🇳'),
  _Opt('JP', '日本', 'Japan', '🇯🇵'),
  _Opt('KR', '한국', 'South Korea', '🇰🇷'),
  _Opt('AU', 'Australia', 'Australia', '🇦🇺'),
  _Opt('NG', 'Nigeria', 'Nigeria', '🇳🇬'),
  _Opt('ZA', 'South Africa', 'South Africa', '🇿🇦'),
  _Opt('OTHER', 'دولة أخرى', 'Other', '🌍'),
];

class OnboardingUI extends StatefulWidget {
  const OnboardingUI({super.key});
  @override
  State<OnboardingUI> createState() => _OnboardingUIState();
}

class _OnboardingUIState extends State<OnboardingUI>
    with SingleTickerProviderStateMixin {
  String? gender;
  String language = "ar";
  String? country;
  bool _countryAuto = false; // تم تحديدها تلقائياً

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // قيم مبدئية من لغة ودولة الجهاز لو مدعومين
    final loc = WidgetsBinding.instance.platformDispatcher.locale;
    if (kLanguages.any((l) => l.code == loc.languageCode)) {
      language = loc.languageCode;
    }
    if (kCountries.any((c) => c.code == loc.countryCode)) {
      country = loc.countryCode;
      _countryAuto = true;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool _covering = false;
  String? _msg;

  // البيانات مش كاملة: من غير تبديل بانيلات، بس رسالة
  void _incomplete() {
    final missing = <String>[
      if (country == null) 'الدولة',
      if (gender == null) 'الجنس',
    ].join(' و ');
    setState(() => _msg = 'لسه ما كمّلتش بياناتك، اختار $missing الأول');
  }

  // الزرار: البانيل الأسود يتمدد ويغطي الشاشة، وبعدين ينسحب للناحية التانية
  // (فوق في الموبايل / يمين في اللابتوب والتلفزيون) ويكشف الخطوة اللي بعدها
  Future<void> _goToNextScreen() async {
    if (_covering) return;
    setState(() {
      _msg = null;
      _covering = true;
    });
    await Future.delayed(const Duration(milliseconds: 720));
    if (!mounted) return;
    final next = IrisHome(
        gender: gender,
        language: language,
        country: country == 'OTHER' ? null : country);
    Navigator.pushReplacement(context, irisCurtainRoute(next));
  }

  Future<void> _pick(String title, List<_Opt> items, String? current,
      void Function(String) onPick) async {
    final res = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF080C11),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (_) =>
          _PickerSheet(title: title, items: items, current: current),
    );
    if (res != null) onPick(res);
  }

  Widget _selector(
      {required String label,
      required String value,
      String? flag,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0E141B).withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kIrisAccent.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            if (flag != null && flag.isNotEmpty) ...[
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: kIrisAccent, size: 26),
          ],
        ),
      ),
    );
  }

  Widget _genderTile(String label, IconData icon, String code) {
    final selected = gender == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = code),
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: selected
                ? kIrisAccent.withOpacity(0.16)
                : const Color(0xFF0E141B).withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? kIrisAccent : kIrisAccent.withOpacity(0.2),
                width: selected ? 1.6 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: kIrisAccent.withOpacity(0.3), blurRadius: 14)
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? kIrisAccent : Colors.white54, size: 24),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 2),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                fontWeight: FontWeight.w700)),
      );

  // بطاقة الاختيارات: اللغة والدولة والجنس وزرار ابدأ
  Widget _card() {
    final ready = gender != null && country != null;
    final lang = kLanguages.firstWhere((l) => l.code == language,
        orElse: () => kLanguages.first);
    final ctry = kCountries.where((c) => c.code == country);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF05080C).withOpacity(0.66),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kIrisAccent.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('اللغة  ·  Language'),
          _selector(
              label: 'language',
              value: '${lang.native}  ·  ${lang.english}',
              onTap: () => _pick('اختر اللغة · Language', kLanguages, language,
                  (v) => setState(() => language = v))),
          const SizedBox(height: 16),
          _title('الدولة  ·  Country'),
          _selector(
              label: 'country',
              flag: ctry.isEmpty ? '🌍' : ctry.first.flag,
              value: ctry.isEmpty
                  ? 'اختر دولتك  ·  Choose country'
                  : '${ctry.first.native}  ·  ${ctry.first.english}',
              onTap: () => _pick('اختر دولتك · Country', kCountries, country,
                  (v) => setState(() { country = v; _countryAuto = false; }))),
          if (_countryAuto)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: const [
                Icon(Icons.my_location, size: 14, color: Color(0xFF9DB9CE)),
                SizedBox(width: 6),
                Expanded(child: Text('اتحددت تلقائياً من موقعك · تقدر تغيّرها', style: TextStyle(color: Colors.white54, fontSize: 12))),
              ]),
            ),
          const SizedBox(height: 16),
          _title('الجنس  ·  Gender (لتخصيص الصوت)'),
          Row(children: [
            _genderTile('ذكر', Icons.male, 'male'),
            _genderTile('أنثى', Icons.female, 'female'),
          ]),
          if (_msg != null) ...[
            const SizedBox(height: 14),
            Text(_msg!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: ready ? _goToNextScreen : _incomplete,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
              label: const Text('ابدأ  ·  Start',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kIrisAccent,
                disabledBackgroundColor: kIrisAccent.withOpacity(0.25),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo(double d) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: kIrisAccent.withOpacity(0.2), blurRadius: 36),
          ],
        ),
        child: IrisLogo(size: d),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(builder: (context, c) {
          if (c.maxWidth >= 700) return _wide(c);
          final headerH = (c.maxHeight * 0.34).clamp(230.0, 360.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              RetinaNetwork(animation: _pulse),
              Positioned.fill(
                top: headerH - 4,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: _covering ? 0 : 1,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                        child: _card(),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
                top: 0,
                left: 0,
                right: 0,
                height: _covering ? c.maxHeight + c.maxWidth * 0.30 : headerH,
                child: CustomPaint(
                  painter: const CurvedHeaderPainter(),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: headerH,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 30),
                          child: Column(
                            children: [
                              _logo(92),
                              const Spacer(),
                              const Text('أهلاً بك في I.R.I.S',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              const Text('خلّينا نظبّط آيرس على مقاسك',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 13.5)),
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
        }),
      ),
    );
  }

  // لابتوب/تلفزيون: نص أسود بقوس دايري فيه اللوجو والعنوان، والنص التاني شبكة الأعصاب والبطاقة
  Widget _wide(BoxConstraints c) {
    final W = c.maxWidth, H = c.maxHeight;
    final apex = W * 0.52;
    final sag = min(H * 0.32, W * 0.17);
    final k = (W / 1000).clamp(1.0, 1.7).toDouble();
    return Stack(
      fit: StackFit.expand,
      children: [
        RetinaNetwork(
            animation: _pulse, origin: const Offset(0.5, 0.5), spread: pi),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          left: 0,
          top: 0,
          width: _covering ? W + sag : apex,
          height: H,
          child: CustomPaint(
            painter: SidePanelPainter(bulgeRight: true, sag: sag),
            child: ClipPath(
              clipper: SidePanelClipper(bulgeRight: true, sag: sag),
              child: Padding(
                padding: EdgeInsets.only(right: _covering ? 0 : sag * 0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _logo(150 * k),
                      SizedBox(height: 22 * k),
                      Text('أهلاً بك في I.R.I.S',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26 * k,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 6 * k),
                      Text('خلّينا نظبّط آيرس على مقاسك',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 14.5 * k)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: apex,
          top: 0,
          right: 0,
          height: H,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            opacity: _covering ? 0 : 1,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Transform.scale(
                  scale: 1.0,
                  child: SizedBox(width: 420 * k, child: _card()),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerSheet extends StatefulWidget {
  final String title;
  final List<_Opt> items;
  final String? current;
  const _PickerSheet(
      {required this.title, required this.items, required this.current});
  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.items
        .where((o) =>
            q.isEmpty ||
            o.native.toLowerCase().contains(q) ||
            o.english.toLowerCase().contains(q))
        .toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(widget.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) =>
                        setState(() => q = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'ابحث  ·  Search',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: kIrisAccent),
                      filled: true,
                      fillColor: const Color(0xFF0E141B),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final o = list[i];
                      final sel = o.code == widget.current;
                      return ListTile(
                        onTap: () => Navigator.pop(context, o.code),
                        leading: o.flag.isEmpty
                            ? null
                            : Text(o.flag,
                                style: const TextStyle(fontSize: 24)),
                        title: Text(o.native,
                            style: TextStyle(
                                color: sel ? kIrisAccent : Colors.white,
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(o.english,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                        trailing: sel
                            ? const Icon(Icons.check_circle, color: kIrisAccent)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
