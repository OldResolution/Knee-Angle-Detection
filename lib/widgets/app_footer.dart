import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEEEF0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: const Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 16,
        children: [
          Text(
            'The Kinetic Sanctuary',
            style: TextStyle(
              color: Color(0xFF4C3E8A),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            '\u00A9 2024 The Kinetic Sanctuary. Clinical precision meets human-centric care.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Text('Help Center', style: TextStyle(color: Colors.black54, fontSize: 13)),
              Text('Privacy Policy', style: TextStyle(color: Colors.black54, fontSize: 13)),
              Text('Settings', style: TextStyle(color: Colors.black54, fontSize: 13)),
              Text('Terms of Service', style: TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
