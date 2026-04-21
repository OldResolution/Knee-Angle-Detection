import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../services/preferences_service.dart';
import '../widgets/responsive/responsive_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTab = 'Account Preferences';
  bool _simMode = true;

  @override
  void initState() {
    super.initState();
    _simMode = PreferencesService.isSimulationMode;
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
            color: Colors.black.withOpacity(0.02),
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
          _buildSidebarItem('System Calibration', Icons.monitor_weight_outlined),
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
            _buildMobileChip('System Calibration'),
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
      case 'System Calibration':
        return _buildLegacySettings();
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
              onPressed: () {},
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

  Widget _buildLegacySettings() {
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
                color: Colors.black.withOpacity(0.02),
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
                subtitle: const Text('Manage connected sensors'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
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
                },
              ),
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
