import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../services/profile_service.dart';
import '../screens/live_angle_screen.dart';
import '../screens/step_counter_screen.dart';
import '../screens/alert_system_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/history_screen.dart';
import '../screens/login_screen.dart';
import '../theme/app_theme.dart';
import 'responsive/responsive_layout.dart';

class AppDrawer extends StatefulWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    await ProfileService.ensureCurrentUserProfile();
    return ProfileService.fetchCurrentUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = ResponsiveLayout.isMobile(context) ? 16.0 : 24.0;

    return Drawer(
      width: math.min(320, screenWidth * 0.82),
      backgroundColor: AppTheme.surface1,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 32.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.accessibility_new_outlined,
                        color: AppTheme.primary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The Kinetic\nSanctuary',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Clinical Precision',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Dashboard is now in bottom nav
                    _buildDrawerItem(
                      context,
                      icon: Icons.accessibility_new,
                      title: 'Live Knee Angle',
                      isSelected: widget.currentRoute == 'Live Knee Angle',
                      targetScreen: const LiveAngleScreen(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.directions_walk,
                      title: 'Step Counter',
                      isSelected: widget.currentRoute == 'Step Counter',
                      targetScreen: const StepCounterScreen(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.notifications_none,
                      title: 'Alert System',
                      isSelected: widget.currentRoute == 'Alert System',
                      targetScreen: const AlertSystemScreen(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.bar_chart,
                      title: 'Analysis',
                      isSelected: widget.currentRoute == 'Analysis',
                      targetScreen: const AnalysisScreen(),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.history,
                      title: 'History',
                      isSelected: widget.currentRoute == 'History',
                      targetScreen: const HistoryScreen(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFE2E2E6),
                          child: Icon(Icons.person,
                              color: Color(0xFF332A7C), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FutureBuilder<Map<String, dynamic>?>(
                            future: _profileFuture,
                            builder: (context, snapshot) {
                              final name = snapshot.data?['name'] as String? ??
                                  'Loading...';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text(
                                    'Attending Specialist',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Sign out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isSelected = false,
    Widget? targetScreen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            size: 24,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () {
            if (!isSelected && targetScreen != null) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      targetScreen,
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            } else if (isSelected) {
              Scaffold.of(context).closeDrawer();
            }
          },
        ),
      ),
    );
  }
}
