import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/knee_data_point.dart';
import '../services/ble_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentKneeDataProvider);
    final history = ref.watch(kneeDataHistoryProvider);
    final liveActive = ref.watch(isLiveDataActiveProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      drawer: const AppDrawer(currentRoute: 'Dashboard'),
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
                      if (constraints.maxWidth > ResponsiveLayout.tabletMaxWidth) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _buildLiveChartCard(context, current, history, liveActive),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(child: _buildStatCard('Total Steps', '4,285 / 6,000 goal', Icons.directions_walk, const Color(0xFFD6CFF0))),
                                      const SizedBox(width: 24),
                                      Expanded(child: _buildStatCard('Active Wear Hours', '6.5 hrs today', Icons.access_time_filled, const Color(0xFFE5E0CB))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(flex: 3, child: _buildSystemAnalysisPanel()),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _buildLiveChartCard(context, current, history, liveActive),
                          const SizedBox(height: 24),
                          _buildStatCard('Total Steps', '4,285 / 6,000 goal', Icons.directions_walk, const Color(0xFFD6CFF0)),
                          const SizedBox(height: 24),
                          _buildStatCard('Active Wear Hours', '6.5 hrs today', Icons.access_time_filled, const Color(0xFFE5E0CB)),
                          const SizedBox(height: 32),
                          _buildSystemAnalysisPanel(),
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
          style: TextStyle(
            fontSize: ResponsiveLayout.headlineSize(context),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4C3E8A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Real-time metrics and recovery insights.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildLiveChartCard(BuildContext context, KneeDataPoint? current, List<KneeDataPoint> history, bool liveActive) {
    final points = history;
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].angle));
    }

    final currentAngle = current?.angle ?? (history.isNotEmpty ? history.last.angle : 0.0);
    final maxX = points.isEmpty ? 60.0 : max(60.0, points.length.toDouble());

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F7),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Knee Angle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _PulseDot(active: liveActive),
                        const SizedBox(width: 8),
                        Text(
                          liveActive ? 'Streaming Data Active' : 'Waiting for stream',
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${currentAngle.toStringAsFixed(1)} deg',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C3E8A),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'CURRENT FLEXION',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF4C3E8A)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 30,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFE4E2EA), strokeWidth: 1),
                  getDrawingVerticalLine: (_) => const FlLine(color: Color(0xFFEDEBF2), strokeWidth: 1),
                ),
                minX: max(0, maxX - 120),
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
                      reservedSize: 42,
                      interval: 30,
                      getTitlesWidget: (value, _) => Text('${value.toInt()} deg', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, _) => Text('-${(maxX - value).round()}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
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
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconBg) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F7),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF4C3E8A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemAnalysisPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E6EB),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A))),
          SizedBox(height: 20),
          Text('AI INSIGHT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          SizedBox(height: 12),
          Text(
            'Live BLE telemetry indicates motion consistency is improving. Continue controlled flexion and extension cycles.',
            style: TextStyle(color: Colors.black54, height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.active});

  final bool active;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
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
          color: widget.active ? const Color(0xFF819230) : const Color(0xFF9E9E9E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
