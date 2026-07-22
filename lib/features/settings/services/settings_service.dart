import 'package:shared_preferences/shared_preferences.dart';

enum MemoryRetention {
  oneWeek('1_week', '1 semana', Duration(days: 7)),
  oneMonth('1_month', '1 mes', Duration(days: 30)),
  threeMonths('3_months', '3 meses', Duration(days: 90)),
  forever('forever', 'Siempre', null);

  final String key;
  final String label;
  final Duration? duration;
  const MemoryRetention(this.key, this.label, this.duration);

  DateTime? get cutoff {
    if (duration == null) return null;
    return DateTime.now().subtract(duration!);
  }
}

class SettingsService {
  static const _keyMemoryRetention = 'ai_memory_retention';
  static MemoryRetention _cached = MemoryRetention.oneMonth;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyMemoryRetention) ?? '1_month';
    _cached = MemoryRetention.values.firstWhere(
      (e) => e.key == value,
      orElse: () => MemoryRetention.oneMonth,
    );
  }

  static MemoryRetention get memoryRetention => _cached;

  static Future<void> setMemoryRetention(MemoryRetention value) async {
    _cached = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMemoryRetention, value.key);
  }
}
