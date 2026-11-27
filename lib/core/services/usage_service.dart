// سقف الاستخدام اليومي (صور). حاليا قيم تجريبية ثابتة. لما الحسابات والسيرفر يتوصلوا:
// نفّذ Usage من السيرفر (عدد المستخدم النهارده + الحد حسب الخطة) بدل PlaceholderUsageService.
class Usage {
  final int used;
  final int limit;
  const Usage(this.used, this.limit);
}

abstract class UsageService {
  Future<Usage> today();
}

class PlaceholderUsageService implements UsageService {
  const PlaceholderUsageService();
  @override
  Future<Usage> today() async => const Usage(3, 7); // تجريبي، مش حقيقي
}

UsageService makeUsageService() => const PlaceholderUsageService();
