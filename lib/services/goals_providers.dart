import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log.dart';
import '../models/knee_data_point.dart';
import '../models/user_goals.dart';
import 'preferences_service.dart';
import 'session_providers.dart';

final userGoalsProvider = StateNotifierProvider<UserGoalsNotifier, UserGoals>((ref) {
  return UserGoalsNotifier();
});

final todayStepsProvider = Provider<int>((ref) {
  final session = ref.watch(activeSessionProvider);
  final log = ref.watch(dailyLogProvider(DateTime.now()));
  return (log.valueOrNull?.totalSteps ?? 0) + (session?.totalSteps ?? 0);
});

final todayExerciseMinutesProvider = Provider<int>((ref) {
  final session = ref.watch(activeSessionProvider);
  final log = ref.watch(dailyLogProvider(DateTime.now()));
  final daily = log.valueOrNull;

  final sessionMinutes = (session?.activityDurations[ActivityType.exercising] ?? Duration.zero).inMinutes;
  final persistedMinutes = (daily?.totalSessions ?? 0) == 0
      ? 0
      : _estimateExerciseMinutesFromLog(daily!);

  return persistedMinutes + sessionMinutes;
});

final todayActiveMinutesProvider = Provider<int>((ref) {
  final session = ref.watch(activeSessionProvider);
  final log = ref.watch(dailyLogProvider(DateTime.now()));
  return (log.valueOrNull?.totalActiveMinutes ?? 0) + (session?.elapsed.inMinutes ?? 0);
});

final stepGoalProgressProvider = Provider<double>((ref) {
  final steps = ref.watch(todayStepsProvider);
  final goals = ref.watch(userGoalsProvider);
  return (steps / goals.dailyStepGoal).clamp(0.0, 1.0);
});

final exerciseGoalProgressProvider = Provider<double>((ref) {
  final minutes = ref.watch(todayExerciseMinutesProvider);
  final goals = ref.watch(userGoalsProvider);
  return (minutes / goals.exerciseMinutesGoal).clamp(0.0, 1.0);
});

final activeHoursGoalProgressProvider = Provider<double>((ref) {
  final minutes = ref.watch(todayActiveMinutesProvider);
  final goals = ref.watch(userGoalsProvider);
  return ((minutes / 60.0) / goals.activeHoursGoal).clamp(0.0, 1.0);
});

final goalCompletionNotifierProvider = Provider<GoalCompletionSignal?>((ref) {
  final stepsProgress = ref.watch(stepGoalProgressProvider);
  final exerciseProgress = ref.watch(exerciseGoalProgressProvider);
  final activeProgress = ref.watch(activeHoursGoalProgressProvider);

  final cache = ref.watch(_goalCompletionCacheProvider.notifier);

  GoalCompletionSignal? signal;
  if (stepsProgress >= 1.0 && !cache.state.contains(GoalType.steps)) {
    cache.state = {...cache.state, GoalType.steps};
    signal = const GoalCompletionSignal(GoalType.steps, 'Daily step goal achieved');
  } else if (exerciseProgress >= 1.0 && !cache.state.contains(GoalType.exerciseMinutes)) {
    cache.state = {...cache.state, GoalType.exerciseMinutes};
    signal = const GoalCompletionSignal(GoalType.exerciseMinutes, 'Exercise minutes goal achieved');
  } else if (activeProgress >= 1.0 && !cache.state.contains(GoalType.activeHours)) {
    cache.state = {...cache.state, GoalType.activeHours};
    signal = const GoalCompletionSignal(GoalType.activeHours, 'Active hours goal achieved');
  }

  if (stepsProgress < 1.0 || exerciseProgress < 1.0 || activeProgress < 1.0) {
    final reset = <GoalType>{};
    if (stepsProgress >= 1.0) {
      reset.add(GoalType.steps);
    }
    if (exerciseProgress >= 1.0) {
      reset.add(GoalType.exerciseMinutes);
    }
    if (activeProgress >= 1.0) {
      reset.add(GoalType.activeHours);
    }
    if (cache.state.length != reset.length || !cache.state.containsAll(reset)) {
      cache.state = reset;
    }
  }

  return signal;
});

final _goalCompletionCacheProvider = StateProvider<Set<GoalType>>((ref) {
  return <GoalType>{};
});

class UserGoalsNotifier extends StateNotifier<UserGoals> {
  UserGoalsNotifier() : super(_loadGoals());

  static UserGoals _loadGoals() {
    return UserGoals(
      dailyStepGoal: PreferencesService.dailyStepGoal,
      exerciseMinutesGoal: PreferencesService.exerciseMinutesGoal,
      activeHoursGoal: PreferencesService.activeHoursGoal,
    );
  }

  Future<void> setDailyStepGoal(int value) async {
    final clamped = value.clamp(1000, 20000);
    await PreferencesService.setDailyStepGoal(clamped);
    state = state.copyWith(dailyStepGoal: clamped);
  }

  Future<void> setExerciseMinutesGoal(int value) async {
    final clamped = value.clamp(5, 120);
    await PreferencesService.setExerciseMinutesGoal(clamped);
    state = state.copyWith(exerciseMinutesGoal: clamped);
  }

  Future<void> setActiveHoursGoal(double value) async {
    final clamped = value.clamp(1.0, 12.0).toDouble();
    await PreferencesService.setActiveHoursGoal(clamped);
    state = state.copyWith(activeHoursGoal: clamped);
  }
}

enum GoalType {
  steps,
  exerciseMinutes,
  activeHours,
}

class GoalCompletionSignal {
  const GoalCompletionSignal(this.type, this.message);

  final GoalType type;
  final String message;

  Color get color {
    switch (type) {
      case GoalType.steps:
        return const Color(0xFF2E7D32);
      case GoalType.exerciseMinutes:
        return const Color(0xFF6A1B9A);
      case GoalType.activeHours:
        return const Color(0xFF0277BD);
    }
  }
}

int _estimateExerciseMinutesFromLog(DailyLog log) {
  return log.totalActiveMinutes ~/ 2;
}
