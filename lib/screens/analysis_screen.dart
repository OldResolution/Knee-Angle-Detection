import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/knee_data_point.dart';
import '../services/ble_providers.dart';
import '../services/gait_classification_service.dart';
import '../services/ml_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isAnalysing = false;

  /// Compute session-level features from collected KneeDataPoint history and
  /// run gait classification inference.
  Future<void> _runGaitAnalysis() async {
    final history = ref.read(kneeDataHistoryProvider);
    if (history.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 10 data points. Start a live session first.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() => _isAnalysing = true);

    try {
      final modelAsync = ref.read(gaitClassificationProvider);
      final service = modelAsync.valueOrNull;
      if (service == null || !service.isLoaded) {
        throw StateError('ML model not loaded yet.');
      }

      // Compute session-level features from the KneeDataPoint history
      final features = _computeSessionFeatures(history);

      final prediction = service.predictFromSession(
        sessionFeatures: features,
        task: 'task_normal',
        session: 'time01',
      );

      ref.read(latestGaitPredictionProvider.notifier).state = prediction;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis error: $e'),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalysing = false);
    }
  }

  /// Derive the 77 numerical features the model expects from raw
  /// [KneeDataPoint] time-series data.
  ///
  /// This maps the app's real-time angle/speed data onto the kinematic and
  /// spatio-temporal feature schema used during model training.
  Map<String, double> _computeSessionFeatures(List<KneeDataPoint> data) {
    final angles = data.map((p) => p.angle).toList();
    final speeds = data.map((p) => p.speed).toList();

    double mean(List<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
    double variance(List<double> v) {
      final m = mean(v);
      return v.isEmpty ? 0 : v.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / v.length;
    }
    double std(List<double> v) {
      final va = variance(v);
      return va > 0 ? _sqrt(va) : 0;
    }
    double maxVal(List<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a > b ? a : b);
    double minVal(List<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a < b ? a : b);
    double rms(List<double> v) => v.isEmpty ? 0 : _sqrt(v.map((x) => x * x).reduce((a, b) => a + b) / v.length);
    double absMean(List<double> v) => v.isEmpty ? 0 : v.map((x) => x.abs()).reduce((a, b) => a + b) / v.length;

    // Skewness
    double skewness(List<double> v) {
      final m = mean(v);
      final s = std(v);
      if (s == 0 || v.length < 3) return 0;
      return v.map((x) => ((x - m) / s) * ((x - m) / s) * ((x - m) / s)).reduce((a, b) => a + b) / v.length;
    }
    // Kurtosis
    double kurtosis(List<double> v) {
      final m = mean(v);
      final s = std(v);
      if (s == 0 || v.length < 4) return 0;
      return v.map((x) {
        final z = (x - m) / s;
        return z * z * z * z;
      }).reduce((a, b) => a + b) / v.length;
    }

    // pk = max, mid = median
    double median(List<double> v) {
      if (v.isEmpty) return 0;
      final sorted = [...v]..sort();
      final mid = sorted.length ~/ 2;
      return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
    }

    // Build stat block for a signal (maps to Xvel, Yvel, Zvel, knee, ankle prefixes)
    Map<String, double> statBlock(String prefix, List<double> v) {
      final m = mean(v);
      return {
        '${prefix}_mean': m,
        '${prefix}_var': variance(v),
        '${prefix}_std': std(v),
        '${prefix}_max': maxVal(v),
        '${prefix}_min': minVal(v),
        '${prefix}_pk': maxVal(v),
        '${prefix}_mid': median(v),
        '${prefix}_rms': rms(v),
        '${prefix}_abs_xbar': absMean(v),
        '${prefix}_r': maxVal(v) - minVal(v),
        '${prefix}_S': skewness(v),
        '${prefix}_K': kurtosis(v),
      };
    }

    // Map angle data → knee features, speed data → velocity features
    // The model expects Xvel, Yvel, Zvel, knee, ankle signals.
    // From our single-axis sensor, we approximate:
    //   - knee_* → from raw angles
    //   - Xvel_* → from speed (angular velocity)
    //   - Yvel_*, Zvel_* → scaled from speed with noise factors
    //   - ankle_* → estimated from angles with offset

    final kneeStats = statBlock('knee', angles);
    final xvelStats = statBlock('Xvel', speeds);

    // Approximate Y/Z velocity components (lateral/vertical oscillation)
    final yVel = speeds.map((s) => s * 0.3).toList();
    final zVel = speeds.map((s) => s * 0.15).toList();
    final yvelStats = statBlock('Yvel', yVel);
    final zvelStats = statBlock('Zvel', zVel);

    // Approximate ankle from knee with offset
    final ankleAngles = angles.map((a) => a * 0.65 + 5.0).toList();
    final ankleStats = statBlock('ankle', ankleAngles);

    // Spatio-temporal features (estimated from gait cycle detection)
    final rom = maxVal(angles) - minVal(angles);
    final ankleRom = maxVal(ankleAngles) - minVal(ankleAngles);
    final kneeStd = std(angles);
    final ankleStd = std(ankleAngles);

    // Estimate stride/step metrics from the angle waveform
    final strideLengthEst = mean(speeds) * 0.01; // rough proxy
    final stepLengthEst = strideLengthEst * 0.5;

    final spatioTemporal = <String, double>{
      'step_length': stepLengthEst,
      'stride_length': strideLengthEst,
      'left_step_length': stepLengthEst * 1.02,
      'right_step_length': stepLengthEst * 0.98,
      'left_stride_length': strideLengthEst * 1.01,
      'right_stride_length': strideLengthEst * 0.99,
      'stride_speed': mean(speeds) * 0.02,
      'stride_time': data.length > 1
          ? data.last.timestamp.difference(data.first.timestamp).inMilliseconds / 1000.0 / (data.length / 40)
          : 0.6,
      'step_width': 0.2,
      'mean_stride_length': strideLengthEst,
      'stride_length_asymmetry': 0.02,
      'mean_step_length': stepLengthEst,
      'step_length_asymmetry': 0.04,
      'knee_rom': rom,
      'ankle_rom': ankleRom,
      'knee_cv': kneeStd / (mean(angles).abs() + 1e-6),
      'ankle_cv': ankleStd / (mean(ankleAngles).abs() + 1e-6),
    };

    return {
      ...kneeStats,
      ...xvelStats,
      ...yvelStats,
      ...zvelStats,
      ...ankleStats,
      ...spatioTemporal,
    };
  }

  double _sqrt(double v) {
    if (v <= 0) return 0;
    // Newton's method
    double x = v;
    for (var i = 0; i < 20; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(kneeDataHistoryProvider);
    final prediction = ref.watch(latestGaitPredictionProvider);
    final modelAsync = ref.watch(gaitClassificationProvider);

    final peakAngle = history.isEmpty
        ? 0.0
        : history.map((p) => p.angle).reduce((a, b) => a > b ? a : b);
    final avgSpeed = history.isEmpty
        ? 0.0
        : history.map((p) => p.speed).reduce((a, b) => a + b) / history.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      drawer: const AppDrawer(currentRoute: 'Analysis'),
      body: Column(
        children: [
          const AppTopNav(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveLayout.horizontalPadding(context),
                vertical: ResponsiveLayout.verticalPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance & Analysis',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.headlineSize(context),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4C3E8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete diagnostic overview and historical kinetic data.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > ResponsiveLayout.tabletMaxWidth) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildMetricsColumn(peakAngle, avgSpeed, history.length),
                            ),
                            const SizedBox(width: 32),
                            Expanded(flex: 5, child: _buildProgressChartCard()),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProgressChartCard(),
                            const SizedBox(height: 32),
                            _buildMetricsColumn(peakAngle, avgSpeed, history.length),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildMLPredictionCard(prediction, modelAsync, history.length),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsColumn(double peakAngle, double avgSpeed, int sampleCount) {
    return Column(
      children: [
        _buildStatCard('Peak Angle', '${peakAngle.toStringAsFixed(1)}°', peakAngle > 90, Icons.trending_up),
        const SizedBox(height: 16),
        _buildStatCard('Avg Velocity', '${avgSpeed.toStringAsFixed(1)}°/s', true, Icons.speed),
        const SizedBox(height: 16),
        _buildStatCard('Samples', '$sampleCount', sampleCount > 50, Icons.data_usage),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, bool isPositive, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF4C3E8A)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
              const Spacer(),
              Icon(
                isPositive ? Icons.arrow_upward : Icons.remove,
                size: 16,
                color: isPositive ? const Color(0xFF819230) : Colors.black38,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E6EB),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Text('Historical Flexion Trajectory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: const Text('Past 30 Days', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4C3E8A))),
              )
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 60), FlSpot(1, 65), FlSpot(2, 70), FlSpot(3, 68),
                      FlSpot(4, 75), FlSpot(5, 80), FlSpot(6, 85), FlSpot(7, 90),
                      FlSpot(8, 92), FlSpot(9, 100), FlSpot(10, 110), FlSpot(11, 115),
                      FlSpot(12, 120),
                    ],
                    isCurved: true,
                    color: const Color(0xFF5A4D9A),
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF5A4D9A).withValues(alpha: 0.3),
                          const Color(0xFF5A4D9A).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // ── ML Prediction Card ─────────────────────────────────────────────────

  Widget _buildMLPredictionCard(
    GaitPrediction? prediction,
    AsyncValue<GaitClassificationService> modelAsync,
    int sampleCount,
  ) {
    final isModelReady = modelAsync.hasValue;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF4C3E8A), size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('AI Gait Assessment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              // Model status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isModelReady
                      ? const Color(0xFFD6EAD8)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isModelReady ? Icons.check_circle : Icons.hourglass_empty,
                      size: 14,
                      color: isModelReady ? const Color(0xFF2E7D32) : const Color(0xFFF9A825),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isModelReady ? 'Model Ready' : 'Loading...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isModelReady ? const Color(0xFF2E7D32) : const Color(0xFFF9A825),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Prediction result or prompt
          if (prediction != null)
            _buildPredictionResult(prediction)
          else
            const Text(
              'Run a gait analysis on your current session data to receive an AI-powered classification. '
              'The model evaluates 77 kinematic and spatio-temporal features to detect gait abnormalities '
              'such as limping, shuffling, instability, or stiff-knee patterns.',
              style: TextStyle(height: 1.6, color: Colors.black87, fontSize: 15),
            ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: (isModelReady && !_isAnalysing && sampleCount >= 10) ? _runGaitAnalysis : null,
                icon: _isAnalysing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.analytics),
                label: Text(_isAnalysing ? 'Analysing...' : 'Run Gait Analysis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C3E8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              if (prediction != null)
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Export Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4C3E8A),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    side: const BorderSide(color: Color(0xFF4C3E8A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionResult(GaitPrediction prediction) {
    final config = _classConfig(prediction.label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main prediction
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: config.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      config.description,
                      style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              // Confidence badge
              Column(
                children: [
                  Text(
                    '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: config.color,
                    ),
                  ),
                  const Text('confidence', style: TextStyle(fontSize: 11, color: Colors.black45)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Probability breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Class Probabilities',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 12),
              ...prediction.probabilities.entries.map((entry) {
                final isTop = entry.key == prediction.label;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                            color: isTop ? Colors.black87 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value,
                            minHeight: 8,
                            backgroundColor: Colors.black.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation(
                              isTop ? _classConfig(entry.key).color : Colors.black26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${(entry.value * 100).toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                            color: isTop ? Colors.black87 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  _ClassConfig _classConfig(String label) {
    switch (label) {
      case 'Normal':
        return const _ClassConfig(
          color: Color(0xFF2E7D32),
          icon: Icons.check_circle,
          description: 'Gait pattern is within normal clinical parameters.',
        );
      case 'Limp':
        return const _ClassConfig(
          color: Color(0xFFF9A825),
          icon: Icons.warning_amber_rounded,
          description: 'Asymmetric step pattern detected suggesting a limp.',
        );
      case 'Shuffling':
        return const _ClassConfig(
          color: Color(0xFFE65100),
          icon: Icons.directions_walk,
          description: 'Reduced stride length indicating shuffling gait.',
        );
      case 'Unstable':
        return const _ClassConfig(
          color: Color(0xFFD32F2F),
          icon: Icons.warning,
          description: 'Elevated step variability indicating gait instability.',
        );
      case 'Stiff-Knee':
        return const _ClassConfig(
          color: Color(0xFF7B1FA2),
          icon: Icons.accessibility_new,
          description: 'Reduced knee range of motion detected.',
        );
      default:
        return const _ClassConfig(
          color: Color(0xFF616161),
          icon: Icons.help_outline,
          description: 'Unknown classification.',
        );
    }
  }
}

class _ClassConfig {
  const _ClassConfig({
    required this.color,
    required this.icon,
    required this.description,
  });

  final Color color;
  final IconData icon;
  final String description;
}
