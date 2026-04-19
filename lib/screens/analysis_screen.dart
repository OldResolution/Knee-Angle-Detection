import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/app_footer.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      drawer: const AppDrawer(currentRoute: 'Analysis'),
      body: Column(
        children: [
          const AppTopNav(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance & Analysis',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C3E8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete diagnostic overview and historical kinetic data.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildMetricsColumn(),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 5,
                        child: _buildProgressChartCard(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildAIReportCard(),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildMetricsColumn() {
    return Column(
      children: [
        _buildStatCard('Symmetry Index', '94%', true, Icons.balance),
        const SizedBox(height: 16),
        _buildStatCard('Gait Velocity', '1.2 m/s', true, Icons.speed),
        const SizedBox(height: 16),
        _buildStatCard('Joint Load', 'Normal', false, Icons.monitor_weight),
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
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
              const Text('Historical Flexion Trajectory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A))),
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
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
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
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF5A4D9A).withOpacity(0.3),
                          const Color(0xFF5A4D9A).withOpacity(0.0),
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

  Widget _buildAIReportCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology, color: Color(0xFF4C3E8A), size: 28),
              SizedBox(width: 12),
              Text('AI Kinetic Assessment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'The data aggregated from your kinetic cap indicates a consistently ascending recovery profile. Joint load has normalized entirely, and gait symmetry matches clinical baselines for post-op week 8. The step variance between your left and right leg is within a 2% margin of error, designating excellent recovery.',
            style: TextStyle(height: 1.6, color: Colors.black87, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text('Export Medical Dossier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C3E8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          )
        ],
      ),
    );
  }
}
