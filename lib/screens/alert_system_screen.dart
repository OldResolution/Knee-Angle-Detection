import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/knee_alert.dart';
import '../services/ble_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class AlertSystemScreen extends ConsumerWidget {
  const AlertSystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertHistoryProvider);
    final activeCount = ref.watch(activeAlertCountProvider);

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
                  // ── Header Row ─────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alert System',
                              style: TextStyle(
                                fontSize: ResponsiveLayout.headlineSize(context),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4C3E8A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activeCount > 0
                                  ? '$activeCount active alert${activeCount == 1 ? '' : 's'} — stay on top of your recovery.'
                                  : 'All clear — no active alerts right now.',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      if (alerts.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionChip(
                              icon: Icons.done_all,
                              label: 'Dismiss All',
                              onTap: () => ref
                                  .read(alertHistoryProvider.notifier)
                                  .dismissAll(),
                            ),
                            const SizedBox(width: 8),
                            _ActionChip(
                              icon: Icons.delete_sweep,
                              label: 'Clear',
                              onTap: () => ref
                                  .read(alertHistoryProvider.notifier)
                                  .clear(),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Alert List / Empty State ───────────────────
                  if (alerts.isEmpty) _buildEmptyState(context),

                  if (alerts.isNotEmpty)
                    ...List.generate(alerts.length, (index) {
                      final alert = alerts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _AlertTile(
                          alert: alert,
                          onDismiss: () => ref
                              .read(alertHistoryProvider.notifier)
                              .dismiss(index),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE2E0EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 48, color: Color(0xFF5A4D9A)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Alerts Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4C3E8A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Alerts will appear here when your knee angle\nexceeds thresholds or sudden movements are detected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black54, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Chip ───────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E2E6)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF5A4D9A)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A4D9A))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert Tile ────────────────────────────────────────────────────────────

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.onDismiss});

  final KneeAlert alert;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final config = _severityConfig(alert.severity);
    final timeSince = _timeAgo(alert.timestamp);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: alert.dismissed ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: config.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert.dismissed
                ? Colors.transparent
                : config.accentColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Severity Badge ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: config.badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon,
                  color: config.iconColor, size: 20),
            ),
            const SizedBox(width: 20),
            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Severity label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: config.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          config.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: config.accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(timeSince,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(alert.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text(alert.message,
                      style: const TextStyle(
                          height: 1.5,
                          color: Colors.black54,
                          fontSize: 14)),
                  const SizedBox(height: 12),
                  if (!alert.dismissed)
                    GestureDetector(
                      onTap: onDismiss,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 16, color: Color(0xFF4C3E8A)),
                          SizedBox(width: 6),
                          Text('Dismiss',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4C3E8A),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SeverityConfig _severityConfig(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const _SeverityConfig(
          label: 'Critical',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.white,
          bgColor: Color(0xFFFFF0F0),
          badgeColor: Color(0xFFD32F2F),
          accentColor: Color(0xFFD32F2F),
        );
      case AlertSeverity.warning:
        return const _SeverityConfig(
          label: 'Warning',
          icon: Icons.error_outline,
          iconColor: Colors.white,
          bgColor: Color(0xFFFFF8E1),
          badgeColor: Color(0xFFF9A825),
          accentColor: Color(0xFFF9A825),
        );
      case AlertSeverity.info:
        return const _SeverityConfig(
          label: 'Info',
          icon: Icons.info_outline,
          iconColor: Colors.white,
          bgColor: Color(0xFFE8EAF6),
          badgeColor: Color(0xFF5C6BC0),
          accentColor: Color(0xFF5C6BC0),
        );
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _SeverityConfig {
  const _SeverityConfig({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.badgeColor,
    required this.accentColor,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color badgeColor;
  final Color accentColor;
}
