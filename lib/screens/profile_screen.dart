import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/app_footer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC), // Light purple-ish gray background matching mockup
      drawer: const AppDrawer(currentRoute: 'Profile'),
      body: Column(
        children: [
          const AppTopNav(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                 }
                 
                 final data = snapshot.data ?? {};
                 final name = data['name'] as String? ?? 'User';
                 final email = data['email'] as String? ?? 'No email provided';
                 final mobile = data['mobile'] as String? ?? 'N/A';
                 final age = data['age']?.toString() ?? 'N/A';

                 return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      _buildUserAvatarCard(name),
                                      const SizedBox(height: 24),
                                      _buildClinicalTeamCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildPersonalInfoCard(email, mobile, age),
                                      const SizedBox(height: 24),
                                      _buildAccountSettingsCard(),
                                      const SizedBox(height: 24),
                                      _buildDangerZoneCard(),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Mobile/Small Screen Layout
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildUserAvatarCard(name),
                                const SizedBox(height: 24),
                                _buildPersonalInfoCard(email, mobile, age),
                                const SizedBox(height: 24),
                                _buildClinicalTeamCard(),
                                const SizedBox(height: 24),
                                _buildAccountSettingsCard(),
                                const SizedBox(height: 24),
                                _buildDangerZoneCard(),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              }
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Overview',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4C3E8A),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Manage your clinical details and account preferences.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(32)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildUserAvatarCard(String name) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              const CircleAvatar(
                radius: 64,
                backgroundColor: Color(0xFFD6CFF0),
                child: Icon(Icons.person, size: 60, color: Color(0xFF4C3E8A)),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4C3E8A),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 4, right: 4),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 24),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBE8F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: Color(0xFF6750A4)),
                SizedBox(width: 8),
                Text(
                  'Active Recovery',
                  style: TextStyle(
                    color: Color(0xFF6750A4),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildClinicalTeamCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE8F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medical_services_outlined, color: Color(0xFF4C3E8A), size: 24),
              ),
              const SizedBox(width: 16),
              const Text(
                'Clinical Team',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildInfoRow('ATTENDING SPECIALIST', 'Dr. Aris Thorne'),
          const SizedBox(height: 24),
          _buildInfoRow('RECOVERY PLAN', 'Phase 2: Mobility Focus'),
          const SizedBox(height: 24),
          _buildInfoRow('LAST CONSULTATION', 'October 12, 2023'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(String email, String mobile, String age) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Update your contact details and basic info.',
                      style: TextStyle(color: Colors.black54),
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Edit', style: TextStyle(color: Color(0xFF4C3E8A), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildTextField('Email Address', email, Icons.email_outlined),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              SizedBox(width: 250, child: _buildTextField('Phone Number', mobile, Icons.phone_outlined)),
              SizedBox(width: 250, child: _buildTextField('Age', age, Icons.calendar_today_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F4F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF4C3E8A), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettingsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your notifications and security.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Color(0xFF4C3E8A), size: 20),
              SizedBox(width: 12),
              Text(
                'Notification Preferences',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F4F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildToggleRow('Email Updates', 'Weekly recovery summaries', true),
                const SizedBox(height: 24),
                _buildToggleRow('Push Notifications', 'Daily session reminders', true),
                const SizedBox(height: 24),
                _buildToggleRow('SMS Alerts', 'Urgent clinical messages only', false),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Row(
            children: [
              Icon(Icons.security, color: Color(0xFF4C3E8A), size: 20),
              SizedBox(width: 12),
              Text(
                'Security',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.key, color: Color(0xFF4C3E8A), size: 18),
            label: const Text(
              'Change Password',
              style: TextStyle(color: Color(0xFF4C3E8A), fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: const BorderSide(color: Color(0xFFE2E2E6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool initialValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: initialValue,
          onChanged: (val) {},
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF4C3E8A),
        ),
      ],
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5), // Light red background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Once you delete your account, there is no going back. Please be certain.',
            style: TextStyle(color: Colors.black87, fontSize: 14),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Deactivate Account',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
