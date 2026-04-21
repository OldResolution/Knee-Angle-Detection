import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Result of a gait classification inference.
class GaitPrediction {
  const GaitPrediction({
    required this.label,
    required this.classIndex,
    required this.confidence,
    required this.probabilities,
    required this.timestamp,
  });

  /// Human-readable class label (e.g. "Normal", "Limp")
  final String label;

  /// Numeric class index (0–4)
  final int classIndex;

  /// Confidence of the predicted class (0.0–1.0)
  final double confidence;

  /// Probability distribution across all classes
  final Map<String, double> probabilities;

  final DateTime timestamp;
}

/// On-device gait abnormality classifier.
///
/// Implements a logistic regression model exported from scikit-learn.
/// The model weights, preprocessing parameters, and class labels are
/// loaded from a JSON asset file at runtime.
///
/// **Classification classes:**
/// 0 = Normal, 1 = Limp, 2 = Shuffling, 3 = Unstable, 4 = Stiff-Knee
class GaitClassificationService {
  GaitClassificationService._();

  bool _loaded = false;
  bool get isLoaded => _loaded;

  // Preprocessing parameters
  late List<String> _numericalFeatures;
  late List<double> _scalerMeans;
  late List<double> _scalerScales;
  late List<String> _categoricalFeatures;
  late Map<String, List<String>> _oheCategories;

  // Model weights
  late List<List<double>> _coefficients; // shape (nClasses, nFeatures)
  late List<double> _intercepts; // shape (nClasses,)
  late List<String> _classLabels;
  late int _nClasses;
  late int _nFeatures;

  /// Load the model from the asset bundle.
  static Future<GaitClassificationService> load({
    String assetPath = 'assets/models/gait_model.json',
  }) async {
    final service = GaitClassificationService._();
    final jsonStr = await rootBundle.loadString(assetPath);
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    // Parse preprocessing
    final preprocessing = data['preprocessing'] as Map<String, dynamic>;
    service._numericalFeatures =
        (preprocessing['numerical_features'] as List).cast<String>();
    service._scalerMeans =
        (preprocessing['scaler_means'] as List).cast<double>();
    service._scalerScales =
        (preprocessing['scaler_scales'] as List).cast<double>();
    service._categoricalFeatures =
        (preprocessing['categorical_features'] as List).cast<String>();

    final oheRaw = preprocessing['ohe_categories'] as Map<String, dynamic>;
    service._oheCategories = oheRaw
        .map((key, value) => MapEntry(key, (value as List).cast<String>()));

    // Parse weights
    final weights = data['weights'] as Map<String, dynamic>;
    service._coefficients = (weights['coefficients'] as List)
        .map((row) => (row as List).cast<double>())
        .toList();
    service._intercepts = (weights['intercepts'] as List).cast<double>();

    // Class labels
    service._classLabels = (data['class_labels'] as List).cast<String>();
    service._nClasses = data['n_classes'] as int;
    service._nFeatures = data['n_features'] as int;

    service._loaded = true;
    return service;
  }

  /// Run inference on a single sample.
  ///
  /// [numericalValues] must be a map of feature name → value for all 77
  /// numerical features. [categoricalValues] must contain 'task' and 'session'.
  GaitPrediction predict({
    required Map<String, double> numericalValues,
    required Map<String, String> categoricalValues,
  }) {
    if (!_loaded) {
      throw StateError('Model not loaded. Call GaitClassificationService.load() first.');
    }

    // 1. StandardScaler transform
    final scaled = List<double>.filled(_numericalFeatures.length, 0);
    for (var i = 0; i < _numericalFeatures.length; i++) {
      final featureName = _numericalFeatures[i];
      final raw = numericalValues[featureName] ?? 0.0;
      scaled[i] = (raw - _scalerMeans[i]) / _scalerScales[i];
    }

    // 2. OneHotEncoder transform
    final oheVec = <double>[];
    for (final catCol in _categoricalFeatures) {
      final value = categoricalValues[catCol] ?? '';
      final categories = _oheCategories[catCol]!;
      for (final cat in categories) {
        oheVec.add(value == cat ? 1.0 : 0.0);
      }
    }

    // 3. Concatenate: [scaled_numerical, one_hot_encoded]
    final features = [...scaled, ...oheVec];
    assert(features.length == _nFeatures,
        'Expected $_nFeatures features, got ${features.length}');

    // 4. Logistic regression: logits = W·x + b
    final logits = List<double>.filled(_nClasses, 0);
    for (var c = 0; c < _nClasses; c++) {
      var sum = _intercepts[c];
      for (var f = 0; f < _nFeatures; f++) {
        sum += _coefficients[c][f] * features[f];
      }
      logits[c] = sum;
    }

    // 5. Softmax
    final probs = _softmax(logits);

    // 6. Argmax
    var maxIndex = 0;
    for (var i = 1; i < _nClasses; i++) {
      if (probs[i] > probs[maxIndex]) maxIndex = i;
    }

    final probMap = <String, double>{};
    for (var i = 0; i < _nClasses; i++) {
      probMap[_classLabels[i]] = probs[i];
    }

    return GaitPrediction(
      label: _classLabels[maxIndex],
      classIndex: maxIndex,
      confidence: probs[maxIndex],
      probabilities: probMap,
      timestamp: DateTime.now(),
    );
  }

  /// Predict from a flat feature map (convenience method).
  ///
  /// Expects all feature names as keys, with numerical values as doubles.
  /// Task and session must be specified separately.
  GaitPrediction predictFromSession({
    required Map<String, double> sessionFeatures,
    String task = 'task_normal',
    String session = 'time01',
  }) {
    return predict(
      numericalValues: sessionFeatures,
      categoricalValues: {'task': task, 'session': session},
    );
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  /// List of numerical feature names the model expects.
  List<String> get numericalFeatures => List.unmodifiable(_numericalFeatures);

  /// Class labels the model can predict.
  List<String> get classLabels => List.unmodifiable(_classLabels);
}
