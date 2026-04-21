import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_nav.dart';
import '../services/preferences_service.dart';
import '../services/ble_providers.dart';
import '../services/ble_data_service.dart';
import '../services/goals_providers.dart';
import '../services/knee_analysis_service.dart';
import '../services/storage_service.dart';
import 'device_connectivity_screen.dart';
import '../widgets/responsive/responsive_layout.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedTab = 'Account Preferences';
  bool _simMode = true;
  SimulationPattern _simulationPattern = SimulationPattern.random;
  double _simulationSpeed = 1.0;

  // AI & Alerts local state (synced from prefs on init)
  double _maxAngle = 140.0;
  double _minAngle = 5.0;
  double _suddenMovement = 200.0;
  bool _alertsEnabled = true;
  int _dailyStepGoal = 8000;
  int _exerciseMinutesGoal = 30;
  double _activeHoursGoal = 6.0;

  @override
  void initState() {
    super.initState();
    _simMode = PreferencesService.isSimulationMode;
    _maxAngle = PreferencesService.maxAngleThreshold;
    _minAngle = PreferencesService.minAngleThreshold;
    _suddenMovement = PreferencesService.suddenMovementThreshold;
    _alertsEnabled = PreferencesService.alertsEnabled;
    _dailyStepGoal = PreferencesService.dailyStepGoal;
    _exerciseMinutesGoal = PreferencesService.exerciseMinutesGoal;
    _activeHoursGoal = PreferencesService.activeHoursGoal;
    _simulationPattern = parseSimulationPattern(PreferencesService.simulationPattern);
    _simulationSpeed = ref.read(bleControllerProvider.notifier).simulationSpeedMultiplier;
  }

  void _onTabSelected(String tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FB),
      drawer: const AppDrawer(currentRoute: 'Settings'),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: Column(
        children: [
          const AppTopNav(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > ResponsiveLayout.tabletMaxWidth) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDesktopSidebar(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(ResponsiveLayout.isDesktop(context) ? 40 : 32),
                          child: _buildActiveContent(),
                        ),
                      ),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMobileNav(),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveLayout.horizontalPadding(context),
                            vertical: ResponsiveLayout.verticalPadding(context),
                          ),
                          child: _buildActiveContent(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: ResponsiveLayout.isDesktop(context) ? 280 : 220,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(2, 0),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveLayout.isDesktop(context) ? 24 : 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: ResponsiveLayout.isDesktop(context) ? 20 : 18,
                  backgroundColor: const Color(0xFF1B3B4A),
                  child: Icon(Icons.person, color: Colors.white, size: ResponsiveLayout.isDesktop(context) ? 24 : 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveLayout.isDesktop(context) ? 16 : 14)),
                      const Text('Manage your recovery atelier', style: TextStyle(fontSize: 10, color: Colors.black54), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSidebarItem('Account Preferences', Icons.person),
          _buildSidebarItem('Data Sync', Icons.sync),
          _buildSidebarItem('Notifications', Icons.notifications),
          _buildSidebarItem('Goals & Targets', Icons.flag),
          _buildSidebarItem('System Calibration', Icons.monitor_weight_outlined),
          _buildSidebarItem('AI & Alerts', Icons.psychology),
          const Spacer(),
          const Divider(),
          _buildSidebarItem('Support', Icons.help, isAction: true),
          _buildSidebarItem('Sign Out', Icons.logout, isAction: true),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String title, IconData icon, {bool isAction = false}) {
    final isSelected = _selectedTab == title && !isAction;
    return InkWell(
      onTap: isAction ? () {} : () => _onTabSelected(title),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A4D9A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : (isAction ? Colors.black87 : const Color(0xFF4C3E8A))),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _buildMobileChip('Account Preferences'),
            const SizedBox(width: 8),
            _buildMobileChip('Data Sync'),
            const SizedBox(width: 8),
            _buildMobileChip('Notifications'),
            const SizedBox(width: 8),
            _buildMobileChip('Goals & Targets'),
            const SizedBox(width: 8),
            _buildMobileChip('System Calibration'),
            const SizedBox(width: 8),
            _buildMobileChip('AI & Alerts'),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileChip(String title) {
    final isSelected = _selectedTab == title;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (_) => _onTabSelected(title),
      selectedColor: const Color(0xFF5A4D9A),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }

  Widget _buildActiveContent() {
    switch (_selectedTab) {
      case 'Data Sync':
        return _buildDataSyncOnlyContent();
      case 'Notifications':
        return _buildNotificationsOnlyContent();
      case 'Goals & Targets':
        return _buildGoalsTargetsContent();
      case 'System Calibration':
        return _buildLegacySettings();
      case 'AI & Alerts':
        return _buildAiAlertsContent();
      case 'Account Preferences':
      default:
        return _buildAccountPreferences();
    }
  }

  Widget _buildAccountPreferences() {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Preferences',
          style: TextStyle(fontSize: ResponsiveLayout.headlineSize(context), fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage your personal details and system credentials.',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        SizedBox(height: isMobile ? 24 : 40),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= ResponsiveLayout.mobileMaxWidth) {
              return Column(
                children: [
                  _buildProfileDetailsCard(),
                  const SizedBox(height: 20),
                  _buildSecurityCard(),
                  const SizedBox(height: 20),
                  _buildDataSyncCard(),
                  const SizedBox(height: 20),
                  _buildAlertPreferencesCard(),
                ],
              );
            }

            return Wrap(
              spacing: 24,
              runSpacing: 24,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      _buildProfileDetailsCard(),
                      const SizedBox(height: 24),
                      _buildSecurityCard(),
                    ],
                  ),
                ),
                SizedBox(
                  width: 350,
                  child: Column(
                    children: [
                      _buildDataSyncCard(),
                      const SizedBox(height: 24),
                      _buildAlertPreferencesCard(),
                    ],
                  ),
                ),
              ],
            );
          },
        )
      ],
    );
  }

  Widget _buildProfileDetailsCard() {
    return _buildMockupCard(
      title: 'Profile Details',
      icon: Icons.badge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Full Name'),
          const SizedBox(height: 8),
          _buildTextField('Elena Rostova', Icons.person),
          const SizedBox(height: 24),
          _buildInputLabel('Email Address'),
          const SizedBox(height: 8),
          _buildTextField('elena.r@kineticsanctuary.com', Icons.email),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return _buildMockupCard(
      title: 'Security',
      icon: Icons.lock,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Current Password'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.vpn_key, color: Color(0xFF5A4D9A), size: 18),
                SizedBox(width: 16),
                Expanded(
                  child: Text('â€¢ â€¢ â€¢ â€¢ â€¢ â€¢ â€¢ â€¢', style: TextStyle(color: Colors.black87, fontSize: 16, letterSpacing: 4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A4D9A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E2E6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDataSyncCard() {
    return _buildMockupCard(
      title: 'Data Synchronization',
      icon: null,
      topRightWidget: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keep your recovery metrics perfectly aligned across the sanctuary network.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_upload, color: Color(0xFF5A4D9A)),
                    SizedBox(width: 16),
                    Text('Auto-Sync to\nCloud', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                Switch(
                  value: true,
                  onChanged: (val) {},
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF5A4D9A),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(storageServiceProvider).clearAllData();
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Local session and daily log cache cleared.'),
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Clear Local Cache'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Color(0xFFE2E2E6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertPreferencesCard() {
    return _buildMockupCard(
      title: 'Alert Preferences',
      icon: null,
      child: Column(
        children: [
          _buildCheckRow('Milestone Achieved', true),
          const SizedBox(height: 16),
          _buildCheckRow('Calibration Needed', true),
          const SizedBox(height: 16),
          _buildCheckRow('Weekly Summary', false),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String label, bool isChecked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Icon(
            isChecked ? Icons.check_box : Icons.check_box_outline_blank,
            color: isChecked ? const Color(0xFF5A4D9A) : Colors.black26,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSyncOnlyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Synchronization',
          style: TextStyle(fontSize: ResponsiveLayout.headlineSize(context), fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'Control data sync behavior and local storage maintenance.',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        const SizedBox(height: 28),
        _buildDataSyncCard(),
      ],
    );
  }

  Widget _buildNotificationsOnlyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: TextStyle(fontSize: ResponsiveLayout.headlineSize(context), fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose which in-app updates and milestones are surfaced.',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        const SizedBox(height: 28),
        _buildAlertPreferencesCard(),
      ],
    );
  }

  Widget _buildGoalsTargetsContent() {
    final goalsNotifier = ref.read(userGoalsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goals & Targets',
          style: TextStyle(fontSize: ResponsiveLayout.headlineSize(context), fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'Define personalized daily goals for steps, exercise, and active wear time.',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        const SizedBox(height: 28),
        _buildMockupCard(
          title: 'Daily Step Goal',
          icon: Icons.directions_walk,
          child: _buildGoalStepper(
            value: _dailyStepGoal,
            unitLabel: 'steps',
            step: 500,
            min: 1000,
            max: 20000,
            onChanged: (next) {
              setState(() => _dailyStepGoal = next);
              unawaited(goalsNotifier.setDailyStepGoal(next));
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildMockupCard(
          title: 'Exercise Minutes Goal',
          icon: Icons.fitness_center,
          child: _buildGoalStepper(
            value: _exerciseMinutesGoal,
            unitLabel: 'minutes',
            step: 5,
            min: 5,
            max: 120,
            onChanged: (next) {
              setState(() => _exerciseMinutesGoal = next);
              unawaited(goalsNotifier.setExerciseMinutesGoal(next));
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildMockupCard(
          title: 'Active Hours Goal',
          icon: Icons.schedule,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _activeHoursGoal,
                      min: 1,
                      max: 12,
                      divisions: 22,
                      activeColor: const Color(0xFF5A4D9A),
                      label: '${_activeHoursGoal.toStringAsFixed(1)} h',
                      onChanged: (val) {
                        setState(() => _activeHoursGoal = val);
                        unawaited(goalsNotifier.setActiveHoursGoal(val));
                      },
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '${_activeHoursGoal.toStringAsFixed(1)} h',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStepper({
    required int value,
    required String unitLabel,
    required int step,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final canDecrement = value > min;
    final canIncrement = value < max;

    return Row(
      children: [
        IconButton(
          onPressed: canDecrement ? () => onChanged((value - step).clamp(min, max)) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$value $unitLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          onPressed: canIncrement ? () => onChanged((value + step).clamp(min, max)) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _buildLegacySettings() {
    final connectionState = ref.watch(bleConnectionStateProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Calibration',
          style: TextStyle(fontSize: ResponsiveLayout.headlineSize(context), fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage underlying hardware sensors and connectivity layers.',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        SizedBox(height: isMobile ? 24 : 40),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.bluetooth, color: Color(0xFF4C3E8A)),
                title: const Text('Device Connectivity'),
                subtitle: Text(connectionState.summary),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DeviceConnectivityScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.hub, color: Color(0xFF4C3E8A)),
                title: const Text('Simulation Mode'),
                subtitle: const Text('Use dummy/random data vs real BLE'),
                value: _simMode,
                activeThumbColor: const Color(0xFF5A4D9A),
                onChanged: (val) {
                  setState(() => _simMode = val);
                  PreferencesService.setSimulationMode(val);
                  unawaited(ref.read(bleControllerProvider.notifier).setSimulationMode(val));
                },
              ),
              if (_simMode) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: _buildSimulationControlPanel(),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF4C3E8A)),
                title: const Text('Calibration Check'),
                subtitle: const Text('Reset device baseline values'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFF4C3E8A)),
                title: const Text('About Firmware'),
                subtitle: const Text('Kinetic Cap Series V 1.0.0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationControlPanel() {
    final controller = ref.read(bleControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Simulation Pattern',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<SimulationPattern>(
          initialValue: _simulationPattern,
          items: SimulationPattern.values
              .map(
                (pattern) => DropdownMenuItem<SimulationPattern>(
                  value: pattern,
                  child: Text(pattern.displayName),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _simulationPattern = value);
            unawaited(controller.setSimulationPattern(value));
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Speed Multiplier',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${_simulationSpeed.toStringAsFixed(1)}x',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: _simulationSpeed,
          min: 0.5,
          max: 3.0,
          divisions: 25,
          activeColor: const Color(0xFF5A4D9A),
          label: '${_simulationSpeed.toStringAsFixed(1)}x',
          onChanged: (value) {
            setState(() => _simulationSpeed = value);
            unawaited(controller.setSimulationSpeedMultiplier(value));
          },
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Status: ${_simulationPattern.displayName} | ${controller.simulationDataRateHz.toStringAsFixed(1)} Hz',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4C3E8A)),
          ),
        ),
      ],
    );
  }

  // ── AI & Alerts Tab ──────────────────────────────────────────────────

  void _syncConfigToProvider() {
    ref.read(analysisConfigProvider.notifier).state = AnalysisConfig(
      maxAngleThreshold: _maxAngle,
      minAngleThreshold: _minAngle,
      suddenMovementThreshold: _suddenMovement,
      alertsEnabled: _alertsEnabled,
    );
  }

  Widget _buildAiAlertsContent() {
    final isMobile = ResponsiveLayout.isMobile(context);
    final alertCount = ref.watch(activeAlertCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI & Alerts',
          style: TextStyle(
            fontSize: ResponsiveLayout.headlineSize(context),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure real-time monitoring thresholds and alert behaviour. '
          '${alertCount > 0 ? '$alertCount active alert${alertCount == 1 ? '' : 's'}.' : 'No active alerts.'}',
          style: const TextStyle(color: Colors.black54, fontSize: 16),
        ),
        SizedBox(height: isMobile ? 24 : 40),

        // ── Master Toggle ──
        _buildMockupCard(
          title: 'Alert System',
          icon: Icons.notifications_active,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Alerts',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Receive notifications when thresholds are breached'),
                value: _alertsEnabled,
                activeThumbColor: const Color(0xFF5A4D9A),
                onChanged: (val) {
                  setState(() => _alertsEnabled = val);
                  PreferencesService.setAlertsEnabled(val);
                  _syncConfigToProvider();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Angle Thresholds ──
        _buildMockupCard(
          title: 'Angle Thresholds',
          icon: Icons.straighten,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Maximum Angle (°)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _maxAngle,
                      min: 90,
                      max: 180,
                      divisions: 18,
                      activeColor: const Color(0xFF5A4D9A),
                      label: '${_maxAngle.round()}°',
                      onChanged: (val) {
                        setState(() => _maxAngle = val);
                        PreferencesService.setMaxAngleThreshold(val);
                        _syncConfigToProvider();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text('${_maxAngle.round()}°',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Minimum Angle (°)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _minAngle,
                      min: 0,
                      max: 30,
                      divisions: 30,
                      activeColor: const Color(0xFF5A4D9A),
                      label: '${_minAngle.round()}°',
                      onChanged: (val) {
                        setState(() => _minAngle = val);
                        PreferencesService.setMinAngleThreshold(val);
                        _syncConfigToProvider();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text('${_minAngle.round()}°',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Sudden Movement ──
        _buildMockupCard(
          title: 'Sudden Movement Detection',
          icon: Icons.flash_on,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Velocity Spike Threshold (°/s)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _suddenMovement,
                      min: 50,
                      max: 500,
                      divisions: 45,
                      activeColor: const Color(0xFFD32F2F),
                      label: '${_suddenMovement.round()}°/s',
                      onChanged: (val) {
                        setState(() => _suddenMovement = val);
                        PreferencesService.setSuddenMovementThreshold(val);
                        _syncConfigToProvider();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text('${_suddenMovement.round()}°/s',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Color(0xFFD32F2F)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A critical alert fires when angular velocity exceeds this limit, indicating a potentially dangerous jerky movement.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB71C1C),
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Phase 2 Placeholder ──
        _buildMockupCard(
          title: 'ML Activity Detection',
          icon: Icons.model_training,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.science,
                        size: 16, color: Color(0xFF5C6BC0)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TensorFlow Lite model integration coming in Phase 2. '
                        'This will provide AI-powered activity classification.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF303F9F),
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMockupCard({required String title, required Widget child, IconData? icon, Widget? topRightWidget}) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FB), // Matching light grey mockup BG
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFF5A4D9A), size: 20),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(fontSize: isMobile ? 16 : 18, color: const Color(0xFF5A4D9A), fontWeight: FontWeight.bold),
              ),
              if (topRightWidget != null) const Spacer(),
              if (topRightWidget != null) topRightWidget,
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, color: Colors.black54),
    );
  }

  Widget _buildTextField(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5A4D9A), size: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
