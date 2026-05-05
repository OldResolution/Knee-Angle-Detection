import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log.dart';
import '../models/session_record.dart';
import 'preferences_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void> init() async {
    // Firestore handles its own initialization and offline persistence.
  }

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to access storage.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _sessionsRef =>
      _firestore.collection('users').doc(_uid).collection('sessions');

  CollectionReference<Map<String, dynamic>> get _dailyLogsRef =>
      _firestore.collection('users').doc(_uid).collection('dailyLogs');

  Future<void> saveSession(SessionRecord session) async {
    if (_auth.currentUser == null) return; // Ignore if not logged in

    try {
      await _sessionsRef.doc(session.id).set(session.toJson());
      await _updateDailyLogFromSession(session);
    } catch (e) {
      print('Error saving session to Firestore: $e');
    }
  }

  Future<DailyLog> getDailyLog(DateTime date) async {
    if (_auth.currentUser == null) return DailyLog.emptyForDate(date);

    final key = _dayKey(date).toString();
    final doc = await _dailyLogsRef.doc(key).get();

    if (doc.exists && doc.data() != null) {
      return DailyLog.fromJson(doc.data()!);
    }

    final empty = DailyLog.emptyForDate(date);
    await _dailyLogsRef.doc(key).set(empty.toJson());
    return empty;
  }

  Future<List<SessionRecord>> getSessionsForDate(DateTime date) async {
    if (_auth.currentUser == null) return [];

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snapshot = await _sessionsRef
        .where('startTime', isGreaterThanOrEqualTo: dayStart.toIso8601String())
        .where('startTime', isLessThan: dayEnd.toIso8601String())
        .get();

    final sessions = snapshot.docs.map((doc) => SessionRecord.fromJson(doc.data())).toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  Future<List<SessionRecord>> getAllSessions() async {
    if (_auth.currentUser == null) return [];

    final snapshot = await _sessionsRef.get();
    final sessions = snapshot.docs.map((doc) => SessionRecord.fromJson(doc.data())).toList();
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
    if (_auth.currentUser == null) return;

    final sessions = await _sessionsRef.get();
    for (var doc in sessions.docs) {
      await doc.reference.delete();
    }

    final logs = await _dailyLogsRef.get();
    for (var doc in logs.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _updateDailyLogFromSession(SessionRecord session) async {
    if (_auth.currentUser == null) return;

    final key = _dayKey(session.startTime).toString();

    // Get existing
    final doc = await _dailyLogsRef.doc(key).get();
    final existing = doc.exists && doc.data() != null
        ? DailyLog.fromJson(doc.data()!)
        : DailyLog.emptyForDate(session.startTime);

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

    await _dailyLogsRef.doc(key).set(updated.toJson());
  }

  int _exerciseMinutesForDay(List<SessionRecord> sessions) {
    return sessions
        .where((s) => s.dominantActivity.name == 'exercising')
        .fold<int>(0, (sum, s) => sum + s.duration.inMinutes);
  }

  Future<List<DailyLog>> _getRecentLogs(int days) async {
    if (_auth.currentUser == null) return [];

    final today = DateTime.now();
    final logs = <DailyLog>[];

    for (var i = days - 1; i >= 0; i--) {
      final date = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final key = _dayKey(date).toString();
      final doc = await _dailyLogsRef.doc(key).get();
      logs.add(doc.exists && doc.data() != null
          ? DailyLog.fromJson(doc.data()!)
          : DailyLog.emptyForDate(date));
    }

    return logs;
  }

  int _dayKey(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }
}
