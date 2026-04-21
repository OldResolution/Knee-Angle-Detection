import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class LiveAngleScreen extends StatelessWidget {
  const LiveAngleScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    'Morning Recovery Session',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.headlineSize(context),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4C3E8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome back, your knee flexion has improved by 4% since yesterday.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  SizedBox(height: ResponsiveLayout.sectionGap(context)),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > ResponsiveLayout.tabletMaxWidth) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _buildMobilityGoalCard(context)),
                            const SizedBox(width: 24),
                            Expanded(flex: 3, child: _buildPainManagementCard(context)),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMobilityGoalCard(context),
                            SizedBox(height: ResponsiveLayout.sectionGap(context)),
                            _buildPainManagementCard(context),
                          ],
                        );
                      }
                    },
                  ),
                  SizedBox(height: ResponsiveLayout.sectionGap(context)),
                  _buildMetricsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > ResponsiveLayout.tabletMaxWidth;
        final isTablet = constraints.maxWidth > ResponsiveLayout.mobileMaxWidth;

        if (isDesktop) {
          return Row(
            children: [
              Expanded(child: _buildMetricCard(context, 'DAILY STEPS', '2,481 / 5,000', Icons.directions_walk, 0.5)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard(context, 'ACTIVE MINUTES', '42 min', Icons.show_chart, 0.7)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard(context, 'RECOVERY SCORE', 'A- Excellent', Icons.insights, 0.9)),
            ],
          );
        }

        if (isTablet) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildMetricCard(context, 'DAILY STEPS', '2,481 / 5,000', Icons.directions_walk, 0.5)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard(context, 'ACTIVE MINUTES', '42 min', Icons.show_chart, 0.7)),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetricCard(context, 'RECOVERY SCORE', 'A- Excellent', Icons.insights, 0.9),
            ],
          );
        }

        return Column(
          children: [
            _buildMetricCard(context, 'DAILY STEPS', '2,481 / 5,000', Icons.directions_walk, 0.5),
            const SizedBox(height: 12),
            _buildMetricCard(context, 'ACTIVE MINUTES', '42 min', Icons.show_chart, 0.7),
            const SizedBox(height: 12),
            _buildMetricCard(context, 'RECOVERY SCORE', 'A- Excellent', Icons.insights, 0.9),
          ],
        );
      },
    );
  }

  Widget _buildMobilityGoalCard(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E6EB),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: isMobile ? 16 : 32,
        runSpacing: 20,
        children: [
          SizedBox(
            width: isMobile ? 118 : 140,
            height: isMobile ? 118 : 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CircularProgressIndicator(
                  value: 112 / 120,
                  strokeWidth: 12,
                  backgroundColor: Color(0xFFDCDAF0),
                  color: Color(0xFF5A4D9A),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '112\u00B0',
                        style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        'MAX FLEXION',
                        style: TextStyle(fontSize: isMobile ? 9 : 10, color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6CFF0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: Color(0xFF5A4D9A)),
                      SizedBox(width: 6),
                      Text('Optimal Range Detected', style: TextStyle(fontSize: 12, color: Color(0xFF5A4D9A), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Today\'s mobility goal is 120\u00B0',
                  style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your recovery curve is trending upwards. Keep the pace consistent during your extension reps today.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A4D9A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Start Active Monitoring', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainManagementCard(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E0CB),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Color(0xFF819230)),
              ),
              const Text(
                'PAIN MANAGEMENT',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF819230), letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Pain Index',
            style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log your current discomfort level on a scale of 1-5.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          SizedBox(height: isMobile ? 20 : 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _painButton(context, '1', false),
              _painButton(context, '2', false),
              _painButton(context, '3', true),
              _painButton(context, '4', false),
              _painButton(context, '5', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _painButton(BuildContext context, String label, bool isSelected) {
    final size = ResponsiveLayout.isMobile(context) ? 36.0 : 40.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF5A4D9A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, double progress) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1E8),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: isMobile ? 18 : 20, color: const Color(0xFF5A4D9A)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                    Text(value, style: TextStyle(fontSize: isMobile ? 17 : 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFDCDAF0),
              color: const Color(0xFF5A4D9A),
            ),
          ),
        ],
      ),
    );
  }
}
