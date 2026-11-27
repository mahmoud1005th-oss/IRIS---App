import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// صوت آيرس من السيرفر (أصوات عصبية عربية ذكر/أنثى). الصوت الحالي داخل الشاشة الرئيسية
// بيستخدم صوت الموبايل (flutter_tts) كبديل بدون إنترنت. لما السيرفر يجهز: حط الرابط
// في kTtsEndpoint. السيرفر يستقبل POST JSON {"text":"...","gender":"male|female","lang":"ar"}
// ويرد ملف صوت (mp3/wav) في الجسم. التطبيق يحفظه ويشغّله (audioplayers).
const String kTtsEndpoint = ''; // فاضي = الصوت من الموبايل نفسه

abstract class TtsService {
  bool get connected;
  // بيرجع مسار ملف الصوت المحفوظ، أو null لو فشل
  Future<String?> synthesize(String text, {String gender = 'male', String lang = 'ar'});
}

class DeviceOnlyTtsService implements TtsService {
  const DeviceOnlyTtsService();
  @override
  bool get connected => false;
  @override
  Future<String?> synthesize(String text, {String gender = 'male', String lang = 'ar'}) async => null;
}

class HttpTtsService implements TtsService {
  final String endpoint;
  const HttpTtsService(this.endpoint);
  @override
  bool get connected => true;
  @override
  Future<String?> synthesize(String text, {String gender = 'male', String lang = 'ar'}) async {
    try {
      final res = await http
          .post(Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'text': text, 'gender': gender, 'lang': lang}))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
      final f = File('${Directory.systemTemp.path}/iris_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await f.writeAsBytes(res.bodyBytes);
      return f.path;
    } catch (_) {
      return null;
    }
  }
}

TtsService makeTtsService() =>
    kTtsEndpoint.isEmpty ? const DeviceOnlyTtsService() : const HttpTtsService(kTtsEndpoint);
