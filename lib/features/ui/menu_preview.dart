import 'package:flutter/material.dart';
import 'login_page.dart' show kIrisAccent, IrisLogo;

// معاينة تصميم فقط (V3.5): القائمة الجانبية + تركيز الطاقة + التطبيقات المتصلة، موبايل ولابتوب.
const Color _bg = Color(0xFF05080C);
const Color _panel = Color(0xFF0B1118);
const Color _card2 = Color(0xFF111A24);

class _Item {
  final IconData icon;
  final String t;
  final String? sub;
  final bool sel;
  final bool group;
  final bool child;
  final String? tag;
  const _Item(this.icon, this.t, {this.sub, this.sel = false, this.group = false, this.child = false, this.tag});
}

class MenuList extends StatelessWidget {
  final bool compact;
  final String selected;
  final void Function(String title)? onSelect;
  const MenuList({super.key, this.compact = false, this.selected = '', this.onSelect});

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
        child: Text(t, style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      );

  Widget _row(_Item it) {
    final sel = it.t.contains(selected) && selected.isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect == null ? null : () => onSelect!(it.t),
      child: Container(
      height: compact ? 38 : 46,
      margin: EdgeInsets.fromLTRB(it.child ? 34 : 10, 1, 10, 1),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: sel ? kIrisAccent.withOpacity(0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: sel ? Border.all(color: kIrisAccent.withOpacity(0.5)) : null,
      ),
      child: Row(children: [
        Icon(it.icon, color: sel ? kIrisAccent : Colors.white70, size: it.child ? 19 : 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.t, style: TextStyle(color: sel ? Colors.white : Colors.white, fontSize: it.child ? 13.5 : 15, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
            if (it.sub != null && !compact) Text(it.sub!, style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
          ]),
        ),
        if (it.tag != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFFFC857).withOpacity(.16), border: Border.all(color: const Color(0xFFFFC857)), borderRadius: BorderRadius.circular(10)),
            child: Text(it.tag!, style: const TextStyle(color: Color(0xFFFFC857), fontSize: 10.5, fontWeight: FontWeight.w800)),
          ),
        if (it.group) const Icon(Icons.expand_less, color: Colors.white38, size: 20),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // الرأس: اللوجو + الاسم
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          const IrisLogo(size: 44),
          const SizedBox(width: 10),
          const Text('IRIS', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const Spacer(),
          const Text('أهلاً يا محمود', style: TextStyle(color: kIrisAccent, fontSize: 12)),
        ]),
      ),
      const Divider(color: Colors.white12, height: 12),
      _label('الأوضاع'),
      _row(const _Item(Icons.travel_explore, 'Deep Search', sub: 'بحث عميق')),
      _row(const _Item(Icons.dashboard_customize_outlined, 'Canvas')),
      _row(const _Item(Icons.school_outlined, 'Guided Learning', sub: 'تعلّم موجّه')),
      _label('الإبداع'),
      _row(const _Item(Icons.image_outlined, 'إنشاء صور')),
      _row(const _Item(Icons.movie_creation_outlined, 'إنشاء ريلز')),
      _row(const _Item(Icons.campaign_outlined, 'ريلز إعلانات / Promo', tag: 'مدفوع')),
      _row(const _Item(Icons.video_library_outlined, 'ريلز فيديو', sub: 'أطفال · علمي · سوشيال')),
      _label('أدوات'),
      _row(const _Item(Icons.menu_book_outlined, 'وضع الطالب', sub: 'ارفع كتبك وآيرس يشرحها')),
      _row(const _Item(Icons.cast_connected, 'وضع الربط', sub: 'اربط التلفزيون بآيرس')),
      _row(const _Item(Icons.apps, 'التطبيقات المتصلة')),
      _row(const _Item(Icons.bolt, 'تركيز الطاقة', sub: 'Energy Focus')),
    ]);
  }
}

// الموبايل: القائمة مفتوحة فوق الشاشة الرئيسية المعتمة
class PhoneDrawerPreview extends StatelessWidget {
  const PhoneDrawerPreview({super.key});
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(children: [
          // الشاشة الرئيسية من ورا (معتمة)
          Positioned.fill(
            child: Opacity(
              opacity: .35,
              child: Column(children: [
                const SizedBox(height: 60),
                const Center(child: IrisLogo(size: 110)),
                const SizedBox(height: 30),
                Container(margin: const EdgeInsets.symmetric(horizontal: 30), height: 44, decoration: BoxDecoration(color: _card2, borderRadius: BorderRadius.circular(22))),
              ]),
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(.55))),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 318,
            child: Container(
              decoration: BoxDecoration(color: _panel, border: Border(left: BorderSide(color: kIrisAccent.withOpacity(.25)))),
              child: SafeArea(child: SingleChildScrollView(child: const MenuList(selected: ''))),
            ),
          ),
        ]),
      ),
    );
  }
}

Widget _appBar(String t, {String? sub, bool back = true}) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(children: [
        if (back) const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
        if (back) const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
            if (sub != null) Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          ]),
        ),
        const IrisLogo(size: 34),
      ]),
    );

Widget _channel(IconData ic, String t, String sub, List<String> chips, {double h = 150, Color? c}) {
  final col = c ?? kIrisAccent;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: _card2,
      border: Border.all(color: col.withOpacity(.45)),
      gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [col.withOpacity(.16), _card2]),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(shape: BoxShape.circle, color: col.withOpacity(.18), border: Border.all(color: col)),
          child: Icon(ic, color: col, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        const Icon(Icons.chevron_left, color: Colors.white38),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final x in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white10),
            child: Text(x, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
      ]),
    ]),
  );
}

Widget _watchCard() => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: _card2, border: Border.all(color: Colors.white12)),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
          child: const Icon(Icons.watch_outlined, color: Colors.white70, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('اربط ساعتك الذكية', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            Text('نبض، خطوات، نوم عشان آيرس يظبط تركيزك', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: kIrisAccent),
          child: const Text('اربط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        ),
      ]),
    );

List<Widget> _energyCards() => [
      _channel(Icons.fitness_center, 'الرياضة', '+100 وضع رياضي جوه آيرس', ['جري', 'سباحة', 'يوجا', 'ملاكمة', 'عدّ', 'تمارين منزلية', '+100']),
      _channel(Icons.auto_stories_outlined, 'اتعلّم حاجة جديدة', 'اقرا مقال أو كتاب بتركيز', ['قراءة', 'مقال', 'ملخص', 'اسألني']),
      _channel(Icons.rocket_launch_outlined, 'الإنتاجية', 'حوّل طاقتك لشغل مخلّص', ['مهام اليوم', 'بومودورو', 'تركيز عميق']),
    ];

class PhoneEnergyPreview extends StatelessWidget {
  const PhoneEnergyPreview({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = _energyCards();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _appBar('تركيز الطاقة', sub: 'Energy Focus · وجّه طاقتك فين؟'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(children: [
                  cs[0], const SizedBox(height: 12), cs[1], const SizedBox(height: 12), cs[2],
                  const Spacer(),
                  _watchCard(),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _App {
  final String m, n, s;
  final bool on;
  const _App(this.m, this.n, this.s, this.on);
}

const _apps = [
  _App('Y', 'YouTube', 'شغّل وابحث بالصوت', true),
  _App('P', 'Google Photos', 'صورك وألبوماتك', true),
  _App('D', 'Google Drive', 'ملفاتك وكتبك', true),
  _App('H', 'Google Home', 'تحكم في البيت', false),
  _App('S', 'Spotify', 'موسيقى وبودكاست', false),
];

Widget _appTile(_App a) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _card2,
          border: Border.all(color: a.on ? const Color(0xFF2EE66B).withOpacity(.5) : Colors.white12)),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: kIrisAccent.withOpacity(.15), border: Border.all(color: kIrisAccent)),
          child: Text(a.m, style: const TextStyle(color: kIrisAccent, fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.n, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
            Text(a.s, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        if (a.on)
          Row(children: const [
            Icon(Icons.check_circle, color: Color(0xFF2EE66B), size: 18),
            SizedBox(width: 4),
            Text('متصل', style: TextStyle(color: Color(0xFF2EE66B), fontSize: 12.5, fontWeight: FontWeight.w700)),
          ])
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: kIrisAccent)),
            child: const Text('اربط', style: TextStyle(color: kIrisAccent, fontWeight: FontWeight.w800)),
          ),
      ]),
    );

class PhoneAppsPreview extends StatelessWidget {
  const PhoneAppsPreview({super.key});
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _appBar('التطبيقات المتصلة', sub: 'آيرس يشتغل مع حساباتك'),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
                for (final a in _apps) Padding(padding: const EdgeInsets.only(bottom: 10), child: _appTile(a)),
                const SizedBox(height: 4),
                const Text('آيرس مش بيشوف الباسورد بتاعك. الربط بيتم عن طريق تسجيل دخول رسمي من كل خدمة.',
                    style: TextStyle(color: Colors.white38, fontSize: 11.5, height: 1.5)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// اللابتوب: قائمة ثابتة على الجنب + محتوى
class LaptopMenuPreview extends StatelessWidget {
  final bool apps;
  final String sel;
  final Widget? content;
  const LaptopMenuPreview({super.key, this.apps = false, this.sel = '', this.content});
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Row(children: [
          Container(
            width: 300,
            decoration: BoxDecoration(color: _panel, border: Border(left: BorderSide(color: kIrisAccent.withOpacity(.25)))),
            child: SingleChildScrollView(child: MenuList(compact: true, selected: sel.isNotEmpty ? sel : (apps ? 'التطبيقات' : 'تركيز'))),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _appBar(apps ? 'التطبيقات المتصلة' : 'تركيز الطاقة', sub: apps ? 'آيرس يشتغل مع حساباتك' : 'Energy Focus · وجّه طاقتك فين؟', back: false),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: apps
                      ? GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 3.6,
                          children: [for (final a in _apps) _appTile(a)],
                        )
                      : Column(children: [
                          SizedBox(
                            height: 250,
                            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              for (final c in _energyCards()) ...[Expanded(child: c), const SizedBox(width: 14)],
                            ]),
                          ),
                          const Spacer(),
                          _watchCard(),
                        ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
