import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_goals.dart';
import '../services/ble_data_service.dart';
import '../services/ble_providers.dart';
import '../services/ble_service.dart';
import '../services/goals_providers.dart';
import '../services/knee_analysis_service.dart';
import '../services/preferences_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/settings/settings_components.dart';
import 'alert_system_screen.dart';
import 'device_connectivity_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

enum SettingsTab {
  account('Account', Icons.person_outline),
  goals('Goals', Icons.flag_outlined),
  connectivity('Connectivity', Icons.bluetooth_searching),
  alerts('Alerts', Icons.notifications_active_outlined),
  data('Data', Icons.storage_outlined);

  const SettingsTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SettingsTab _selectedTab = SettingsTab.account;
  late Future<Map<String, dynamic>?> _profileFuture;

  bool _simMode = true;
  SimulationPattern _simulationPattern = SimulationPattern.random;
  double _simulationSpeed = 1.0;
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
    _simulationPattern =
        parseSimulationPattern(PreferencesService.simulationPattern);
    _simulationSpeed =
        ref.read(bleControllerProvider.notifier).simulationSpeedMultiplier;
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    await ProfileService.ensureCurrentUserProfile();
    return ProfileService.fetchCurrentUserProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<void> _sendPasswordReset() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      _showSnack('No account email available for password reset.');
      return;
    }

    await Supabase.instance.client.auth.resetPasswordForEmail(email);
    _showSnack('Password reset link sent to $email.');
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _clearLocalCache() async {
    await ref.read(storageServiceProvider).clearAllData();
    _showSnack('Local session and daily log cache cleared.');
  }

  Future<void> _resetGoals() async {
    final notifier = ref.read(userGoalsProvider.notifier);
    await notifier.setDailyStepGoal(UserGoals.defaults.dailyStepGoal);
    await notifier
        .setExerciseMinutesGoal(UserGoals.defaults.exerciseMinutesGoal);
    await notifier.setActiveHoursGoal(UserGoals.defaults.activeHoursGoal);
    if (!mounted) {
      return;
    }
    setState(() {
      _dailyStepGoal = UserGoals.defaults.dailyStepGoal;
      _exerciseMinutesGoal = UserGoals.defaults.exerciseMinutesGoal;
      _activeHoursGoal = UserGoals.defaults.activeHoursGoal;
    });
    _showSnack('Goals reset to defaults.');
  }

  Future<void> _setSimulationMode(bool enabled) async {
    setState(() => _simMode = enabled);
    await PreferencesService.setSimulationMode(enabled);
    await ref.read(bleControllerProvider.notifier).setSimulationMode(enabled);
  }

  void _syncAnalysisConfig() {
    ref.read(analysisConfigProvider.notifier).state = AnalysisConfig(
      maxAngleThreshold: _maxAngle,
      minAngleThreshold: _minAngle,
      suddenMovementThreshold: _suddenMovement,
      alertsEnabled: _alertsEnabled,
    );
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsNotifier = ref.read(userGoalsProvider.notifier);
    final scanState = ref.watch(bleScanStateProvider);
    final connectionState = ref.watch(bleConnectionStateProvider);
    final goals = ref.watch(userGoalsProvider);
    final activeAlerts = ref.watch(activeAlertCountProvider);

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
                final content = _buildActiveTabContent(
                  context,
                  goals: goals,
                  goalsNotifier: goalsNotifier,
                  scanState: scanState,
                  connectionState: connectionState,
                  activeAlerts: activeAlerts,
                );

                if (constraints.maxWidth > ResponsiveLayout.tabletMaxWidth) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDesktopSidebar(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: ResponsiveLayout.constrainedPage(
                            context,
                            content,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMobileTabBar(),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveLayout.horizontalPadding(context),
                          vertical: ResponsiveLayout.verticalPadding(context),
                        ),
                        child: content,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Control profile, goals, connectivity, alerts, and local data.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (final tab in SettingsTab.values) _buildSidebarItem(tab),
          const Spacer(),
          FilledButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(SettingsTab tab) {
    final selected = _selectedTab == tab;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFF5A4D9A) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedTab = tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  color: selected ? Colors.white : const Color(0xFF4C3E8A),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (final tab in SettingsTab.values) ...[
              ChoiceChip(
                label: Text(tab.label),
                selected: _selectedTab == tab,
                onSelected: (_) => setState(() => _selectedTab = tab),
                selectedColor: const Color(0xFF5A4D9A),
                labelStyle: TextStyle(
                  color: _selectedTab == tab ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context, {
    required UserGoals goals,
    required UserGoalsNotifier goalsNotifier,
    required BleScanState scanState,
    required BleConnectionStateData connectionState,
    required int activeAlerts,
  }) {
    switch (_selectedTab) {
      case SettingsTab.account:
        return _buildAccountTab();
      case SettingsTab.goals:
        return _buildGoalsTab(goals, goalsNotifier);
      case SettingsTab.connectivity:
        return _buildConnectivityTab(scanState, connectionState);
      case SettingsTab.alerts:
        return _buildAlertsTab(activeAlerts);
      case SettingsTab.data:
        return _buildDataTab();
    }
  }

  Widget _buildAccountTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(
          'Account Settings',
          'Keep profile data consistent and manage your sign-in credentials.',
        ),
        const SizedBox(height: 24),
        FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ?? const <String, dynamic>{};
            final name = data['name']?.toString() ?? 'User';
            final email = data['email']?.toString() ?? 'No email available';
            final mobile = data['mobile']?.toString() ?? 'Not provided';
            final age = data['age']?.toString() ?? 'Not provided';

            return SettingsSectionCard(
              title: 'Profile',
              subtitle:
                  'This summary is merged from Supabase auth metadata and the profiles table.',
              icon: Icons.badge_outlined,
              trailing: IconButton(
                tooltip: 'Refresh profile',
                onPressed: _refreshProfile,
                icon: const Icon(Icons.refresh),
              ),
              child: Column(
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SettingsStatChip(label: 'Name', value: name),
                      SettingsStatChip(label: 'Email', value: email),
                      SettingsStatChip(label: 'Mobile', value: mobile),
                      SettingsStatChip(label: 'Age', value: age),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final vertical = constraints.maxWidth < 520;
                      final openProfileButton = OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Open Profile'),
                      );
                      final resetPasswordButton = FilledButton.icon(
                        onPressed: _sendPasswordReset,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Reset Password'),
                      );

                      if (vertical) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            openProfileButton,
                            const SizedBox(height: 12),
                            resetPasswordButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: openProfileButton),
                          const SizedBox(width: 12),
                          Expanded(child: resetPasswordButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        SettingsSectionCard(
          title: 'Session',
          subtitle: 'Quick account actions that are guaranteed to work.',
          icon: Icons.manage_accounts_outlined,
          child: Column(
            children: [
              SettingsActionTile(
                title: 'Refresh merged profile data',
                subtitle: 'Re-read auth metadata and the profiles table.',
                icon: Icons.sync,
                onTap: _refreshProfile,
              ),
              const SizedBox(height: 12),
              SettingsActionTile(
                title: 'Sign out',
                subtitle: 'Return to the login screen.',
                icon: Icons.logout,
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsTab(UserGoals goals, UserGoalsNotifier goalsNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(
          'Goals & Targets',
          'Tune the daily goals that drive dashboard progress and history markers.',
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: 'Daily Goals',
          subtitle:
              'Changes here are saved locally and reflected across the app.',
          icon: Icons.flag_outlined,
          trailing: TextButton(
            onPressed: _resetGoals,
            child: const Text('Reset'),
          ),
          child: Column(
            children: [
              _buildGoalAdjuster(
                title: 'Daily Step Goal',
                valueLabel: '${goals.dailyStepGoal} steps',
                canDecrement: _dailyStepGoal > 1000,
                canIncrement: _dailyStepGoal < 20000,
                onDecrement: () {
                  final next = (_dailyStepGoal - 500).clamp(1000, 20000);
                  setState(() => _dailyStepGoal = next);
                  unawaited(goalsNotifier.setDailyStepGoal(next));
                },
                onIncrement: () {
                  final next = (_dailyStepGoal + 500).clamp(1000, 20000);
                  setState(() => _dailyStepGoal = next);
                  unawaited(goalsNotifier.setDailyStepGoal(next));
                },
              ),
              const SizedBox(height: 16),
              _buildGoalAdjuster(
                title: 'Exercise Minutes Goal',
                valueLabel: '${goals.exerciseMinutesGoal} min',
                canDecrement: _exerciseMinutesGoal > 5,
                canIncrement: _exerciseMinutesGoal < 120,
                onDecrement: () {
                  final next = (_exerciseMinutesGoal - 5).clamp(5, 120);
                  setState(() => _exerciseMinutesGoal = next);
                  unawaited(goalsNotifier.setExerciseMinutesGoal(next));
                },
                onIncrement: () {
                  final next = (_exerciseMinutesGoal + 5).clamp(5, 120);
                  setState(() => _exerciseMinutesGoal = next);
                  unawaited(goalsNotifier.setExerciseMinutesGoal(next));
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Hours Goal',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: goals.activeHoursGoal,
                            min: 1,
                            max: 12,
                            divisions: 22,
                            activeColor: const Color(0xFF5A4D9A),
                            label:
                                '${goals.activeHoursGoal.toStringAsFixed(1)} h',
                            onChanged: (value) {
                              setState(() => _activeHoursGoal = value);
                              unawaited(
                                  goalsNotifier.setActiveHoursGoal(value));
                            },
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            '${goals.activeHoursGoal.toStringAsFixed(1)} h',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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

  Widget _buildConnectivityTab(
    BleScanState scanState,
    BleConnectionStateData connectionState,
  ) {
    final controller = ref.read(bleControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(
          'Connectivity',
          'Control BLE scanning, connection status, and simulation behavior from one place.',
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: 'BLE Status',
          subtitle: scanState.summary,
          icon: Icons.bluetooth_searching,
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SettingsStatChip(
                    label: 'Adapter',
                    value: scanState.adapterState.name,
                  ),
                  SettingsStatChip(
                    label: 'Connection',
                    value: connectionState.phaseLabel,
                  ),
                  SettingsStatChip(
                    label: 'Target',
                    value: connectionState.deviceLabel,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  SettingsActionTile(
                    title: 'Open device connectivity page',
                    subtitle: 'View discovered devices and connect manually.',
                    icon: Icons.radar,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DeviceConnectivityScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SettingsActionTile(
                    title:
                        scanState.isScanning ? 'Stop scanning' : 'Start scan',
                    subtitle: scanState.isScanning
                        ? 'Stop the current BLE discovery session.'
                        : 'Start scanning immediately.',
                    icon: scanState.isScanning
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline,
                    onTap: scanState.isScanning
                        ? () => unawaited(controller.stopScan())
                        : () => unawaited(controller.startScan()),
                  ),
                  const SizedBox(height: 12),
                  if (scanState.isBluetoothOff && scanState.canRequestEnable)
                    SettingsActionTile(
                      title: 'Turn Bluetooth on',
                      subtitle: 'Ask Android to enable the Bluetooth adapter.',
                      icon: Icons.bluetooth_audio,
                      onTap: () =>
                          unawaited(controller.requestBluetoothEnable()),
                    )
                  else
                    SettingsActionTile(
                      title: 'Disconnect current device',
                      subtitle: 'Drop the active BLE link cleanly.',
                      icon: Icons.link_off,
                      onTap: connectionState.device == null
                          ? null
                          : () => unawaited(controller.disconnect()),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SettingsSectionCard(
          title: 'Simulation Mode',
          subtitle:
              'Use the same screens and analytics pipeline with generated telemetry instead of hardware.',
          icon: Icons.hub_outlined,
          trailing: Switch(
            value: _simMode,
            onChanged: (value) => unawaited(_setSimulationMode(value)),
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF5A4D9A),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulation Pattern',
                style: TextStyle(fontWeight: FontWeight.w700),
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
                onChanged: !_simMode
                    ? null
                    : (value) {
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
                      style: TextStyle(fontWeight: FontWeight.w700),
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
                onChanged: !_simMode
                    ? null
                    : (value) {
                        setState(() => _simulationSpeed = value);
                        unawaited(
                            controller.setSimulationSpeedMultiplier(value));
                      },
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _simMode
                      ? 'Simulation is active with ${_simulationPattern.displayName} at ${controller.simulationDataRateHz.toStringAsFixed(1)} Hz.'
                      : 'Simulation is disabled. Live telemetry will come from BLE when connected.',
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab(int activeAlerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(
          'Alerts & Safety Thresholds',
          'Configure real-time angle and movement thresholds used by the live monitoring engine.',
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: 'Alert Controls',
          subtitle: activeAlerts == 0
              ? 'No active alerts right now.'
              : '$activeAlerts alert${activeAlerts == 1 ? '' : 's'} are currently active.',
          icon: Icons.notifications_active_outlined,
          trailing: Switch(
            value: _alertsEnabled,
            onChanged: (value) async {
              setState(() => _alertsEnabled = value);
              await PreferencesService.setAlertsEnabled(value);
              _syncAnalysisConfig();
            },
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF5A4D9A),
          ),
          child: Column(
            children: [
              _buildSliderTile(
                label: 'Maximum angle threshold',
                value: _maxAngle,
                min: 90,
                max: 180,
                divisions: 18,
                unit: '°',
                activeColor: const Color(0xFF5A4D9A),
                onChanged: (value) async {
                  setState(() => _maxAngle = value);
                  await PreferencesService.setMaxAngleThreshold(value);
                  _syncAnalysisConfig();
                },
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                label: 'Minimum angle threshold',
                value: _minAngle,
                min: 0,
                max: 30,
                divisions: 30,
                unit: '°',
                activeColor: const Color(0xFF5A4D9A),
                onChanged: (value) async {
                  setState(() => _minAngle = value);
                  await PreferencesService.setMinAngleThreshold(value);
                  _syncAnalysisConfig();
                },
              ),
              const SizedBox(height: 16),
              _buildSliderTile(
                label: 'Sudden movement threshold',
                value: _suddenMovement,
                min: 50,
                max: 500,
                divisions: 45,
                unit: '°/s',
                activeColor: const Color(0xFFD32F2F),
                onChanged: (value) async {
                  setState(() => _suddenMovement = value);
                  await PreferencesService.setSuddenMovementThreshold(value);
                  _syncAnalysisConfig();
                },
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 540;
                  final openButton = OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AlertSystemScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Alert Center'),
                  );
                  final dismissButton = FilledButton.icon(
                    onPressed: () {
                      ref.read(alertHistoryProvider.notifier).dismissAll();
                      _showSnack('All current alerts dismissed.');
                    },
                    icon: const Icon(Icons.done_all),
                    label: const Text('Dismiss All'),
                  );

                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        openButton,
                        const SizedBox(height: 12),
                        dismissButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: openButton),
                      const SizedBox(width: 12),
                      Expanded(child: dismissButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(
          'Data & Storage',
          'Keep local session history tidy and navigate to stored records quickly.',
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: 'Local Storage',
          subtitle:
              'This app currently stores session history and daily summaries locally with Hive.',
          icon: Icons.storage_outlined,
          child: Column(
            children: [
              SettingsActionTile(
                title: 'Open session history',
                subtitle:
                    'Review stored sessions, trends, and daily summaries.',
                icon: Icons.history,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              SettingsActionTile(
                title: 'Clear local cache',
                subtitle: 'Remove all locally stored sessions and daily logs.',
                icon: Icons.delete_outline,
                onTap: () => unawaited(_clearLocalCache()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveLayout.headlineSize(context),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildGoalAdjuster({
    required String title,
    required String valueLabel,
    required bool canDecrement,
    required bool canIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  valueLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canDecrement ? onDecrement : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            onPressed: canIncrement ? onIncrement : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required Color activeColor,
    required Future<void> Function(double value) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${value.round()}$unit',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: activeColor,
            label: '${value.round()}$unit',
            onChanged: (next) => unawaited(onChanged(next)),
          ),
        ],
      ),
    );
  }
}
