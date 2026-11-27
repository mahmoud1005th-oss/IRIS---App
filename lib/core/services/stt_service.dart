import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// تفريغ الصوت لنص. الخدمة الحقيقية لسه مش موجودة: محتاجة سيرفر (مثلاً Modal بنموذج كلام مجاني).
// لما السيرفر يجهز: حط الرابط في kSttEndpoint، والسيرفر يستقبل POST multipart
// فيه ملف الصوت في الحقل "audio" واللغة في "lang"، ويرد JSON: {"text": "..."}
const String kSttEndpoint = ''; // فاضي = الخدمة مش متوصلة

class SttResult {
  final String? text;
  final String? error;
  const SttResult.ok(String t) : text = t, error = null;
  const SttResult.fail(String e) : text = null, error = e;
  bool get ok => text != null;
}

abstract class SttService {
  Future<SttResult> transcribe(String audioPath, {String lang = 'ar'});
}

class PlaceholderSttService implements SttService {
  @override
  Future<SttResult> transcribe(String audioPath, {String lang = 'ar'}) async =>
      const SttResult.fail('not_connected');
}

class HttpSttService implements SttService {
  final String endpoint;
  const HttpSttService(this.endpoint);
  @override
  Future<SttResult> transcribe(String audioPath, {String lang = 'ar'}) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(endpoint))
        ..fields['lang'] = lang
        ..files.add(await http.MultipartFile.fromPath('audio', audioPath));
      final res = await http.Response.fromStream(
          await req.send().timeout(const Duration(seconds: 60)));
      if (res.statusCode != 200) return SttResult.fail('http_${res.statusCode}');
      final t = (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['text'];
      if (t is! String || t.trim().isEmpty) return const SttResult.fail('empty');
      return SttResult.ok(t.trim());
    } on SocketException {
      return const SttResult.fail('offline');
    } catch (_) {
      return const SttResult.fail('error');
    }
  }
}

SttService makeSttService() =>
    kSttEndpoint.isEmpty ? PlaceholderSttService() : const HttpSttService(kSttEndpoint);
