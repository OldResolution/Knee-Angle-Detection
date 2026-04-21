import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/goals_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class StepCounterScreen extends ConsumerWidget {
  const StepCounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(userGoalsProvider);
    final steps = ref.watch(todayStepsProvider);
    final stepProgress = ref.watch(stepGoalProgressProvider);
    final activeMinutes = ref.watch(todayActiveMinutesProvider);
    final calories = steps * 0.04;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(currentRoute: 'Step Counter'),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0), // Use same nav
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning, Alex',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You're ${goals.dailyStepGoal - steps} steps from your target",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFE2E2E6),
                        child: Icon(Icons.person, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > ResponsiveLayout.tabletMaxWidth) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildTotalStepsCard(
                                context,
                                steps: steps,
                                goal: goals.dailyStepGoal,
                                progress: stepProgress,
                                calories: calories,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 3,
                              child: _buildActiveWearCard(
                                context,
                                activeMinutes: activeMinutes,
                                goalHours: goals.activeHoursGoal,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTotalStepsCard(
                              context,
                              steps: steps,
                              goal: goals.dailyStepGoal,
                              progress: stepProgress,
                              calories: calories,
                            ),
                            const SizedBox(height: 24),
                            _buildActiveWearCard(
                              context,
                              activeMinutes: activeMinutes,
                              goalHours: goals.activeHoursGoal,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildHourlyActivityCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalStepsCard(
    BuildContext context, {
    required int steps,
    required int goal,
    required double progress,
    required double calories,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 16,
                    backgroundColor: const Color(0xFFF2F2F6),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${(progress * 100).round()}% of Goal', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(_formatInt(steps), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.1)),
                        const SizedBox(height: 4),
                        Text('${_formatInt(goal)} steps', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${calories.toStringAsFixed(0)} kcal burned', style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveWearCard(
    BuildContext context, {
    required int activeMinutes,
    required double goalHours,
  }) {
    final goalMinutes = (goalHours * 60).round();
    final progress = (activeMinutes / goalMinutes).clamp(0.0, 1.0);
    final activeHoursPart = activeMinutes ~/ 60;
    final activeMinutesPart = activeMinutes % 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Active Wear', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${activeHoursPart}h ${activeMinutesPart}m', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E2E6),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
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

  Widget _buildHourlyActivityCard(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hourly Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 8),
                    Text('Step distribution throughout the day', style: TextStyle(color: Colors.black54), overflow: TextOverflow.visible),
                  ],
                ),
              ),
              if (!isMobile)
                Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: const Text('Week', style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
                )
            ],
          ),
          SizedBox(height: isMobile ? 28 : 48),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
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
                          case 0: text = const Text('8 AM', style: style); break;
                          case 2: text = const Text('10 AM', style: style); break;
                          case 4: text = const Text('12 PM', style: style); break;
                          case 6: text = const Text('2 PM', style: style); break;
                          case 8: text = const Text('4 PM', style: style); break;
                          case 10: text = const Text('6 PM', style: style); break;
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
                barGroups: [
                  _makeGroupData(0, 10, isLight: true),
                  _makeGroupData(1, 20, isLight: true),
                  _makeGroupData(2, 60, isDark: true),
                  _makeGroupData(3, 30, isLight: true),
                  _makeGroupData(4, 15, isLight: true),
                  _makeGroupData(5, 45, isLight: true),
                  _makeGroupData(6, 90, isDark: true),
                  _makeGroupData(7, 40, isLight: true),
                  _makeGroupData(8, 25, isLight: true),
                  _makeGroupData(9, 5, isLight: true),
                  _makeGroupData(10, 5, isLight: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, {bool isDark = false, bool isLight = false}) {
    Color barColor = isDark ? const Color(0xFF4C3E8A) : (isLight ? const Color(0xFFE2DCEC) : const Color(0xFFC4B8E1));
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: 36,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}
