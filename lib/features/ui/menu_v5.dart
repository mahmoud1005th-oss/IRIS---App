import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart' show kIrisAccent, IrisLogo, LoginPage;
import 'v34_home.dart' show IrisHome;
import '../../core/services/auth_service.dart';

// واجهة جانبية جديدة (V3.5): واجهة فقط، مفيش ربط حقيقي.
const Color _bg = Color(0xFF05080C);
const Color _panel = Color(0xFF0B1118);
const Color _card = Color(0xFF111A24);
const Color _gold = Colors.white;

// دايرة الحساب: أول حرف من اسم المستخدم (أو إيميله)، وإلا علامة آيرس
class AccountAvatar extends StatefulWidget {
  final double size;
  final String? name;
  const AccountAvatar({super.key, this.size = 42, this.name});
  @override
  State<AccountAvatar> createState() => _AccountAvatarState();
}

class _AccountAvatarState extends State<AccountAvatar> {
  String _seed = '';
  @override
  void initState() {
    super.initState();
    final a = AuthService();
    _seed = (widget.name ?? a.displayName ?? a.currentEmail ?? '').trim();
    if (_seed.isEmpty) _load();
  }

  // الاسم لو معروف، وإلا الإيميل اللي المستخدم دخل بيه (محفوظ على الموبايل)
  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = (p.getString('iris_user_name') ?? p.getString('iris_user_email') ?? '').trim();
      if (v.isNotEmpty && mounted) setState(() => _seed = v);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    if (_seed.isEmpty) return IrisLogo(size: size);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: kIrisAccent.withOpacity(.18), border: Border.all(color: kIrisAccent.withOpacity(.6))),
      child: Text(_seed.characters.first.toUpperCase(), style: TextStyle(color: kIrisAccent, fontSize: size * .45, fontWeight: FontWeight.w800)),
    );
  }
}

Widget _lbl(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(children: [
        Container(width: 3, height: 12, decoration: BoxDecoration(color: kIrisAccent.withOpacity(.7), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(t, style: const TextStyle(color: Colors.white54, fontSize: 11.5, letterSpacing: .8, fontWeight: FontWeight.w800)),
      ]),
    );

Widget _mrow(IconData ic, String t, {String? sub, String? tag, bool dim = false, VoidCallback? onTap}) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48,
        margin: const EdgeInsets.fromLTRB(10, 1, 10, 1),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Colors.white.withOpacity(dim ? .03 : .06), borderRadius: BorderRadius.circular(10)),
            child: Icon(ic, color: dim ? Colors.white54 : kIrisAccent, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: TextStyle(color: dim ? Colors.white70 : Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
              if (sub != null) Padding(padding: const EdgeInsets.only(top: 1), child: Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11))),
            ]),
          ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.black, border: Border.all(color: _gold), borderRadius: BorderRadius.circular(10)),
              child: Text(tag, style: const TextStyle(color: _gold, fontSize: 10.5, fontWeight: FontWeight.w800)),
            ),
        ]),
      ),
    );

// سقف الاستخدام: كام صورة اتعملت النهارده من الحد المسموح (٧ للمستخدم العادي)
class UsageCap extends StatelessWidget {
  final int used;
  final int limit;
  const UsageCap({super.key, this.used = 3, this.limit = 7});
  @override
  Widget build(BuildContext context) {
    final left = limit - used;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.image_outlined, color: kIrisAccent, size: 18),
          const SizedBox(width: 8),
          const Text('سقف الاستخدام النهارده', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$used من $limit', style: const TextStyle(color: kIrisAccent, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          for (var i = 0; i < limit; i++)
            Expanded(child: Container(height: 6, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: i < used ? kIrisAccent : Colors.white12, borderRadius: BorderRadius.circular(3)))),
        ]),
        const SizedBox(height: 6),
        Text('فاضلك $left صور. بيتجدد كل يوم · الحد العادي $limit صور', style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
      ]),
    );
  }
}

class MenuV5 extends StatelessWidget {
  final void Function(String)? onSelect;
  final bool admin;
  const MenuV5({super.key, this.onSelect, this.admin = false});
  VoidCallback? _t(String s) => onSelect == null ? null : () => onSelect!(s);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          const AccountAvatar(size: 42),
          const SizedBox(width: 10),
          const Text('IRIS', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _t('settings'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: kIrisAccent.withOpacity(.14), borderRadius: BorderRadius.circular(12), border: Border.all(color: kIrisAccent.withOpacity(.5))),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.settings_outlined, color: kIrisAccent, size: 18),
                SizedBox(width: 5),
                Text('الإعدادات', style: TextStyle(color: kIrisAccent, fontSize: 12.5, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
      ),
      const Divider(color: Colors.white12, height: 12),
      _lbl('الإبداع'),
      _mrow(Icons.image_outlined, 'إنشاء صور', onTap: _t('إنشاء صور')),
      _mrow(Icons.movie_creation_outlined, 'إنشاء ريلز', onTap: _t('إنشاء ريلز')),
      _mrow(Icons.campaign_outlined, 'ريلز إعلانات / Promo', tag: 'مدفوع', onTap: _t('ريلز إعلانات / Promo')),
      _mrow(Icons.video_library_outlined, 'ريلز فيديو', sub: 'أطفال · علمي · سوشيال', onTap: _t('ريلز فيديو')),
      _lbl('أدوات'),
      _mrow(Icons.bolt, 'تركيز الطاقة', sub: 'Energy Focus', onTap: _t('تركيز الطاقة')),
      _mrow(Icons.cast_connected, 'وضع الربط', sub: 'اربط التلفزيون بآيرس', onTap: _t('وضع الربط')),
      _mrow(Icons.auto_stories_outlined, 'آيرس نوت بوك', onTap: _t('notebook')),
      _lbl('أوضاع إضافية'),
      _mrow(Icons.travel_explore, 'Deep Search', sub: 'بحث عميق ودقيق', dim: true, onTap: _t('Deep Search')),
      _mrow(Icons.dashboard_customize_outlined, 'Canvas', dim: true, onTap: _t('Canvas')),
      _mrow(Icons.menu_book_outlined, 'وضع الطالب', dim: true, onTap: _t('وضع الطالب')),
      _mrow(Icons.school_outlined, 'التعليم الموجّه', dim: true, onTap: _t('التعليم الموجّه')),
      const SizedBox(height: 8),
      const UsageCap(),
      const Divider(color: Colors.white12, height: 14),
      _mrow(Icons.settings_outlined, 'الإعدادات', onTap: _t('settings')),
      _mrow(Icons.help_outline, 'الحصول على المساعدة', onTap: _t('help')),
      if (admin) _mrow(Icons.admin_panel_settings_outlined, 'لوحة المايسترو', onTap: _t('admin')),
      const SizedBox(height: 10),
    ]);
  }
}

// إيدج سوايب: القائمة بتنزلق من الحافة مع الشاشة بتعتم. progress ٠..١
class SideMenuFrame extends StatelessWidget {
  final double progress;
  const SideMenuFrame({super.key, required this.progress});
  @override
  Widget build(BuildContext context) {
    const w = 318.0;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          Positioned.fill(
            child: Opacity(
              opacity: .5,
              child: Column(children: [
                const SizedBox(height: 70),
                const Center(child: IrisLogo(size: 110)),
              ]),
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(.55 * progress))),
          Positioned(
            top: 0,
            bottom: 0,
            right: -w * (1 - progress),
            width: w,
            child: Container(
              decoration: BoxDecoration(color: _panel, border: Border(left: BorderSide(color: kIrisAccent.withOpacity(.25)))),
              child: SafeArea(child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: const MenuV5())),
            ),
          ),
        ]),
      ),
    );
  }
}

Widget _head(String t, {String? sub}) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(children: [
        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Text(t, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (sub != null) Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );

Widget _srowRaw(IconData ic, String t, {String? val, String? sub, bool pro = false, bool last = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Colors.white10))),
      child: Row(children: [
        Icon(ic, color: kIrisAccent, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(color: Colors.white, fontSize: 14.5)),
            if (sub != null) Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
          ]),
        ),
        if (pro)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(border: Border.all(color: _gold), borderRadius: BorderRadius.circular(8)),
            child: const Text('PRO', style: TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        if (val != null) Text(val, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_left, color: Colors.white30, size: 20),
      ]),
    );

void _notYet(BuildContext c) {
  ScaffoldMessenger.of(c).showSnackBar(const SnackBar(
    content: Directionality(textDirection: TextDirection.rtl, child: Text('ده الشكل بس دلوقتي، هيشتغل لما نوصّل السيرفر')),
    duration: Duration(seconds: 2),
  ));
}

Widget _srow(IconData ic, String t, {String? val, String? sub, bool pro = false, bool last = false, Widget? to}) => Builder(
      builder: (c) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: to == null ? () => _notYet(c) : () => Navigator.of(c).push(MaterialPageRoute(builder: (_) => to)),
        child: _srowRaw(ic, t, val: val, sub: sub, pro: pro, last: last),
      ),
    );

Widget _group(String title, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl(title),
      Container(margin: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Column(children: rows)),
    ]);

class _ThemeChips extends StatefulWidget {
  const _ThemeChips();
  @override
  State<_ThemeChips> createState() => _ThemeChipsState();
}

class _ThemeChipsState extends State<_ThemeChips> {
  int _sel = 2;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Row(children: [
          const Icon(Icons.brightness_6_outlined, color: kIrisAccent, size: 21),
          const SizedBox(width: 12),
          const Text('المظهر', style: TextStyle(color: Colors.white, fontSize: 14.5)),
          const Spacer(),
          for (var i = 0; i < 3; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _sel = i),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _sel == i ? kIrisAccent.withOpacity(.2) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: _sel == i ? kIrisAccent : Colors.white24)),
                child: Text(const ['فاتح', 'داكن', 'تلقائي'][i], style: TextStyle(color: _sel == i ? kIrisAccent : Colors.white60, fontSize: 12)),
              ),
            ),
        ]),
      );
}

class SettingsV5 extends StatelessWidget {
  const SettingsV5({super.key});
  Widget _theme() => const _ThemeChips();
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _head('الإعدادات'),
              Builder(builder: (c) => GestureDetector(
                    onTap: () => Navigator.of(c).push(MaterialPageRoute(builder: (_) => const ProfileV6())),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                      child: Row(children: const [
                        IrisLogo(size: 46),
                        SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('حسابي', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('الاسم والبريد وكلمة السر', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ])),
                        Icon(Icons.chevron_left, color: Colors.white30),
                      ]),
                    ),
                  )),
              _group('الحساب', [
                _srow(Icons.record_voice_over_outlined, 'تغيير الصوت', val: 'ذكر', to: const VoiceV6()),
                _srow(Icons.person_add_alt_outlined, 'إضافة أو إنشاء حساب آخر', sub: 'سجّل دخول بحساب موجود أو اعمل حساب جديد', to: const AddAccountV6()),
                _srow(Icons.devices, 'الأجهزة المتصلة', sub: '٤ أجهزة مرتبطة بحسابك', last: true, to: const DevicesV5()),
              ]),
              _group('آيرس', [
                _srow(Icons.psychology_alt_outlined, 'شخصية آيرس وأسلوب الرد', sub: 'صريح، مختصر، مفصّل', to: const PersonaV6()),
                _srow(Icons.chat_bubble_outline, 'المحادثة', sub: 'حفظ، تصدير، مسح', to: const ChatSettingsV6()),
                _srow(Icons.psychology_outlined, 'ذاكرة آيرس', sub: 'شوف أو امسح اللي فاكره', to: const MemoryV6()),
                _srow(Icons.auto_stories_outlined, 'آيرس نوت بوك', last: true, to: const NotebookV6()),
              ]),
              _group('التطبيق', [
                _srow(Icons.brightness_6_outlined, 'المظهر', val: 'تلقائي', to: const AppearanceV6()),
                _srow(Icons.language, 'اللغة', val: 'العربية', to: const LanguageV6()),
                _srow(Icons.notifications_none, 'الإشعارات', to: const NotificationsV6()),
                _srow(Icons.perm_media_outlined, 'الوسائط', to: const MediaV6()),
                _srow(Icons.apps, 'التطبيقات المرتبطة', to: const LinkedAppsV6()),
                _srow(Icons.devices_other_outlined, 'أدوات التحكم بالجهاز', last: true, to: const DeviceControlsV6()),
              ]),
              _group('الأمان', [
                _srow(Icons.lock_outline, 'الخصوصية والأمان', sub: 'قفل التطبيق بالبصمة', last: true, to: const PrivacyV6()),
              ]),
              Builder(builder: (c) => _btn('تسجيل الخروج', onTap: () async {
                    await AuthService().signOut();
                    if (c.mounted) Navigator.of(c).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
                  })),
              const Padding(padding: EdgeInsets.only(top: 12), child: Center(child: Text('IRIS · الإصدار 3.5', style: TextStyle(color: Colors.white24, fontSize: 11)))),
              const SizedBox(height: 14),
            ]),
          ),
        ),
      ),
    );
  }
}

class HelpV5 extends StatelessWidget {
  const HelpV5({super.key});
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _head('الحصول على المساعدة'),
            _group('المساعدة', [
              _srow(Icons.quiz_outlined, 'الأسئلة الشائعة', sub: 'إجابات سريعة', to: const FaqV6()),
              _srow(Icons.support_agent, 'الدعم', sub: 'كلّم فريق آيرس', to: const SupportV6()),
              _srow(Icons.flag_outlined, 'إبلاغ عن مشكلة', sub: 'ابعت وصف أو صورة للمشكلة', to: const ReportV6()),
              _srow(Icons.lightbulb_outline, 'اقترح ميزة', sub: 'فكرة توصل للمطوّر', to: const IdeaV6()),
              _srow(Icons.info_outline, 'لمحة عن التطبيق ومن نحن', to: const AboutV6()),
              _srow(Icons.system_update_alt, 'التحديثات', val: 'الإصدار 3.5', last: true, to: const UpdatesV6()),
            ]),
            const Spacer(),
            const Center(child: IrisLogo(size: 64)),
            const SizedBox(height: 6),
            const Center(child: Text('Infinity Retinal Intelligence System', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1))),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// Deep Search: بيتفعل من القائمة وبيفضل في نفس صفحة الشات، والبحث يبقى على النقطة المحددة بتفاصيلها
class DeepSearchFrame extends StatelessWidget {
  const DeepSearchFrame({super.key});
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(children: const [Icon(Icons.menu, color: Colors.white70), SizedBox(width: 12), IrisLogo(size: 30), SizedBox(width: 7), Text('IRIS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3))]),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(color: kIrisAccent.withOpacity(.22), borderRadius: BorderRadius.circular(18), border: Border.all(color: kIrisAccent.withOpacity(.5))),
                    child: const Text('أسعار كروت الشاشة RTX 5070 في مصر', style: TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: kIrisAccent.withOpacity(.4))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: const [
                      Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.travel_explore, color: kIrisAccent, size: 18), SizedBox(width: 6), Text('Deep Search مفعّل', style: TextStyle(color: kIrisAccent, fontWeight: FontWeight.w800, fontSize: 13))]),
                      SizedBox(height: 8),
                      Text('بدور على النقطة دي بالظبط، في أكتر من مصدر', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                      SizedBox(height: 6),
                      Text('١  فتح المتصفح وجمع المصادر', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                      Text('٢  قراءة التفاصيل ومقارنة الأرقام', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                      Text('٣  تجهيز إجابة دقيقة بالتفاصيل', style: TextStyle(color: Colors.white38, fontSize: 12.5)),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Text('عرض الشكل بس: مفيش بحث حقيقي لسه', style: TextStyle(color: Colors.white38, fontSize: 11.5))),
              ]),
            ),
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white12)),
              child: Row(children: [
                const Icon(Icons.travel_explore, color: kIrisAccent, size: 20),
                const SizedBox(width: 8),
                const Text('Deep Search', style: TextStyle(color: kIrisAccent, fontSize: 13, fontWeight: FontWeight.w800)),
                const Spacer(),
                const Text('اكتب هنا...', style: TextStyle(color: Colors.white38)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}


class DevicesV5 extends StatelessWidget {
  const DevicesV5({super.key});
  Widget _dev(IconData ic, String name, String sub, bool on, {bool me = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
        child: Row(children: [
          Icon(ic, color: kIrisAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(me ? '$name (الجهاز ده)' : name, style: const TextStyle(color: Colors.white, fontSize: 14.5)),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? const Color(0xFF6FCF97) : Colors.white24)),
          const SizedBox(width: 6),
          Text(on ? 'متصل' : 'غير متصل', style: TextStyle(color: on ? Colors.white70 : Colors.white38, fontSize: 11.5)),
        ]),
      );
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _head('الأجهزة المتصلة'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
                child: Column(children: [
                  _dev(Icons.smartphone, 'موبايل محمود', 'Android · آخر نشاط دلوقتي', true, me: true),
                  _dev(Icons.tv, 'TV IRIS', 'غرفة المعيشة · آخر نشاط من ٥ دقايق', true),
                  _dev(Icons.laptop_mac, 'لابتوب', 'آخر نشاط إمبارح', false),
                  _dev(Icons.desktop_windows_outlined, 'كمبيوتر', 'آخر نشاط من ٣ أيام', false),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(children: const [Icon(Icons.add_link, color: kIrisAccent, size: 20), SizedBox(width: 8), Text('ربط جهاز جديد', style: TextStyle(color: kIrisAccent, fontWeight: FontWeight.w700))]),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Text('اضغط على جهاز لفصله أو تغيير اسمه.', style: TextStyle(color: Colors.white38, fontSize: 11.5)),
              ),
              const Spacer(),
              const Padding(padding: EdgeInsets.all(14), child: Center(child: Text('أمثلة للشكل بس: الأجهزة الحقيقية لسه مش بتتسجل', style: TextStyle(color: Colors.white30, fontSize: 11)))),
            ]),
          ),
        ),
      );
}

class AdminV5 extends StatelessWidget {
  const AdminV5({super.key});
  Widget _req(IconData ic, String kind, String who, String text, String time, {bool isNew = false}) => Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: isNew ? kIrisAccent.withOpacity(.6) : Colors.white12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ic, color: kIrisAccent, size: 18),
            const SizedBox(width: 8),
            Text(kind, style: const TextStyle(color: kIrisAccent, fontSize: 12, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (isNew) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Text('جديد', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900))),
            const SizedBox(width: 6),
            Text(time, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 4),
          Text(who, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      );
  Widget _chip(String t, bool on) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: on ? kIrisAccent.withOpacity(.2) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: on ? kIrisAccent : Colors.white24)),
        child: Text(t, style: TextStyle(color: on ? kIrisAccent : Colors.white60, fontSize: 12)),
      );
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _head('لوحة المايسترو', sub: 'ظاهرة لحسابك أنت بس'),
              Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 10), child: Row(children: [_chip('الكل', true), _chip('أفكار للمطوّر', false), _chip('دعم', false), _chip('مشاكل', false)])),
              _req(Icons.lightbulb_outline, 'فكرة للمطوّر', 'مستخدم #1042', 'سأل آيرس: "ليه مش بتعرف تعمل ملف APK؟" وآيرس قال هبلّغ المطوّر.', 'من ٣ د', isNew: true),
              _req(Icons.support_agent, 'طلب دعم', 'مستخدم #0877', 'الصوت بيقطع وأنا بسمع رد آيرس.', 'من ساعة', isNew: true),
              _req(Icons.flag_outlined, 'إبلاغ عن مشكلة', 'مستخدم #0531', 'الصورة مابتتحملش، مرفق لقطة شاشة.', 'إمبارح'),
              _req(Icons.lightbulb_outline, 'فكرة للمطوّر', 'مستخدم #0390', 'سأل: "ينفع تتكلم بصوت راجل؟" آيرس قال هبلّغ المطوّر.', 'من يومين'),
              _group('أدوات المايسترو', [
                _srow(Icons.people_outline, 'إدارة المستخدمين', sub: 'ترقية لـ Pro أو حظر'),
                _srow(Icons.attach_money, 'إدارة التسعير', sub: 'أسعار الباقات'),
                _srow(Icons.key, 'مفاتيح API', sub: 'OpenRouter / Replicate'),
                _srow(Icons.analytics_outlined, 'الإحصائيات', sub: 'الصور والفيديوهات المولّدة', last: true),
              ]),
              Builder(builder: (c) => GestureDetector(onTap: () => Navigator.of(c).push(MaterialPageRoute(builder: (_) => const IrisHome())), child: _btn('افتح آيرس العادي'))),
              const SizedBox(height: 10),
              const Padding(padding: EdgeInsets.all(14), child: Center(child: Text('أمثلة للشكل بس: لسه مفيش استقبال حقيقي للطلبات', style: TextStyle(color: Colors.white30, fontSize: 11)))),
            ])),
          ),
        ),
      );
}

// ---------- شاشات فرعية (شكل فقط، الخدمة وراها لسه مش شغالة) ----------
Widget _tog(IconData ic, String t, bool on, {String? sub}) => _TogW(ic, t, on, sub);

class _TogW extends StatefulWidget {
  final IconData ic;
  final String t;
  final bool on;
  final String? sub;
  const _TogW(this.ic, this.t, this.on, this.sub);
  @override
  State<_TogW> createState() => _TogWState();
}

class _TogWState extends State<_TogW> {
  late bool _on = widget.on;
  String get _key => widget.t == 'قفل التطبيق بالبصمة' ? 'fingerprint_enabled' : 'tog_${widget.t}';
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool(_key);
      if (v != null && mounted) setState(() => _on = v);
    }).catchError((_) {});
  }

  Future<void> _flip() async {
    setState(() => _on = !_on);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key, _on);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final on = _on;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _flip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
        child: Row(children: [
          Icon(widget.ic, color: kIrisAccent, size: 21),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.t, style: const TextStyle(color: Colors.white, fontSize: 14.5)),
            if (widget.sub != null) Text(widget.sub!, style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 44, height: 24, padding: const EdgeInsets.all(3),
            alignment: on ? Alignment.centerLeft : Alignment.centerRight,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: on ? kIrisAccent : Colors.white12),
            child: Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? Colors.black : Colors.white54)),
          ),
        ]),
      ),
    );
  }
}

Widget _slide(String t, double v, String end) => _SlideW(t, v, end);

class _SlideW extends StatefulWidget {
  final String t, end;
  final double v;
  const _SlideW(this.t, this.v, this.end);
  @override
  State<_SlideW> createState() => _SlideWState();
}

class _SlideWState extends State<_SlideW> {
  late double _v = widget.v;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Column(children: [
          Row(children: [Text(widget.t, style: const TextStyle(color: Colors.white, fontSize: 14)), const Spacer(), Text(widget.end, style: const TextStyle(color: Colors.white54, fontSize: 12))]),
          Slider(value: _v, onChanged: (x) => setState(() => _v = x), activeColor: kIrisAccent, inactiveColor: Colors.white12),
        ]),
      );
}

Widget _pill(String t, bool on, {VoidCallback? onTap}) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: on ? kIrisAccent.withOpacity(.2) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: on ? kIrisAccent : Colors.white24)),
      child: Text(t, style: TextStyle(color: on ? kIrisAccent : Colors.white60, fontSize: 12.5)),
    ));

Widget _pills(String t, List<String> o, int sel) => _PillsW(t, o, sel);

class _PillsW extends StatefulWidget {
  final String t;
  final List<String> o;
  final int sel;
  const _PillsW(this.t, this.o, this.sel);
  @override
  State<_PillsW> createState() => _PillsWState();
}

class _PillsWState extends State<_PillsW> {
  late int _sel = widget.sel;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.t, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(runSpacing: 6, children: [for (var i = 0; i < widget.o.length; i++) _pill(widget.o[i], i == _sel, onTap: () => setState(() => _sel = i))]),
        ]),
      );
}

Widget _tag(String t) => Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
      child: Text(t, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    );

Widget _off(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(children: [const Icon(Icons.info_outline, color: Colors.white24, size: 15), const SizedBox(width: 6), Expanded(child: Text(t, style: const TextStyle(color: Colors.white30, fontSize: 11)))]),
    );

Widget _btn(String t, {bool danger = false, VoidCallback? onTap}) => Builder(builder: (c) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap ?? () => _notYet(c), child: Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: danger ? const Color(0xFFE57373) : Colors.white54)),
      child: Text(t, style: TextStyle(color: danger ? const Color(0xFFE57373) : Colors.white, fontWeight: FontWeight.w700)),
    )));

Widget _subScreen(String title, List<Widget> body, {String off = 'الخدمة دي لسه مش مفعّلة، الشكل بس.'}) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_head(title), ...body, _off(off)]))),
      ),
    );

class AppearanceV6 extends StatelessWidget {
  const AppearanceV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('المظهر', [
        _group('الثيم', [_pills('وضع الألوان', ['فاتح', 'داكن', 'تلقائي (حسب الجهاز)'], 2)]),
        _group('اللون المميز', [Padding(padding: const EdgeInsets.all(14), child: Row(children: [for (final x in [0xFF9DB9CE, 0xFF7FB8A4, 0xFFB79DCE, 0xFFCE9D9D, 0xFFFFFFFF]) Container(margin: const EdgeInsets.only(left: 12), width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(x), border: Border.all(color: x == 0xFF9DB9CE ? Colors.white : Colors.transparent, width: 2)))]))]),
        _group('النص', [_slide('حجم الخط', .5, 'متوسط'), _tog(Icons.animation, 'تقليل الحركة', false, sub: 'يوقف الأنيميشن')]),
      ], off: 'الثيم الفاتح والألوان لسه محتاجين تصميم وتوصيل. الشكل بس.');
}

class NotificationsV6 extends StatelessWidget {
  const NotificationsV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('الإشعارات', [
        _group('عام', [_tog(Icons.notifications_active_outlined, 'تفعيل الإشعارات', true), _tog(Icons.vibration, 'اهتزاز', true), _tog(Icons.volume_up_outlined, 'صوت الإشعار', false)]),
        _group('النوع', [_tog(Icons.chat_bubble_outline, 'ردود آيرس', true), _tog(Icons.movie_outlined, 'اكتمال الصور والريلز', true), _tog(Icons.alarm, 'تذكيرات آيرس بالمهام', true, sub: 'آيرس يفكّرك باللي قلت إنك هتعمله'), _tog(Icons.system_update_alt, 'التحديثات', false)]),
        _group('وقت الهدوء', [_tog(Icons.bedtime_outlined, 'عدم الإزعاج', false, sub: 'من ١٢ بالليل لـ ٧ الصبح')]),
      ], off: 'الإشعارات الحقيقية محتاجة خدمة إشعارات (لسه). الشكل بس.');
}

class VoiceV6 extends StatelessWidget {
  const VoiceV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('تغيير الصوت', [
        _group('الصوت', [_pills('نوع الصوت', ['ذكر', 'أنثى'], 0)]),
        _group('اختيار الصوت', [_srow(Icons.graphic_eq, 'صوت عصبي طبيعي (سيرفر)', sub: 'ذكر / أنثى بصوتين مختلفين', val: 'قريباً'), _srow(Icons.phone_android, 'صوت الجهاز (احتياطي)', sub: 'من أصوات موبايلك العربية', last: true)]),
        _group('الضبط', [_slide('السرعة', .45, 'عادي'), _slide('النبرة', .5, 'عادي')]),
        _btn('جرّب الصوت'),
      ], off: 'الصوت العصبي محتاج سيرفر، لسه مش شغال. صوت الجهاز شغال.');
}

class MediaV6 extends StatelessWidget {
  const MediaV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('الوسائط', [
        _group('الصور والريلز', [_pills('جودة الصور', ['عادية', 'عالية'], 0), _tog(Icons.save_alt, 'حفظ الصور تلقائياً في المعرض', false), _tog(Icons.wifi, 'التحميل على الواي فاي بس', true, sub: 'يوفر داتا الموبايل')]),
        _group('التخزين', [_srow(Icons.folder_outlined, 'المساحة المستخدمة', val: '٤٨ ميجا'), _srow(Icons.cleaning_services_outlined, 'مسح الملفات المؤقتة', last: true)]),
      ], off: 'التخزين والجودة لسه مش موصلين. الشكل بس.');
}

class PrivacyV6 extends StatelessWidget {
  const PrivacyV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('الخصوصية والأمان', [
        _group('القفل', [_tog(Icons.fingerprint, 'قفل التطبيق بالبصمة', true), _tog(Icons.visibility_off_outlined, 'إخفاء المعاينة في المهام الأخيرة', false)]),
        _group('بياناتك', [_tog(Icons.cloud_sync_outlined, 'مزامنة الذاكرة الأساسية بين الأجهزة', true), _srow(Icons.download_outlined, 'تصدير محادثاتي'), _srow(Icons.policy_outlined, 'سياسة الخصوصية'), _srow(Icons.description_outlined, 'الشروط والأحكام', last: true)]),
        _btn('مسح كل المحادثات', danger: true),
        _btn('حذف حسابي', danger: true),
      ], off: 'البصمة شغالة. المزامنة والتصدير والحذف محتاجين سوبابيس.');
}

class LinkedAppsV6 extends StatelessWidget {
  const LinkedAppsV6({super.key});
  Widget _app(IconData ic, String n, String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
        child: Row(children: [Icon(ic, color: kIrisAccent, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n, style: const TextStyle(color: Colors.white, fontSize: 14.5)), Text(s, style: const TextStyle(color: Colors.white38, fontSize: 10.5))])), _pill('ربط', false)]),
      );
  @override
  Widget build(BuildContext c) => _subScreen('التطبيقات المرتبطة', [
        _group('خدمات تقدر تربطها', [_app(Icons.mail_outline, 'Gmail', 'آيرس يقرا ويلخّص إيميلاتك'), _app(Icons.calendar_month_outlined, 'Google Calendar', 'مواعيدك وتذكيراتها'), _app(Icons.folder_open, 'Google Drive', 'ملفاتك ومستنداتك'), _app(Icons.chat_outlined, 'WhatsApp', 'ردود ورسائل'), _app(Icons.code, 'GitHub', 'مشاريعك')]),
      ], off: 'مفيش أي ربط شغال لسه. كل واحد يحتاج إذن منك لما يتفعّل.');
}

class MemoryV6 extends StatelessWidget {
  const MemoryV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('ذاكرة آيرس', [
        _group('أنواع الذاكرة', [_srow(Icons.hub_outlined, 'الذاكرة الأساسية', sub: 'مشتركة بين كل أجهزتك', val: '١٢ عنصر'), _srow(Icons.phone_android, 'ذاكرة المحادثة', sub: 'على الجهاز ده بس', val: '٣٨ عنصر', last: true)]),
        _group('اللي آيرس فاكره عنك', [_srow(Icons.person_outline, 'بتتكلم مصري وبتحب الصور أكتر من الكلام'), _srow(Icons.flag_outlined, 'مشروعك: تطبيق IRIS'), _srow(Icons.schedule, 'بتشتغل من الموبايل', last: true)]),
        _group('تحكم', [_tog(Icons.psychology_outlined, 'تفعيل الذاكرة', true)]),
        _btn('مسح ذاكرة الجهاز ده', danger: true),
      ], off: 'أمثلة للشكل بس: الذاكرة الحقيقية لسه مش شغالة.');
}

class DeviceControlsV6 extends StatelessWidget {
  const DeviceControlsV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('أدوات التحكم بالجهاز', [
        _group('على الموبايل ده', [_tog(Icons.mic_none, 'استخدام الميكروفون', true), _tog(Icons.camera_alt_outlined, 'استخدام الكاميرا', true), _tog(Icons.my_location, 'الموقع', false), _tog(Icons.layers_outlined, 'العرض فوق التطبيقات', false, sub: 'للمساعد العائم')]),
        _group('الأوامر الصوتية', [_tog(Icons.record_voice_over_outlined, 'الاستماع لكلمة "IRIS"', false, sub: 'الاسم الصوتي على الموبايل'), _tog(Icons.tv, 'الاستماع لـ "TV IRIS" على التلفزيون', false)]),
      ], off: 'الصلاحيات بتتطلب من نظام الأندرويد وقت الاستخدام. الاستماع بالاسم لسه مش شغال.');
}


Widget _field(String hint, {bool tall = false, IconData? ic}) => Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      constraints: BoxConstraints(minHeight: tall ? 110 : 46),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
      child: Row(crossAxisAlignment: tall ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
        if (ic != null) Padding(padding: EdgeInsets.only(top: tall ? 14 : 0), child: Icon(ic, color: Colors.white38, size: 19)),
        if (ic != null) const SizedBox(width: 10),
        Expanded(
          child: TextField(
            maxLines: tall ? 5 : 1,
            minLines: tall ? 4 : 1,
            obscureText: hint.contains('كلمة السر'),
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 13.5), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ]),
    );

Widget _fill(String t) => Builder(builder: (c) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _notYet(c), child: Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kIrisAccent, borderRadius: BorderRadius.circular(14)),
      child: Text(t, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14.5)),
    )));

class AddAccountV6 extends StatefulWidget {
  const AddAccountV6({super.key});
  @override
  State<AddAccountV6> createState() => _AddAccountV6State();
}

class _AddAccountV6State extends State<AddAccountV6> {
  bool _login = true;
  @override
  Widget build(BuildContext c) => _subScreen('إضافة أو إنشاء حساب', [
        Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 0), child: Row(children: [_pill('تسجيل دخول', _login, onTap: () => setState(() => _login = true)), _pill('حساب جديد', !_login, onTap: () => setState(() => _login = false))])),
        _field('البريد الإلكتروني', ic: Icons.mail_outline),
        _field('كلمة السر', ic: Icons.lock_outline),
        if (!_login) _field('الاسم', ic: Icons.badge_outlined),
        _fill(_login ? 'متابعة' : 'إنشاء الحساب'),
        _lbl('أو'),
        _group('', [
          _srow(Icons.g_mobiledata, 'المتابعة بحساب جوجل'),
          _srow(Icons.window, 'المتابعة بحساب مايكروسوفت'),
          _srow(Icons.code, 'المتابعة بحساب GitHub'),
          _srow(Icons.apple, 'المتابعة بحساب أبل', last: true),
        ]),
        _lbl('حساباتك'),
        _group('', [_srow(Icons.person_outline, 'الحساب الحالي', sub: 'مسجّل دخول', last: true)]),
      ], off: 'تعدد الحسابات محتاج سوبابيس. تسجيل الدخول الحالي هو اللي شغال.');
}

class NotebookV6 extends StatelessWidget {
  const NotebookV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('آيرس نوت بوك', [
        _field('ابحث في دفاترك', ic: Icons.search),
        _group('دفاترك', [
          _srow(Icons.book_outlined, 'أفكار التطبيق', sub: '١٢ ملاحظة · آخر تعديل النهارده'),
          _srow(Icons.book_outlined, 'مذاكرة', sub: '٧ ملاحظات'),
          _srow(Icons.mic_none, 'ملاحظات صوتية', sub: '٥ تسجيلات مع نص مكتوب', last: true),
        ]),
        _fill('دفتر جديد'),
      ], off: 'أمثلة للشكل بس: الدفاتر الحقيقية لسه مش مفعّلة.');
}

class SupportV6 extends StatelessWidget {
  const SupportV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('الدعم', [
        _group('أسئلة شائعة', [
          _srow(Icons.help_outline, 'إزاي أغيّر صوت آيرس؟'),
          _srow(Icons.help_outline, 'ليه مش قادر أعمل صور أكتر؟', sub: 'سقف الاستخدام اليومي'),
          _srow(Icons.help_outline, 'إزاي أربط التلفزيون؟', last: true),
        ]),
        _lbl('كلّم الفريق'),
        _field('اكتب رسالتك هنا', tall: true),
        _fill('إرسال'),
      ], off: 'الرسالة هتوصل للوحة المايسترو لما سوبابيس يتوصل. دلوقتي الشكل بس.');
}

class ReportV6 extends StatelessWidget {
  const ReportV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('إبلاغ عن مشكلة', [
        _group('', [_pills('نوع المشكلة', ['الصوت', 'الصور', 'الدخول', 'الشات', 'حاجة تانية'], 0)]),
        _field('اوصف اللي حصل', tall: true),
        _btn('إرفاق لقطة شاشة'),
        _tog(Icons.phonelink_setup, 'إرسال معلومات الجهاز مع البلاغ', true, sub: 'الموديل والإصدار فقط، بدون محادثاتك'),
        _fill('إرسال البلاغ'),
      ], off: 'البلاغ هيوصل للوحة المايسترو لما سوبابيس يتوصل. دلوقتي الشكل بس.');
}

class AboutV6 extends StatelessWidget {
  const AboutV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('لمحة عن التطبيق', [
        const SizedBox(height: 16),
        const Center(child: IrisLogo(size: 90)),
        const SizedBox(height: 10),
        const Center(child: Text('IRIS', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 5))),
        const Center(child: Text('Infinity Retinal Intelligence System', style: TextStyle(color: Colors.white38, fontSize: 11.5))),
        const SizedBox(height: 6),
        const Center(child: Text('الإصدار 3.5', style: TextStyle(color: kIrisAccent, fontSize: 13))),
        _group('من نحن', [_srow(Icons.person_outline, 'محمود محمد', sub: 'مطوّر بيبني تطبيق ينافس المساعدين الكبار'), _srow(Icons.policy_outlined, 'سياسة الخصوصية'), _srow(Icons.description_outlined, 'الشروط والأحكام'), _srow(Icons.code, 'التراخيص المفتوحة', last: true)]),
      ], off: 'نصوص السياسة والشروط لسه هتتكتب.');
}

class UpdatesV6 extends StatelessWidget {
  const UpdatesV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('التحديثات', [
        _group('الإصدار الحالي', [_srow(Icons.verified_outlined, 'الإصدار 3.5', sub: 'النسخة اللي عندك', last: true)]),
        _btn('افحص وجود تحديث'),
        _group('الجديد', [
          _srow(Icons.menu, 'قائمة جانبية بالسحب من الحافة'),
          _srow(Icons.settings_outlined, 'إعدادات ومساعدة وسقف الاستخدام'),
          _srow(Icons.volume_up_outlined, 'سماعة لقراءة الرد بصوت', last: true),
        ]),
        _tog(Icons.notifications_none, 'نبّهني بالتحديثات الجديدة', true),
      ], off: 'فحص التحديث الحقيقي لسه مش شغال. الجديد المكتوب هو اللي في النسخة دي.');
}

class LanguageV6 extends StatelessWidget {
  const LanguageV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('اللغة', [
        _group('لغة التطبيق', [_pills('اللغة', ['العربية', 'English'], 0)]),
        _group('لهجة آيرس', [_pills('بيرد عليك بـ', ['مصري', 'فصحى بسيطة', 'English'], 0)]),
      ], off: 'تغيير اللغة لسه مش شغال، التطبيق عربي مصري.');
}

// فتح عناصر القائمة الجديدة من الشاشة الرئيسية
Widget? v5PageFor(String key) {
  switch (key) {
    case 'settings':
      return const SettingsV5();
    case 'help':
      return const HelpV5();
    case 'admin':
      return const AdminV5();
    case 'notebook':
      return const NotebookV6();
  }
  return null;
}


class ProfileV6 extends StatelessWidget {
  const ProfileV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('حسابي', [
        const SizedBox(height: 10),
        const Center(child: AccountAvatar(size: 80)),
        _field('الاسم', ic: Icons.badge_outlined),
        _field('البريد الإلكتروني', ic: Icons.mail_outline),
        _group('', [_srow(Icons.password, 'تغيير كلمة السر'), _srow(Icons.verified_user_outlined, 'الدخول بخطوتين', val: 'قريباً', last: true)]),
        _fill('حفظ'),
      ], off: 'تعديل البيانات محتاج سوبابيس. الشكل بس.');
}

class PersonaV6 extends StatelessWidget {
  const PersonaV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('شخصية آيرس وأسلوب الرد', [
        _group('الأسلوب', [_pills('آيرس يكلمك بـ', ['صريح وحازم', 'لطيف', 'مختصر وعملي'], 0)]),
        _group('طول الرد', [_pills('الرد يكون', ['مختصر', 'متوسط', 'مفصّل'], 1)]),
        _group('سلوك', [_tog(Icons.alarm, 'يفكّرني باللي قلت إني هعمله', true), _tog(Icons.record_voice_over_outlined, 'يقرا الرد بصوت تلقائياً', false), _tog(Icons.fact_check_outlined, 'يسألني قبل ما يبعت أي رسالة باسمي', true, sub: 'أمان: مفيش رسالة بتتبعت من غير موافقتك')]),
      ], off: 'الشخصية الحقيقية بتتحكم فيها خدمة الذكاء الاصطناعي اللي لسه مش متوصلة. الشكل بس.');
}

class ChatSettingsV6 extends StatelessWidget {
  const ChatSettingsV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('المحادثة', [
        _group('الحفظ', [_tog(Icons.save_outlined, 'حفظ المحادثة على الموبايل', true, sub: 'شغّال دلوقتي'), _tog(Icons.cloud_upload_outlined, 'نسخة احتياطية على السحابة', false)]),
        _group('الإدخال', [_tog(Icons.keyboard_return, 'الإرسال بزر Enter', false), _tog(Icons.closed_caption_outlined, 'CC تلقائي للملاحظات الصوتية', false, sub: 'نص مكتوب وترجمة تحت التسجيل')]),
        _group('بياناتك', [_srow(Icons.download_outlined, 'تصدير المحادثة'), _srow(Icons.search, 'بحث في المحادثة', last: true)]),
        _btn('مسح المحادثة', danger: true),
      ], off: 'الحفظ على الموبايل شغال. السحابة والتصدير والترجمة لسه.');
}

class FaqV6 extends StatelessWidget {
  const FaqV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('الأسئلة الشائعة', [
        _group('', [
          _srow(Icons.help_outline, 'إزاي أغيّر صوت آيرس؟', sub: 'الإعدادات > تغيير الصوت'),
          _srow(Icons.help_outline, 'ليه فيه حد للصور اليومية؟', sub: 'عشان نحافظ على الخدمة للكل'),
          _srow(Icons.help_outline, 'إزاي أربط التلفزيون؟', sub: 'القائمة > وضع الربط'),
          _srow(Icons.help_outline, 'بياناتي محفوظة فين؟', sub: 'المحادثة على موبايلك'),
          _srow(Icons.help_outline, 'إزاي أمسح ذاكرة آيرس؟', last: true, sub: 'الإعدادات > ذاكرة آيرس'),
        ]),
      ], off: 'الإجابات دي لسه هتتكتب بالكامل.');
}

class IdeaV6 extends StatelessWidget {
  const IdeaV6({super.key});
  @override
  Widget build(BuildContext c) => _subScreen('اقترح ميزة', [
        _field('عايز التطبيق يعمل إيه؟', tall: true),
        _fill('ابعت للمطوّر'),
      ], off: 'الفكرة هتظهر في لوحة المايسترو لما سوبابيس يتوصل. الشكل بس.');
}
