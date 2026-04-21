
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../services/ble_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(currentRoute: 'Live Knee Angle'),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveLayout.horizontalPadding(context),
                  vertical: ResponsiveLayout.verticalPadding(context),
                ),
                child: ResponsiveLayout.constrainedPage(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderRow(liveActive: liveActive, pulseController: _pulseController),
                      SizedBox(height: ResponsiveLayout.sectionGap(context)),
                      Center(
                        child: _GaugeCard(
                          angle: latest?.angle ?? 0,
                          target: 120,
                          liveActive: liveActive,
                        ),
                      ),
                      SizedBox(height: ResponsiveLayout.sectionGap(context)),
                      const RepaintBoundary(child: _ThrottledLiveChart()),
                      SizedBox(height: ResponsiveLayout.sectionGap(context)),
                      _SessionTargetCard(target: 85.0, current: latest?.angle ?? 0),
                      SizedBox(height: ResponsiveLayout.sectionGap(context)),
                      _buildBottomMetrics(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMetrics(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          const _BottomMetricCard(
            title: 'Extension Target Met',
            subtitle: 'Consistent full extension achieved in the last 3 rotations. Keep up the steady pace.',
            icon: Icons.check_circle,
            iconColor: Color(0xFF4C3E8A),
            bgColor: Color(0xFFE2DCEC),
          ),
          const _BottomMetricCard(
            title: 'Smoothness Score: 92',
            subtitle: 'Kinematic flow is exceptionally fluid. Micro-stutters detected have decreased by 14%.',
            icon: Icons.water_drop,
            iconColor: Color(0xFFF9A825),
            bgColor: Color(0xFFFFF59D),
          ),
        ];

        if (constraints.maxWidth > ResponsiveLayout.tabletMaxWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          );
        }

        return Column(
          children: [
            cards[0],
            const SizedBox(height: 16),
            cards[1],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, size: 26),
                onPressed: () => Scaffold.of(context).openDrawer(),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveLayout.horizontalPadding(context) * 0.5, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
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
                        color: liveActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      liveActive ? 'Streaming Data Active' : 'Idle',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: ResponsiveLayout.isMobile(context) ? 11 : 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Live Kinematics', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        Text('Real-time analysis of your patellar mobility.', style: Theme.of(context).textTheme.bodyLarge),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxAvailable = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width - (ResponsiveLayout.horizontalPadding(context) * 2);
        final gaugeSize = min(320.0, maxAvailable * 0.9).clamp(200.0, 320.0);
        final numberFontSize = max(28.0, gaugeSize * 0.25);
        final labelFontSize = max(10.0, gaugeSize * 0.045);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: gaugeSize,
              height: gaugeSize,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: angle.clamp(0, 180).toDouble()),
                duration: const Duration(milliseconds: 260),
                builder: (context, value, _) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _RadialGaugePainter(
                          value: value,
                          target: target,
                          isBreached: isBreached,
                          isCritical: isCritical,
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: gaugeSize * 0.08),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: gaugeSize * 0.72,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${value.toStringAsFixed(0)}°',
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: numberFontSize,
                                      fontWeight: FontWeight.w900,
                                      color: isCritical ? const Color(0xFFD32F2F) : const Color(0xFF4C3E8A),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: gaugeSize * 0.72,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'CURRENT FLEXION',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: labelFontSize,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveLayout.horizontalPadding(context), vertical: 6),
              decoration: BoxDecoration(
                color: liveActive ? const Color(0xFFD6EAD8) : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                liveActive ? 'Live telemetry active' : 'Waiting for telemetry',
                style: TextStyle(
                  color: liveActive ? const Color(0xFF2E7D32) : const Color(0xFF616161),
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveLayout.isMobile(context) ? 11 : 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SessionTargetCard extends StatelessWidget {
  const _SessionTargetCard({required this.target, required this.current});
  final double target;
  final double current;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveLayout.horizontalPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Session Target', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A))),
                Icon(Icons.tune, color: Colors.black54, size: 20),
              ],
            ),
            SizedBox(height: ResponsiveLayout.sectionGap(context) * 0.5),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (current / target).clamp(0.0, 1.0),
                      minHeight: 16,
                      backgroundColor: const Color(0xFFE2E2E6),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveLayout.horizontalPadding(context) * 0.5),
                Flexible(child: Text('${target.toInt()}°', style: TextStyle(fontSize: ResponsiveLayout.isMobile(context) ? 16 : 20, fontWeight: FontWeight.bold))),
              ],
            ),
            SizedBox(height: ResponsiveLayout.sectionGap(context) * 0.25),
            Text('Target goal for optimal recovery phase.', style: TextStyle(color: Colors.black54, fontSize: ResponsiveLayout.isMobile(context) ? 12 : 13)),
          ],
        ),
      ),
    );
  }
}

class _ThrottledLiveChart extends ConsumerWidget {
  const _ThrottledLiveChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveLayout.horizontalPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mobility Trajectory', style: TextStyle(fontSize: ResponsiveLayout.isDesktop(context) ? 22 : 18, fontWeight: FontWeight.bold, color: const Color(0xFF4C3E8A))),
                    SizedBox(height: ResponsiveLayout.sectionGap(context) * 0.2),
                    Text('Last 15 minutes of movement', style: TextStyle(color: Colors.black54, fontSize: ResponsiveLayout.isMobile(context) ? 11 : 13)),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F4F7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C3E8A),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text('Live', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: const Text('Session', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveLayout.sectionGap(context)),
            SizedBox(
              height: ResponsiveLayout.isMobile(context) ? 160 : 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: max(300.0, MediaQuery.of(context).size.width - (ResponsiveLayout.horizontalPadding(context) * 2)),
                  child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 180,
                  barTouchData: const BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(color: Colors.black54, fontSize: 12);
                          Widget text;
                          switch (value.toInt()) {
                            case 0: text = const Text('-15m', style: style); break;
                            case 3: text = const Text('-10m', style: style); break;
                            case 6: text = const Text('-5m', style: style); break;
                            case 9: text = const Text('Now', style: style); break;
                            default: text = const Text('', style: style); break;
                          }
                          return text;
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(10, (index) {
                    final isPeak = index == 6;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: 40 + (index * 12.0) % 80 + (isPeak ? 40 : 0),
                          color: const Color(0xFF4C3E8A).withValues(alpha: 0.7 + (index * 0.03)),
                          width: 28,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _BottomMetricCard extends StatelessWidget {
  const _BottomMetricCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveLayout.horizontalPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveLayout.isMobile(context) ? 6 : 8),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: iconColor, size: ResponsiveLayout.isMobile(context) ? 18 : 20),
                ),
                SizedBox(width: ResponsiveLayout.horizontalPadding(context) * 0.5),
                Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: ResponsiveLayout.isMobile(context) ? 14 : 16, fontWeight: FontWeight.bold))),
              ],
            ),
            SizedBox(height: ResponsiveLayout.sectionGap(context) * 0.5),
            Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black87, fontSize: ResponsiveLayout.isMobile(context) ? 12 : 13, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  _RadialGaugePainter({required this.value, required this.target, required this.isBreached, required this.isCritical});

  final double value;
  final double target;
  final bool isBreached;
  final bool isCritical;

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = pi / 2;
    const sweepMax = pi * 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;

    final basePaint = Paint()
      ..color = const Color(0xFFE2DCEC)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 20;

    final valueColor = isCritical ? const Color(0xFFD32F2F) : const Color(0xFF4C3E8A);
    final valuePaint = Paint()
      ..color = valueColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 20;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, sweepMax, false, basePaint);

    final normalized = (value / 180).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepMax * normalized,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.target != target || oldDelegate.isBreached != isBreached || oldDelegate.isCritical != isCritical;
  }
}