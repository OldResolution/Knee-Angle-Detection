import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEEEF0),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'The Kinetic Sanctuary',
            style: TextStyle(
              color: Color(0xFF4C3E8A),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Text(
            '© 2024 The Kinetic Sanctuary. Clinical precision meets human-centric care.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          LayoutBuilder(builder: (context, constraints) {
            return Row(
              children: const [
                Text('Help Center', style: TextStyle(color: Colors.black54, fontSize: 13)),
                SizedBox(width: 16),
                Text('Privacy Policy', style: TextStyle(color: Colors.black54, fontSize: 13)),
                SizedBox(width: 16),
                Text('Settings', style: TextStyle(color: Colors.black54, fontSize: 13)),
                SizedBox(width: 16),
                Text('Terms of Service', style: TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            );
          }),
        ],
      ),
    );
  }
}
