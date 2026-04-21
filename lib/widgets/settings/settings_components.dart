import 'package:flutter/material.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF4C3E8A)),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C3E8A),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F5FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF4C3E8A)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null)
                const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsStatChip extends StatelessWidget {
  const SettingsStatChip({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
