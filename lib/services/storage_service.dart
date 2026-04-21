import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/daily_log.dart';
import '../models/session_record.dart';
import 'preferences_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _sessionsBoxName = 'sessions';
  static const String _dailyLogsBoxName = 'dailyLogs';

  late final Box<SessionRecord> _sessionsBox;
  late final Box<DailyLog> _dailyLogsBox;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SessionRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DailyLogAdapter());
    }

    _sessionsBox = await Hive.openBox<SessionRecord>(_sessionsBoxName);
    _dailyLogsBox = await Hive.openBox<DailyLog>(_dailyLogsBoxName);
    _isInitialized = true;
  }

  Future<void> saveSession(SessionRecord session) async {
    _ensureInitialized();
    await _sessionsBox.put(session.id, session);
    await _updateDailyLogFromSession(session);
  }

  Future<DailyLog> getDailyLog(DateTime date) async {
    _ensureInitialized();
    final key = _dayKey(date);
    final existing = _dailyLogsBox.get(key);
    if (existing != null) {
      return existing;
    }

    final empty = DailyLog.emptyForDate(date);
    await _dailyLogsBox.put(key, empty);
    return empty;
  }

  Future<List<SessionRecord>> getSessionsForDate(DateTime date) async {
    _ensureInitialized();
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final sessions = _sessionsBox.values.where((session) {
      return !session.startTime.isBefore(dayStart) && session.startTime.isBefore(dayEnd);
    }).toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  Future<List<SessionRecord>> getAllSessions() async {
    _ensureInitialized();
    final sessions = _sessionsBox.values.toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  Future<List<DailyLog>> getLast7DaysLogs() async {
    return _getRecentLogs(7);
  }

  Future<List<DailyLog>> getLast30DaysLogs() async {
    return _getRecentLogs(30);
  }

  Future<void> clearAllData() async {
    _ensureInitialized();
    await _sessionsBox.clear();
    await _dailyLogsBox.clear();
  }

  Future<void> _updateDailyLogFromSession(SessionRecord session) async {
    final key = _dayKey(session.startTime);
    final existing = _dailyLogsBox.get(key) ?? DailyLog.emptyForDate(session.startTime);

    final sessionsToday = await getSessionsForDate(session.startTime);
    final totalSessions = sessionsToday.length;
    final totalSteps = sessionsToday.fold<int>(0, (sum, s) => sum + s.totalSteps);
    final totalCalories = sessionsToday.fold<double>(0.0, (sum, s) => sum + s.caloriesBurned);
    final totalActiveMinutes = sessionsToday.fold<int>(
      0,
      (sum, s) => sum + s.duration.inMinutes,
    );

    final avgKneeAngle = totalSessions == 0
      ? 0.0
        : sessionsToday.fold<double>(0.0, (sum, s) => sum + s.avgAngle) / totalSessions;
    final peakKneeAngle = sessionsToday.fold<double>(0.0, (maxValue, s) {
      return s.peakAngle > maxValue ? s.peakAngle : maxValue;
    });
    final avgSpeed = totalSessions == 0
      ? 0.0
        : sessionsToday.fold<double>(0.0, (sum, s) => sum + s.avgSpeed) / totalSessions;

    final updated = existing.copyWith(
      date: DateTime(session.startTime.year, session.startTime.month, session.startTime.day),
      totalSteps: totalSteps,
      totalCalories: totalCalories,
      totalActiveMinutes: totalActiveMinutes,
      totalSessions: totalSessions,
      avgKneeAngle: avgKneeAngle,
      peakKneeAngle: peakKneeAngle,
      avgSpeed: avgSpeed,
      goalStepsMet: totalSteps >= PreferencesService.dailyStepGoal,
      goalExerciseMet: _exerciseMinutesForDay(sessionsToday) >= PreferencesService.exerciseMinutesGoal,
      goalActiveHoursMet: (totalActiveMinutes / 60.0) >= PreferencesService.activeHoursGoal,
    );

    await _dailyLogsBox.put(key, updated);
  }

  int _exerciseMinutesForDay(List<SessionRecord> sessions) {
    return sessions
        .where((s) => s.dominantActivity.name == 'exercising')
        .fold<int>(0, (sum, s) => sum + s.duration.inMinutes);
  }

  Future<List<DailyLog>> _getRecentLogs(int days) async {
    _ensureInitialized();
    final today = DateTime.now();
    final logs = <DailyLog>[];

    for (var i = days - 1; i >= 0; i--) {
      final date = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final key = _dayKey(date);
      logs.add(_dailyLogsBox.get(key) ?? DailyLog.emptyForDate(date));
    }

    return logs;
  }

  int _dayKey(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('StorageService.init() must be called before usage.');
    }
  }
}
