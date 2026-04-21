import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log.dart';
import '../models/knee_data_point.dart';
import '../models/session_record.dart';
import '../models/user_goals.dart';
import 'ble_data_service.dart';
import 'ble_providers.dart';
import 'goals_providers.dart';
import 'session_providers.dart';

final simulationModeProvider = Provider<bool>((ref) {
  return ref.watch(bleConnectionStateProvider).isSimulationMode;
});

final simulationPatternProvider = Provider<SimulationPattern>((ref) {
  return ref.watch(bleControllerProvider.notifier).simulationPattern;
});

final mobilityTrajectoryBucketsProvider = Provider<List<double>>((ref) {
  final history = ref.watch(kneeDataHistoryProvider);
  final pattern = ref.watch(simulationPatternProvider);
  if (history.isNotEmpty) {
    return _bucketizeAngles(history, bucketCount: 10);
  }
  return _generateMobilityBuckets(pattern);
});

final hourlyActivityBarsProvider = Provider<List<double>>((ref) {
  final pattern = ref.watch(simulationPatternProvider);
  final activeSession = ref.watch(activeSessionProvider);
  final stepsToday = ref.watch(todayStepsProvider);
  return _generateHourlyBars(
    pattern: pattern,
    stepsToday: stepsToday,
    activeSession: activeSession,
  );
});

final dashboardInsightProvider = Provider<DashboardInsightData>((ref) {
  final current = ref.watch(currentKneeDataProvider);
  final history = ref.watch(kneeDataHistoryProvider);
  final alerts = ref.watch(alertHistoryProvider);
  final activeSession = ref.watch(activeSessionProvider);
  final pattern = ref.watch(simulationPatternProvider);
  final latestAlert = alerts.isEmpty
      ? null
      : alerts.firstWhere(
          (alert) => !alert.dismissed,
          orElse: () => alerts.first,
        );

  final recentPoints =
      history.length > 30 ? history.sublist(history.length - 30) : history;
  final avgSpeed = recentPoints.isEmpty
      ? 0.0
      : recentPoints.fold<double>(0, (sum, point) => sum + point.speed) /
          recentPoints.length;
  final avgAngle = recentPoints.isEmpty
      ? 0.0
      : recentPoints.fold<double>(0, (sum, point) => sum + point.angle) /
          recentPoints.length;

  final primaryTitle = latestAlert?.title ??
      (avgSpeed < 8 ? 'Mobility Nudge' : 'Movement Quality Stable');
  final primaryMessage = latestAlert?.message ??
      (avgSpeed < 8
          ? 'Range of motion has been gentle for a while. A short mobility drill can keep the joint warm.'
          : 'Current cadence and flexion profile look steady with no sudden instability detected.');

  final extensionCount =
      ((activeSession?.totalSteps ?? 0) / 14).clamp(1, 8).round();
  final secondaryTitle =
      avgAngle >= 75 ? 'Extension Target Met' : 'Flexion Building';
  final secondaryMessage = avgAngle >= 75
      ? 'You achieved controlled extension $extensionCount times in this session with smooth recovery between reps.'
      : 'Average flexion is trending upward. Another few minutes of guided reps should move you closer to target.';

  final gaitCue = _patternInsight(pattern);
  final peakAngle = history.isEmpty
      ? _patternTraits(pattern).avgAngle + _patternTraits(pattern).peakOffset
      : history.fold<double>(0, (maxValue, point) {
          return point.angle > maxValue ? point.angle : maxValue;
        });
  final aiInsight =
      '$gaitCue Peak flexion is ${peakAngle.toStringAsFixed(0)} degrees and average movement speed is ${avgSpeed.toStringAsFixed(0)} degrees per second.';

  return DashboardInsightData(
    primaryTitle: primaryTitle,
    primaryMessage: primaryMessage,
    secondaryTitle: secondaryTitle,
    secondaryMessage: secondaryMessage,
    aiInsight: aiInsight,
    recommendedTargetAngle: math.max(75, (avgAngle + 12).round()).toDouble(),
    currentAngle: current?.angle ?? avgAngle,
  );
});

final liveSessionMetricsProvider = Provider<LiveSessionMetricsData>((ref) {
  final activeSession = ref.watch(activeSessionProvider);
  final history = ref.watch(kneeDataHistoryProvider);
  final pattern = ref.watch(simulationPatternProvider);
  final traits = _patternTraits(pattern);

  final currentAngle = history.isEmpty ? traits.avgAngle : history.last.angle;
  final peakAngle = history.isEmpty
      ? traits.avgAngle + traits.peakOffset
      : history.fold<double>(0, (maxValue, point) {
          return point.angle > maxValue ? point.angle : maxValue;
        });

  final deltas = <double>[];
  for (var i = 1; i < history.length; i++) {
    deltas.add((history[i].angle - history[i - 1].angle).abs());
  }
  final avgDelta = deltas.isEmpty
      ? traits.smoothnessBase
      : deltas.reduce((a, b) => a + b) / deltas.length;
  final smoothnessScore = (100 - avgDelta * 1.8).clamp(62, 98).round();
  final improvement =
      ((activeSession?.totalSteps ?? 0) / 18).clamp(3, 18).round();

  final extensionTitle = peakAngle >= traits.avgAngle + traits.peakOffset * 0.6
      ? 'Extension Target Met'
      : 'Extension Building';
  final extensionSubtitle = peakAngle >=
          traits.avgAngle + traits.peakOffset * 0.6
      ? 'Peak flexion reached ${peakAngle.toStringAsFixed(0)} degrees with stable recovery in the last movement cycle.'
      : 'Current range tops out at ${peakAngle.toStringAsFixed(0)} degrees. A few more smooth cycles should close the gap.';

  final smoothnessSubtitle =
      'Kinematic flow remains ${smoothnessScore >= 85 ? 'steady' : 'variable'} with simulation pattern tuned for ${pattern.displayName.toLowerCase()}. Micro-stutters have ${smoothnessScore >= 85 ? 'decreased' : 'started to ease'} by about $improvement%.';

  return LiveSessionMetricsData(
    targetAngle: math
        .max(80, (traits.avgAngle + traits.peakOffset * 0.7).round())
        .toDouble(),
    extensionTitle: extensionTitle,
    extensionSubtitle: extensionSubtitle,
    smoothnessScore: smoothnessScore,
    smoothnessSubtitle: smoothnessSubtitle,
    currentAngle: currentAngle,
  );
});

final simulatedTrendLogsProvider =
    Provider.family<List<DailyLog>, int>((ref, days) {
  final pattern = ref.watch(simulationPatternProvider);
  final goals = ref.watch(userGoalsProvider);
  return _generateTrendLogs(pattern: pattern, goals: goals, days: days);
});

final simulatedSessionsProvider = Provider<List<SessionRecord>>((ref) {
  final pattern = ref.watch(simulationPatternProvider);
  return _generateSessions(pattern);
});

class DashboardInsightData {
  const DashboardInsightData({
    required this.primaryTitle,
    required this.primaryMessage,
    required this.secondaryTitle,
    required this.secondaryMessage,
    required this.aiInsight,
    required this.recommendedTargetAngle,
    required this.currentAngle,
  });

  final String primaryTitle;
  final String primaryMessage;
  final String secondaryTitle;
  final String secondaryMessage;
  final String aiInsight;
  final double recommendedTargetAngle;
  final double currentAngle;
}

class LiveSessionMetricsData {
  const LiveSessionMetricsData({
    required this.targetAngle,
    required this.extensionTitle,
    required this.extensionSubtitle,
    required this.smoothnessScore,
    required this.smoothnessSubtitle,
    required this.currentAngle,
  });

  final double targetAngle;
  final String extensionTitle;
  final String extensionSubtitle;
  final int smoothnessScore;
  final String smoothnessSubtitle;
  final double currentAngle;
}

class _PatternTraits {
  const _PatternTraits({
    required this.avgAngle,
    required this.peakOffset,
    required this.speedBase,
    required this.stepFloor,
    required this.stepRange,
    required this.label,
    required this.smoothnessBase,
  });

  final double avgAngle;
  final double peakOffset;
  final double speedBase;
  final int stepFloor;
  final int stepRange;
  final String label;
  final double smoothnessBase;
}

_PatternTraits _patternTraits(SimulationPattern pattern) {
  switch (pattern) {
    case SimulationPattern.normalWalking:
      return const _PatternTraits(
        avgAngle: 72,
        peakOffset: 30,
        speedBase: 74,
        stepFloor: 7600,
        stepRange: 2400,
        label: 'Normal',
        smoothnessBase: 7,
      );
    case SimulationPattern.limp:
      return const _PatternTraits(
        avgAngle: 58,
        peakOffset: 35,
        speedBase: 68,
        stepFloor: 5200,
        stepRange: 1800,
        label: 'Limp',
        smoothnessBase: 11,
      );
    case SimulationPattern.shuffling:
      return const _PatternTraits(
        avgAngle: 26,
        peakOffset: 14,
        speedBase: 42,
        stepFloor: 3400,
        stepRange: 1200,
        label: 'Shuffling',
        smoothnessBase: 14,
      );
    case SimulationPattern.stiffKnee:
      return const _PatternTraits(
        avgAngle: 42,
        peakOffset: 18,
        speedBase: 36,
        stepFloor: 4100,
        stepRange: 1600,
        label: 'Stiff-Knee',
        smoothnessBase: 12,
      );
    case SimulationPattern.exercise:
      return const _PatternTraits(
        avgAngle: 88,
        peakOffset: 42,
        speedBase: 96,
        stepFloor: 6900,
        stepRange: 2600,
        label: 'Normal',
        smoothnessBase: 8,
      );
    case SimulationPattern.random:
      return const _PatternTraits(
        avgAngle: 68,
        peakOffset: 28,
        speedBase: 70,
        stepFloor: 6100,
        stepRange: 2100,
        label: 'Unstable',
        smoothnessBase: 10,
      );
  }
}

String _patternInsight(SimulationPattern pattern) {
  switch (pattern) {
    case SimulationPattern.normalWalking:
      return 'Symmetry remains balanced across the recent walking cycles. ';
    case SimulationPattern.limp:
      return 'The simulated limp pattern still shows mild asymmetry, but cadence is stabilizing. ';
    case SimulationPattern.shuffling:
      return 'Short-step shuffling is visible, with conservative flexion and reduced propulsion. ';
    case SimulationPattern.stiffKnee:
      return 'Range-of-motion remains guarded, which is consistent with a stiff-knee recovery pattern. ';
    case SimulationPattern.exercise:
      return 'Exercise mode is producing larger, more deliberate flexion arcs with stronger tempo. ';
    case SimulationPattern.random:
      return 'Movement variability is intentionally diverse here, useful for stress-testing the analytics panels. ';
  }
}

List<double> _bucketizeAngles(
  List<KneeDataPoint> history, {
  required int bucketCount,
}) {
  final source =
      history.length > 150 ? history.sublist(history.length - 150) : history;
  if (source.isEmpty) {
    return List<double>.filled(bucketCount, 0);
  }

  final bucketSize = math.max(1, (source.length / bucketCount).ceil());
  final values = <double>[];
  for (var i = 0; i < bucketCount; i++) {
    final start = i * bucketSize;
    if (start >= source.length) {
      values.add(values.isEmpty ? source.last.angle : values.last);
      continue;
    }
    final end = math.min(source.length, start + bucketSize);
    final segment = source.sublist(start, end);
    final avg = segment.fold<double>(0, (sum, point) => sum + point.angle) /
        segment.length;
    values.add(avg);
  }
  return values;
}

List<double> _generateMobilityBuckets(SimulationPattern pattern) {
  final traits = _patternTraits(pattern);
  final now = DateTime.now();
  return List<double>.generate(10, (index) {
    final phase = (now.minute / 60) + index * 0.37;
    final wave = math.sin(phase * math.pi * 1.25) * (traits.peakOffset * 0.45);
    final harmonic =
        math.cos((phase + 0.4) * math.pi * 0.7) * (traits.peakOffset * 0.18);
    return (traits.avgAngle + wave + harmonic).clamp(10, 150).toDouble();
  });
}

List<double> _generateHourlyBars({
  required SimulationPattern pattern,
  required int stepsToday,
  required ActiveSessionState? activeSession,
}) {
  final traits = _patternTraits(pattern);
  final now = DateTime.now();
  final base = math.max(stepsToday ~/ 180, 18);

  return List<double>.generate(11, (index) {
    final morningPeak = math.exp(-math.pow(index - 2.2, 2) / 5.5);
    final afternoonPeak = math.exp(-math.pow(index - 6.5, 2) / 4.0);
    final eveningPeak = math.exp(-math.pow(index - 8.8, 2) / 5.0);
    final currentBoost = index == (now.hour - 8).clamp(0, 10) ? 0.28 : 0.0;
    final profile = 0.5 +
        morningPeak * 0.7 +
        afternoonPeak * 1.0 +
        eveningPeak * 0.55 +
        currentBoost;
    final sessionBoost = activeSession == null
        ? 0.0
        : (activeSession.totalSteps / 220).clamp(0, 18).toDouble();
    final value = base * profile * (traits.speedBase / 70) + sessionBoost;
    return value.clamp(8, 98).toDouble();
  });
}

List<DailyLog> _generateTrendLogs({
  required SimulationPattern pattern,
  required UserGoals goals,
  required int days,
}) {
  final traits = _patternTraits(pattern);
  final today = DateTime.now();
  return List<DailyLog>.generate(days, (index) {
    final dayOffset = days - index - 1;
    final date = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: dayOffset));
    final trend = math.sin((index + 1) * 0.48);
    final recovery = math.cos((index + 1) * 0.21);
    final steps = (traits.stepFloor +
            traits.stepRange * 0.5 +
            trend * traits.stepRange * 0.45)
        .round();
    final activeMinutes =
        (55 + (traits.speedBase * 0.35) + recovery * 16).round().clamp(28, 180);
    final avgAngle = (traits.avgAngle + trend * (traits.peakOffset * 0.35))
        .clamp(15, 140)
        .toDouble();
    final peakAngle =
        (avgAngle + traits.peakOffset + recovery * 6).clamp(25, 160).toDouble();
    final avgSpeed = (traits.speedBase + trend * 12 + recovery * 7)
        .clamp(16, 150)
        .toDouble();
    final totalSessions = pattern == SimulationPattern.exercise ? 2 : 1;

    return DailyLog(
      date: date,
      totalSteps: steps,
      totalCalories: steps * 0.04,
      totalActiveMinutes: activeMinutes,
      totalSessions: totalSessions,
      avgKneeAngle: avgAngle,
      peakKneeAngle: peakAngle,
      avgSpeed: avgSpeed,
      goalStepsMet: steps >= goals.dailyStepGoal,
      goalExerciseMet: activeMinutes >= goals.exerciseMinutesGoal,
      goalActiveHoursMet: (activeMinutes / 60.0) >= goals.activeHoursGoal,
    );
  });
}

List<SessionRecord> _generateSessions(SimulationPattern pattern) {
  final traits = _patternTraits(pattern);
  final now = DateTime.now();
  return List<SessionRecord>.generate(6, (index) {
    final dayShift = index ~/ 2;
    final start = DateTime(
      now.year,
      now.month,
      now.day - dayShift,
      7 + (index % 2) * 9,
      12 + index * 4,
    );
    final durationMinutes = 16 + index * 4;
    final avgAngle =
        (traits.avgAngle + math.sin(index * 0.8) * 6).clamp(12, 135).toDouble();
    final peakAngle = (avgAngle + traits.peakOffset + math.cos(index * 0.6) * 3)
        .clamp(24, 160)
        .toDouble();
    final avgSpeed = (traits.speedBase + math.sin(index * 0.5) * 8)
        .clamp(18, 160)
        .toDouble();
    final totalSteps = (traits.stepFloor / 12 + index * 90).round();
    final activity = pattern == SimulationPattern.exercise
        ? ActivityType.exercising
        : ActivityType.walking;

    return SessionRecord(
      id: 'sim-session-$index',
      startTime: start,
      endTime: start.add(Duration(minutes: durationMinutes)),
      avgAngle: avgAngle,
      peakAngle: peakAngle,
      minAngle: math.max(0, avgAngle - 22),
      avgSpeed: avgSpeed,
      peakSpeed: avgSpeed + 18,
      totalSteps: totalSteps,
      caloriesBurned: totalSteps * 0.04,
      dominantActivity: activity,
      gaitLabel: traits.label,
    );
  });
}
