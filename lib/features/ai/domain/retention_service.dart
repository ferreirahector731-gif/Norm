import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/database/database_service.dart';

enum RetentionPeriod {
  week(604800),
  month(2592000),
  threeMonths(7776000),
  never(0);

  final int seconds;
  const RetentionPeriod(this.seconds);
}

class RetentionService {
  static final RetentionService _instance = RetentionService._();
  factory RetentionService() => _instance;
  RetentionService._();

  Timer? _timer;
  final ValueNotifier<RetentionPeriod> retentionPeriod =
      ValueNotifier(RetentionPeriod.month);

  bool _initialized = false;

  /// Inicia el timer de limpieza periódica (cada 6 horas).
  void start({RetentionPeriod period = RetentionPeriod.month}) {
    if (_initialized) return;
    _initialized = true;
    retentionPeriod.value = period;
    _scheduleCleanup();
  }

  void _scheduleCleanup() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 6), (_) => _runCleanup());
    // Ejecutar una limpieza inicial al arrancar
    _runCleanup();
  }

  Future<void> _runCleanup() async {
    final period = retentionPeriod.value;
    if (period == RetentionPeriod.never) return;

    final cutoff = DateTime.now().subtract(Duration(seconds: period.seconds));
    try {
      await DatabaseService.deleteOldChatMessages(cutoff);
    } catch (_) {
      // Silencioso — reintentar en el próximo ciclo
    }
  }

  void updatePeriod(RetentionPeriod period) {
    retentionPeriod.value = period;
    _scheduleCleanup();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _initialized = false;
  }
}
