import 'dart:math';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/knee_data_point.dart';
import '../services/ble_providers.dart';
import '../services/goals_providers.dart';
import '../services/simulation_analytics_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<GoalCompletionSignal?>(goalCompletionNotifierProvider,
        (previous, next) {
      if (next == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.message),
          backgroundColor: next.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    final current = ref.watch(currentKneeDataProvider);
    final history = ref.watch(kneeDataHistoryProvider);
    final liveActive = ref.watch(isLiveDataActiveProvider);
    final goals = ref.watch(userGoalsProvider);
    final steps = ref.watch(todayStepsProvider);
    final activeMinutes = ref.watch(todayActiveMinutesProvider);
    final activeHours = activeMinutes / 60.0;
    final insights = ref.watch(dashboardInsightProvider);
    final isSimulationMode = ref.watch(simulationModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(currentRoute: 'Dashboard'),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
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
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >
                          ResponsiveLayout.tabletMaxWidth) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _buildLiveChartCard(
                                      context, current, history, liveActive),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total Steps',
                                          '${_formatInt(steps)} / ${_formatInt(goals.dailyStepGoal)} goal',
                                          Icons.directions_walk,
                                          const Color(0xFFD6CFF0),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Active Wear Hours',
                                          '${activeHours.toStringAsFixed(1)} hrs today',
                                          Icons.access_time_filled,
                                          const Color(0xFFE5E0CB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 3,
                              child: _buildSystemAnalysisPanel(
                                insights,
                                isSimulationMode: isSimulationMode,
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _buildLiveChartCard(
                              context, current, history, liveActive),
                          const SizedBox(height: 24),
                          _buildStatCard(
                            'Total Steps',
                            '${_formatInt(steps)} / ${_formatInt(goals.dailyStepGoal)} goal',
                            Icons.directions_walk,
                            const Color(0xFFD6CFF0),
                          ),
                          const SizedBox(height: 24),
                          _buildStatCard(
                            'Active Wear Hours',
                            '${activeHours.toStringAsFixed(1)} hrs today',
                            Icons.access_time_filled,
                            const Color(0xFFE5E0CB),
                          ),
                          const SizedBox(height: 32),
                          _buildSystemAnalysisPanel(
                            insights,
                            isSimulationMode: isSimulationMode,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Knee Health Dashboard',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Real-time metrics and recovery insights.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildLiveChartCard(BuildContext context, KneeDataPoint? current,
      List<KneeDataPoint> history, bool liveActive) {
    // Only process the visible window of points for performance
    final visibleCount = 100;
    final startIndex = max(0, history.length - visibleCount);
    final visiblePoints = history.skip(startIndex).toList();

    final spots = <FlSpot>[];
    for (var i = 0; i < visiblePoints.length; i++) {
      spots.add(FlSpot((startIndex + i).toDouble(), visiblePoints[i].angle));
    }

    final currentAngle =
        current?.angle ?? (history.isNotEmpty ? history.last.angle : 0.0);
    final maxX = history.isEmpty ? 60.0 : max(60.0, history.length.toDouble());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Knee Angle',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _PulseDot(active: liveActive),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    liveActive
                                        ? 'Streaming Data Active'
                                        : 'Waiting for stream',
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width:
                            90, // Reserved width for 3 digits + decimal + " deg"
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${currentAngle.toStringAsFixed(1)} deg',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4C3E8A),
                                  height: 1,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'CURRENT FLEXION',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Color(0xFF4C3E8A)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 28),
            SizedBox(
              height: 220,
              child: RepaintBoundary(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 45,
                      verticalInterval: 20,
                      getDrawingHorizontalLine: (_) => FlLine(
                          color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                          strokeWidth: 1),
                      getDrawingVerticalLine: (_) => FlLine(
                          color:
                              const Color(0xFF6750A4).withValues(alpha: 0.05),
                          strokeWidth: 1),
                    ),
                    minX: max(0, maxX - 80), // Tighter window for less "travel"
                    maxX: maxX,
                    minY: 0,
                    maxY: 180,
                    clipData: const FlClipData.all(),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 45,
                          getTitlesWidget: (value, _) => Text(
                              '${value.toInt()}°',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black45,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          getTitlesWidget: (value, _) => Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('${(value - maxX).toInt()}s',
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.black38)),
                          ),
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF6750A4),
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6750A4).withValues(alpha: 0.2),
                              const Color(0xFF6750A4).withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color iconBg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: const Color(0xFF4C3E8A)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4C3E8A))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemAnalysisPanel(
    DashboardInsightData insights, {
    required bool isSimulationMode,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'System Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C3E8A),
                    ),
                  ),
                ),
                if (isSimulationMode)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9F5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Simulation',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4C3E8A),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAlertCard(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFF8B7D14),
              bgColor: Colors.white,
              title: insights.primaryTitle,
              message: insights.primaryMessage,
            ),
            const SizedBox(height: 12),
            _buildAlertCard(
              icon: Icons.check_circle,
              iconColor: const Color(0xFF524587),
              bgColor: Colors.white,
              title: insights.secondaryTitle,
              message: insights.secondaryMessage,
            ),
            const SizedBox(height: 24),
            const Text('AI INSIGHT',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(
              insights.aiInsight,
              style:
                  TextStyle(color: Colors.black87, height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('View Detailed Report'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(
      {required IconData icon,
      required Color iconColor,
      required Color bgColor,
      required String title,
      required String message}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(message,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatInt(int value) {
    final source = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < source.length; i++) {
      final indexFromEnd = source.length - i;
      buffer.write(source[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return value < 0 ? '-${buffer.toString()}' : buffer.toString();
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.active});

  final bool active;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
    if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.active ? (0.9 + _controller.value * 0.35) : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color:
              widget.active ? const Color(0xFF819230) : const Color(0xFF9E9E9E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
