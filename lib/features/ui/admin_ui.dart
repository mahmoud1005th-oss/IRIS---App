import 'package:flutter/material.dart';

class AdminUI extends StatelessWidget {
  const AdminUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("لوحة المايسترو - Admin Panel"), backgroundColor: Colors.cyanAccent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("أهلاً بك يا مايسترو محمود 👑", style: TextStyle(color: Colors.cyanAccent, fontSize: 22)),
          const Divider(),
          // إشعارات طلبات المستخدمين غير المتاحة (V3 - واجهة مبدئية)
          // لما مستخدم يطلب من آيرس حاجة مش قادر عليها (زي ملف APK) هيوصلك إشعار هنا
          // وآيرس ترد عليه "مش متاح حاليًا، وفيه تحديثات جاية"
          // الجزء ده محتاج جدول في Supabase - هيتفعل لما المفاتيح تتضاف
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const ListTile(
              leading: Icon(Icons.notifications_active, color: Colors.cyanAccent),
              title: Text("طلبات غير متاحة من المستخدمين", style: TextStyle(color: Colors.white)),
              subtitle: Text(
                "قريبًا: إشعار لما مستخدم يطلب حاجة آيرس مش قادر عليها (محتاج ربط Supabase)",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          ListTile(leading: const Icon(Icons.key, color: Colors.white), title: const Text("إدارة مفاتيح API", style: TextStyle(color: Colors.white)), subtitle: const Text("تغيير OpenRouter / Replicate Keys", style: TextStyle(color: Colors.grey))),
          ListTile(leading: const Icon(Icons.people, color: Colors.white), title: const Text("إدارة المستخدمين", style: TextStyle(color: Colors.white)), subtitle: const Text("ترقية مستخدم لـ Pro / حظر مستخدم", style: TextStyle(color: Colors.grey))),
          ListTile(leading: const Icon(Icons.attach_money, color: Colors.white), title: const Text("إدارة التسعير", style: TextStyle(color: Colors.white)), subtitle: const Text("تعديل أسعار الباقات", style: TextStyle(color: Colors.grey))),
          ListTile(leading: const Icon(Icons.analytics, color: Colors.white), title: const Text("الإحصائيات", style: TextStyle(color: Colors.white)), subtitle: const Text("عدد الصور والفيديوهات المولدة", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}
