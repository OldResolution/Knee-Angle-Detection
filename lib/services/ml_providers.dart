import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gait_classification_service.dart';

/// Whether the ML model has been loaded and is ready for inference.
final mlModelLoadedProvider = StateProvider<bool>((ref) => false);

/// Singleton gait classification service (loaded async).
final gaitClassificationProvider =
    FutureProvider<GaitClassificationService>((ref) async {
  final service = await GaitClassificationService.load();
  ref.read(mlModelLoadedProvider.notifier).state = true;
  return service;
});

/// Latest gait prediction result from a session analysis.
final latestGaitPredictionProvider =
    StateProvider<GaitPrediction?>((ref) => null);
