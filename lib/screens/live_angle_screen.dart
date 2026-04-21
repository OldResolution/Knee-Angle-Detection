import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/knee_data_point.dart';
import '../services/ble_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class LiveAngleScreen extends ConsumerStatefulWidget {
  const LiveAngleScreen({super.key});

  @override
  ConsumerState<LiveAngleScreen> createState() => _LiveAngleScreenState();
}

class _LiveAngleScreenState extends ConsumerState<LiveAngleScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(kneeDataHistoryProvider);
    final current = ref.watch(currentKneeDataProvider);
    final liveActive = ref.watch(isLiveDataActiveProvider);

    final latest = current ?? (history.isNotEmpty ? history.last : null);
    final peakToday = history.isEmpty
        ? 0.0
        : history.map((point) => point.angle).reduce((left, right) => left > right ? left : right);

    final sessionDuration = history.length < 2
        ? Duration.zero
        : history.last.timestamp.difference(history.first.timestamp);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      drawer: const AppDrawer(currentRoute: 'Live Knee Angle'),
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
                  _HeaderRow(liveActive: liveActive, pulseController: _pulseController),
                  SizedBox(height: ResponsiveLayout.sectionGap(context)),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > ResponsiveLayout.tabletMaxWidth;

                      final gaugeCard = _GaugeCard(
                        angle: latest?.angle ?? 0,
                        target: 120,
                        liveActive: liveActive,
                      );

                      final metricsCard = _MetricsCard(
                        current: latest,
                        peakToday: peakToday,
                        sessionDuration: sessionDuration,
                      );

                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: gaugeCard),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: metricsCard),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          gaugeCard,
                          const SizedBox(height: 16),
                          metricsCard,
                        ],
                      );
                    },
                  ),
                  SizedBox(height: ResponsiveLayout.sectionGap(context)),
                  const RepaintBoundary(child: _ThrottledLiveChart()),
                  SizedBox(height: ResponsiveLayout.sectionGap(context)),
                  _buildBottomMetrics(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMetrics(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          const _BottomMetricCard(
            title: 'Daily Steps',
            value: '2,481 / 5,000',
            icon: Icons.directions_walk,
            color: Color(0xFFD6CFF0),
          ),
          const _BottomMetricCard(
            title: 'Active Minutes',
            value: '42 min',
            icon: Icons.show_chart,
            color: Color(0xFFE5E0CB),
          ),
          const _BottomMetricCard(
            title: 'Recovery Score',
            value: 'A- Excellent',
            icon: Icons.insights,
            color: Color(0xFFDAE4C4),
          ),
        ];

        if (constraints.maxWidth > ResponsiveLayout.tabletMaxWidth) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
              const SizedBox(width: 16),
              Expanded(child: cards[2]),
            ],
          );
        }

        return Column(
          children: [
            cards[0],
            const SizedBox(height: 12),
            cards[1],
            const SizedBox(height: 12),
            cards[2],
          ],
        );
      },
    );
  }
}

class _HeaderRow extends ConsumerWidget {
  const _HeaderRow({
    required this.liveActive,
    required this.pulseController,
  });

  final bool liveActive;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertCount = ref.watch(activeAlertCountProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Knee Monitoring',
                style: TextStyle(
                  fontSize: ResponsiveLayout.headlineSize(context),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4C3E8A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Continuous joint telemetry from BLE feed with angle, speed, and activity states.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            // ── Alert Badge ──
            if (alertCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$alertCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                final scale = liveActive ? (0.9 + pulseController.value * 0.3) : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: liveActive ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              liveActive ? 'streaming' : 'idle',
              style: TextStyle(
                color: liveActive ? const Color(0xFF2E7D32) : const Color(0xFF757575),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GaugeCard extends ConsumerWidget {
  const _GaugeCard({
    required this.angle,
    required this.target,
    required this.liveActive,
  });

  final double angle;
  final double target;
  final bool liveActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(analysisConfigProvider);
    final isBreached = angle > config.maxAngleThreshold ||
        angle < config.minAngleThreshold;
    final isCritical = angle > config.maxAngleThreshold;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E6EB),
        borderRadius: BorderRadius.circular(16),
        border: isBreached
            ? Border.all(
                color: isCritical
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFFF9A825),
                width: 2.5,
              )
            : Border.all(color: Colors.transparent, width: 2.5),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: angle.clamp(0, 180).toDouble()),
              duration: const Duration(milliseconds: 260),
              builder: (context, value, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _RadialGaugePainter(value: value, target: target),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${value.toStringAsFixed(1)} deg',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'CURRENT ANGLE',
                            style: TextStyle(fontSize: 10, color: Colors.black54, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: liveActive ? const Color(0xFFD6EAD8) : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              liveActive ? 'Live telemetry active' : 'Waiting for telemetry',
              style: TextStyle(
                color: liveActive ? const Color(0xFF2E7D32) : const Color(0xFF616161),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({
    required this.current,
    required this.peakToday,
    required this.sessionDuration,
  });

  final KneeDataPoint? current;
  final double peakToday;
  final Duration sessionDuration;

  @override
  Widget build(BuildContext context) {
    final data = <MapEntry<String, String>>[
      MapEntry('Current Angle', current == null ? '--' : '${current!.angle.toStringAsFixed(1)} deg'),
      MapEntry('Movement Speed', current == null ? '--' : '${current!.speed.toStringAsFixed(1)} deg/s'),
      MapEntry('Activity', current == null ? '--' : current!.activityType.displayName),
      MapEntry('Peak Today', peakToday == 0 ? '--' : '${peakToday.toStringAsFixed(1)} deg'),
      MapEntry('Session Duration', _formatDuration(sessionDuration)),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: data
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    Text(
                      entry.value,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ThrottledLiveChart extends ConsumerStatefulWidget {
  const _ThrottledLiveChart();

  @override
  ConsumerState<_ThrottledLiveChart> createState() => _ThrottledLiveChartState();
}

class _ThrottledLiveChartState extends ConsumerState<_ThrottledLiveChart> {
  List<KneeDataPoint> _latest = const [];
  List<KneeDataPoint> _rendered = const [];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _rendered = _latest;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<KneeDataPoint>>(kneeDataHistoryProvider, (_, next) {
      _latest = next;
    });

    final points = _rendered;
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].angle));
    }

    final maxX = points.isEmpty ? 60.0 : max(60.0, points.length.toDouble());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Real-Time Angle Graph',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 30,
                  verticalInterval: 20,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFE4E2EA), strokeWidth: 1),
                  getDrawingVerticalLine: (_) => const FlLine(color: Color(0xFFEDEBF2), strokeWidth: 1),
                ),
                minX: max(0, maxX - 200),
                maxX: maxX,
                minY: 0,
                maxY: 180,
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: 30,
                      getTitlesWidget: (value, _) {
                        return Text('${value.toInt()} deg', style: const TextStyle(fontSize: 10, color: Colors.black54));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 40,
                      getTitlesWidget: (value, _) {
                        return Text('-${(maxX - value).round()}', style: const TextStyle(fontSize: 10, color: Colors.black54));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF5A4D9A),
                    barWidth: 2.8,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF5A4D9A).withValues(alpha: 0.2),
                          const Color(0xFF5A4D9A).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomMetricCard extends StatelessWidget {
  const _BottomMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF4C3E8A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  _RadialGaugePainter({required this.value, required this.target});

  final double value;
  final double target;

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = -pi * 3 / 4;
    const sweepMax = pi * 3 / 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;

    final basePaint = Paint()
      ..color = const Color(0xFFDCDAF0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16;

    final valuePaint = Paint()
      ..color = const Color(0xFF5A4D9A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepMax, false, basePaint);

    final normalized = (value / 180).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepMax * normalized,
      false,
      valuePaint,
    );

    final markerAngle = startAngle + sweepMax * (target / 180).clamp(0.0, 1.0);
    final markerPosition = Offset(
      center.dx + cos(markerAngle) * radius,
      center.dy + sin(markerAngle) * radius,
    );

    final markerPaint = Paint()..color = const Color(0xFF1B3B4A);
    canvas.drawCircle(markerPosition, 5, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.target != target;
  }
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
