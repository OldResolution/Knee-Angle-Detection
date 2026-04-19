import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';

class AppTopNav extends StatelessWidget {
  const AppTopNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF4C3E8A)),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'The Kinetic Sanctuary',
                style: TextStyle(
                  color: Color(0xFF4C3E8A),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.help_sharp, color: Color(0xFF4C3E8A), size: 20),
              const SizedBox(width: 16),
              const Icon(Icons.settings, color: Color(0xFF4C3E8A), size: 20),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1B3B4A),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
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
          )
        ],
      ),
    );
  }
}
