import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ble_providers.dart';
import '../services/preferences_service.dart';
import '../services/simulation_analytics_providers.dart';
import 'responsive/responsive_layout.dart';

class AppTopNav extends ConsumerWidget {
  const AppTopNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final isSimulationMode = ref.watch(simulationModeProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E2E6))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: isMobile ? 10 : 16),
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu,
                      color: const Color(0xFF4C3E8A), size: isMobile ? 20 : 24),
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
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final nextValue = !isSimulationMode;
                  await PreferencesService.setSimulationMode(nextValue);
                  await ref
                      .read(bleControllerProvider.notifier)
                      .setSimulationMode(nextValue);
                },
                icon: Icon(
                  isSimulationMode
                      ? Icons.toggle_on
                      : Icons.toggle_off_outlined,
                  size: isMobile ? 18 : 20,
                ),
                label: Text(isSimulationMode ? 'Simulation' : 'Live'),
                style: FilledButton.styleFrom(
                  backgroundColor: isSimulationMode
                      ? const Color(0xFFEDE9F5)
                      : const Color(0xFFE8F1F3),
                  foregroundColor: const Color(0xFF4C3E8A),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 14,
                    vertical: isMobile ? 8 : 10,
                  ),
                  textStyle: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
