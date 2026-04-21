import 'package:flutter/material.dart';
import 'responsive/responsive_layout.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      color: const Color(0xFFEEEEF0),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.horizontalPadding(context),
        vertical: isMobile ? 20 : 32,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: isMobile ? 12 : 24,
        runSpacing: 12,
        children: [
          Text(
            'The Kinetic Sanctuary',
            style: TextStyle(
              color: const Color(0xFF4C3E8A),
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          Text(
            '\u00A9 2024 The Kinetic Sanctuary. Clinical precision meets human-centric care.',
            style: TextStyle(color: Colors.black54, fontSize: isMobile ? 12 : 13),
            textAlign: TextAlign.center,
          ),
          Wrap(
            spacing: isMobile ? 10 : 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Text('Help Center', style: TextStyle(color: Colors.black54, fontSize: isMobile ? 12 : 13)),
              Text('Privacy Policy', style: TextStyle(color: Colors.black54, fontSize: isMobile ? 12 : 13)),
              Text('Settings', style: TextStyle(color: Colors.black54, fontSize: isMobile ? 12 : 13)),
              Text('Terms of Service', style: TextStyle(color: Colors.black54, fontSize: isMobile ? 12 : 13)),
            ],
          ),
        ],
      ),
    );
  }
}
