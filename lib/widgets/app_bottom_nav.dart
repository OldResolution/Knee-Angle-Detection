import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget target;
    switch (index) {
      case 0:
        target = const HomeScreen();
        break;
      case 1:
        target = const SettingsScreen();
        break;
      case 2:
        target = const ProfileScreen();
        break;
      default:
        target = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (idx) => _onTap(context, idx),
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.primary,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined, color: currentIndex == 0 ? Colors.white : AppTheme.textSecondary),
          selectedIcon: const Icon(Icons.dashboard, color: Colors.white),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined, color: currentIndex == 1 ? Colors.white : AppTheme.textSecondary),
          selectedIcon: const Icon(Icons.settings, color: Colors.white),
          label: 'Settings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: currentIndex == 2 ? Colors.white : AppTheme.textSecondary),
          selectedIcon: const Icon(Icons.person, color: Colors.white),
          label: 'Profile',
        ),
      ],
    );
  }
}
