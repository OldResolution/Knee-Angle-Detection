import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class StepCounterScreen extends StatelessWidget {
  const StepCounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      drawer: const AppDrawer(currentRoute: 'Step Counter'),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Motion',
                              style: TextStyle(
                                fontSize: ResponsiveLayout.headlineSize(context),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4C3E8A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tracking your kinetic journey for optimal recovery.',
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                              overflow: TextOverflow.visible,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F4F7),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Color(0xFF4C3E8A)),
                            SizedBox(width: 8),
                            Text('Today', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A))),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > ResponsiveLayout.tabletMaxWidth) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _buildTotalStepsCard(context)),
                            const SizedBox(width: 24),
                            Expanded(flex: 3, child: _buildActiveWearCard(context)),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTotalStepsCard(context),
                            const SizedBox(height: 24),
                            _buildActiveWearCard(context),
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

  Widget _buildTotalStepsCard(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth <= ResponsiveLayout.mobileMaxWidth;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                const Text('You\'re making excellent progress today.', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 20),
                const Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  children: [
                    Text('6,432', style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A))),
                    Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('/ 8,000', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2DCEC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, size: 16, color: Color(0xFF819230)),
                      SizedBox(width: 8),
                      Text('320 kcal burned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 0.8,
                          strokeWidth: 14,
                          backgroundColor: Color(0xFFEFEFFB),
                          color: Color(0xFF4C3E8A),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_walk, color: Color(0xFF4C3E8A), size: 28),
                              SizedBox(height: 6),
                              Text('80%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text('OF GOAL', style: TextStyle(fontSize: 10, color: Colors.black54, letterSpacing: 1.1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 8),
                    Text('You\'re making excellent progress today.', style: TextStyle(color: Colors.black54)),
                    SizedBox(height: 32),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      children: [
                        Text('6,432', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A))),
                        Text('/ 8,000', style: TextStyle(fontSize: 18, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 0.8,
                      strokeWidth: 20,
                      backgroundColor: Color(0xFFEFEFFB),
                      color: Color(0xFF4C3E8A),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_walk, color: Color(0xFF4C3E8A), size: 32),
                          SizedBox(height: 8),
                          Text('80%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text('OF GOAL', style: TextStyle(fontSize: 10, color: Colors.black54, letterSpacing: 1.1)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveWearCard(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F8),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6CFF0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer, color: Color(0xFF4C3E8A)),
              ),
              const SizedBox(width: 16),
              const Text('Active Wear', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Total active hours wearing the kinetic cap today.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          isMobile
              ? const Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 4,
                  children: [
                    Text('4', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('h', style: TextStyle(fontSize: 18, color: Colors.black87)),
                    SizedBox(width: 6),
                    Text('15', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('m', style: TextStyle(fontSize: 18, color: Colors.black87)),
                  ],
                )
              : const Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('4', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('h ', style: TextStyle(fontSize: 20, color: Colors.black87)),
                    Text('15', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('m', style: TextStyle(fontSize: 20, color: Colors.black87)),
                  ],
                ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.7,
              minHeight: 12,
              backgroundColor: Color(0xFFE2E2E6),
              color: Color(0xFF4C3E8A),
            ),
          ),
          const SizedBox(height: 12),
          isMobile
              ? const Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text('Target: 6 hours', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('1h 45m remaining', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target: 6 hours', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('1h 45m remaining', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
                  ],
                ),
        ],
      ),
    );
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
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
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
