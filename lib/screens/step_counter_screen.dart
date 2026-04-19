import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/app_footer.dart';

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
              padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Daily Motion',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4C3E8A),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tracking your kinetic journey for optimal recovery.',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F4F7),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.calendar_today, size: 16, color: Color(0xFF4C3E8A)),
                            SizedBox(width: 8),
                            Text('Today', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A))),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildTotalStepsCard(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 3,
                        child: _buildActiveWearCard(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildHourlyActivityCard(),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildTotalStepsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                const Text('You\'re making excellent progress today.', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text('6,432', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A))),
                    SizedBox(width: 8),
                    Text('/ 8,000', style: TextStyle(fontSize: 18, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2DCEC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.local_fire_department, size: 16, color: Color(0xFF819230)),
                      SizedBox(width: 8),
                      Text('320 kcal burned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
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
                  backgroundColor: const Color(0xFFEFEFFB),
                  color: const Color(0xFF4C3E8A),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
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
      ),
    );
  }

  Widget _buildActiveWearCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F8),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Target: 6 hours', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text('1h 45m remaining', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyActivityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Hourly Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 8),
                  Text('Step distribution throughout the day', style: TextStyle(color: Colors.black54)),
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
          const SizedBox(height: 48),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
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
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
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
