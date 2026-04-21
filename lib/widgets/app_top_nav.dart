import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import 'responsive/responsive_layout.dart';

class AppTopNav extends StatelessWidget {
  const AppTopNav({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 10 : 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu, color: const Color(0xFF4C3E8A), size: isMobile ? 20 : 24),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The Kinetic Sanctuary',
                    style: TextStyle(
                      color: const Color(0xFF4C3E8A),
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 15 : 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (!isMobile) ...[
                const Icon(Icons.help_sharp, color: Color(0xFF4C3E8A), size: 20),
                const SizedBox(width: 12),
              ],
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.settings, color: const Color(0xFF4C3E8A), size: isMobile ? 18 : 20),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
              SizedBox(width: isMobile ? 10 : 16),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: isMobile ? 14 : 16,
                  backgroundColor: const Color(0xFF1B3B4A),
                  child: Icon(Icons.person, color: Colors.white, size: isMobile ? 18 : 20),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20, color: Colors.grey),
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              ],
            ],
          )
        ],
      ),
    );
  }
}
