import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class AlertSystemScreen extends StatelessWidget {
  const AlertSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      drawer: const AppDrawer(currentRoute: 'Alert System'),
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
                    'Alert System (Inbox)',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.headlineSize(context),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4C3E8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stay updated on your clinical goals and physical milestones.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  _buildAlertTile(
                    title: 'Form Correction Reminded',
                    message: 'Your kinetic cap detected improper knee flexion during your last session. Please review video guidance for correct form.',
                    icon: Icons.monitor_heart,
                    iconColor: Colors.white,
                    bgColor: const Color(0xFFE5E0CB),
                    badgeBgColor: const Color(0xFF6F701B),
                    timeAgo: '10 mins ago',
                  ),
                  const SizedBox(height: 16),
                  _buildAlertTile(
                    title: 'Hydration & Rest Pattern',
                    message: 'You have been active for an extended period. The AI suggests a brief 5-minute break with proper hydration for optimal joint recovery.',
                    icon: Icons.water_drop,
                    iconColor: const Color(0xFF4C3E8A),
                    bgColor: Colors.white,
                    badgeBgColor: const Color(0xFFE2E2E6),
                    timeAgo: '1 hour ago',
                  ),
                  const SizedBox(height: 16),
                  _buildAlertTile(
                    title: 'Mobility Goal Hit!',
                    message: 'Congratulations! You reached your 120\u00B0 mobility goal. Your active monitoring data demonstrates improved asymmetry vs last week.',
                    icon: Icons.auto_awesome,
                    iconColor: Colors.white,
                    bgColor: const Color(0xFFE2E0EE),
                    badgeBgColor: const Color(0xFF5A4D9A),
                    timeAgo: '3 hours ago',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color badgeBgColor,
    required String timeAgo,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))),
                    const SizedBox(width: 8),
                    Text(timeAgo, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(message, style: const TextStyle(height: 1.5, color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C3E8A), fontSize: 13)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF4C3E8A)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
