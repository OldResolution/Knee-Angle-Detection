import 'package:flutter/material.dart';
import 'responsive/responsive_layout.dart';

class AppTopNav extends StatelessWidget {
  const AppTopNav({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E2E6))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 10 : 16),
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
      ),
    );
  }
}
