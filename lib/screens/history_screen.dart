import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log.dart';
import '../models/knee_data_point.dart';
import '../models/session_record.dart';
import '../services/session_providers.dart';
import '../services/simulation_analytics_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionHistoryProvider);
    final todayLogAsync = ref.watch(dailyLogProvider(DateTime.now()));
    final trend7Async = ref.watch(trendDataProvider(7));
    final trend30Async = ref.watch(trendDataProvider(30));
    final isSimulationMode = ref.watch(simulationModeProvider);
    final simulatedTrend7 = ref.watch(simulatedTrendLogsProvider(7));
    final simulatedTrend30 = ref.watch(simulatedTrendLogsProvider(30));
    final simulatedSessions = ref.watch(simulatedSessionsProvider);

    final realTodayLog = todayLogAsync.valueOrNull;
    final resolvedTodayLog = _hasMeaningfulDailyLog(realTodayLog)
        ? realTodayLog
        : (isSimulationMode ? simulatedTrend7.last : null);
    final trend7Logs = _hasMeaningfulTrend(trend7Async.valueOrNull)
        ? trend7Async.valueOrNull!
        : (isSimulationMode ? simulatedTrend7 : const <DailyLog>[]);
    final trend30Logs = _hasMeaningfulTrend(trend30Async.valueOrNull)
        ? trend30Async.valueOrNull!
        : (isSimulationMode ? simulatedTrend30 : const <DailyLog>[]);
    final sessionItems = (sessionsAsync.valueOrNull?.isNotEmpty ?? false)
        ? sessionsAsync.valueOrNull!
        : (isSimulationMode ? simulatedSessions : const <SessionRecord>[]);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      drawer: const AppDrawer(currentRoute: 'History'),
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
                  const SizedBox(height: 24),
                  _buildDateFilter(context),
                  const SizedBox(height: 24),
                  if (resolvedTodayLog != null)
                    _buildDailySummary(resolvedTodayLog)
                  else
                    todayLogAsync.when(
                      data: _buildDailySummary,
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  const SizedBox(height: 24),
                  _buildTrendChart(
                    title: '7-Day Trend',
                    subtitle: isSimulationMode &&
                            !_hasMeaningfulTrend(trend7Async.valueOrNull)
                        ? 'Average angle and daily steps from the active simulation pattern'
                        : 'Average angle and daily steps',
                    logs: trend7Logs,
                    showGoalMarkers: false,
                  ),
                  const SizedBox(height: 24),
                  _buildTrendChart(
                    title: '30-Day Trend',
                    subtitle: isSimulationMode &&
                            !_hasMeaningfulTrend(trend30Async.valueOrNull)
                        ? 'Monthly flexion trajectory projected from simulation mode'
                        : 'Monthly flexion trajectory with goal markers',
                    logs: trend30Logs,
                    showGoalMarkers: true,
                  ),
                  const SizedBox(height: 24),
                  _buildSessionList(sessionItems),
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
          'Session History',
          style: TextStyle(
            fontSize: ResponsiveLayout.headlineSize(context),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4C3E8A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Review session outcomes, daily summary, and trend progression.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    final label = _selectedRange == null
        ? 'All dates'
        : '${_fmtDate(_selectedRange!.start)} to ${_fmtDate(_selectedRange!.end)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Date Range',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 2),
              lastDate: now,
              initialDateRange: _selectedRange,
            );
            if (picked != null) {
              setState(() {
                _selectedRange = picked;
              });
            }
          },
          icon: const Icon(Icons.date_range),
          label: Text(label),
        ),
      ],
    );
  }

  Widget _buildDailySummary(DailyLog log) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          _metric('Steps', log.totalSteps.toString()),
          _metric('Calories', log.totalCalories.toStringAsFixed(1)),
          _metric('Active Time', '${log.totalActiveMinutes} min'),
          _metric('Sessions', log.totalSessions.toString()),
          _metric('Avg Angle', '${log.avgKneeAngle.toStringAsFixed(1)} deg'),
          _metric('Peak Angle', '${log.peakKneeAngle.toStringAsFixed(1)} deg'),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4C3E8A))),
        ],
      ),
    );
  }

  Widget _buildTrendChart({
    required String title,
    required String subtitle,
    required List<DailyLog> logs,
    required bool showGoalMarkers,
  }) {
    final angleSpots = <FlSpot>[];
    final stepSpots = <FlSpot>[];
    final markers = <FlSpot>[];

    for (var i = 0; i < logs.length; i++) {
      angleSpots.add(FlSpot(i.toDouble(), logs[i].avgKneeAngle));
      stepSpots.add(FlSpot(i.toDouble(), logs[i].totalSteps.toDouble() / 100));
      if (showGoalMarkers &&
          (logs[i].goalStepsMet ||
              logs[i].goalExerciseMet ||
              logs[i].goalActiveHoursMet)) {
        markers.add(FlSpot(i.toDouble(), logs[i].avgKneeAngle));
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: logs.isEmpty ? 1 : (logs.length - 1).toDouble(),
                minY: 0,
                maxY: 180,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: logs.length > 14 ? 4 : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= logs.length) {
                          return const SizedBox.shrink();
                        }
                        final date = logs[index].date;
                        return Text('${date.month}/${date.day}',
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: angleSpots,
                    color: const Color(0xFF4C3E8A),
                    isCurved: true,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: stepSpots,
                    color: const Color(0xFF819230),
                    isCurved: true,
                    barWidth: 2,
                    dashArray: const [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  if (markers.isNotEmpty)
                    LineChartBarData(
                      spots: markers,
                      isCurved: false,
                      color: Colors.transparent,
                      barWidth: 0,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFFD32F2F),
                          strokeWidth: 1,
                          strokeColor: Colors.white,
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

  Widget _buildSessionList(List<SessionRecord> sessions) {
    final filtered = _selectedRange == null
        ? sessions
        : sessions.where((session) {
            final start = DateTime(
              session.startTime.year,
              session.startTime.month,
              session.startTime.day,
            );
            return !start.isBefore(_selectedRange!.start) &&
                !start.isAfter(_selectedRange!.end);
          }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Text('No sessions recorded yet.')
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final item = filtered[index];
                final duration = item.duration;
                final mins = duration.inMinutes;
                final secs = duration.inSeconds % 60;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${_fmtDate(item.startTime)} ${_fmtTime(item.startTime)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Duration ${mins}m ${secs}s  |  Avg ${item.avgAngle.toStringAsFixed(1)} deg  |  Steps ${item.totalSteps}  |  ${item.gaitLabel ?? item.dominantActivity.displayName}',
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _fmtTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _hasMeaningfulDailyLog(DailyLog? log) {
    if (log == null) {
      return false;
    }
    return log.totalSteps > 0 ||
        log.totalActiveMinutes > 0 ||
        log.totalSessions > 0 ||
        log.avgKneeAngle > 0;
  }

  bool _hasMeaningfulTrend(List<DailyLog>? logs) {
    if (logs == null || logs.isEmpty) {
      return false;
    }
    return logs.any(_hasMeaningfulDailyLog);
  }
}
