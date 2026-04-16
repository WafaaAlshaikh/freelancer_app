// lib/screens/admin/settings_screen.dart
import 'package:flutter/material.dart';

const _kAccent = Color(0xFF5B58E2);
const _kAccentLight = Color(0xFF8B88FF);
const _kGreen = Color(0xFF14A800);
const _kPageBg = Color(0xFFF0F2F8);

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  bool _autoVerifyEmail = false;
  bool _sendWeeklyReports = true;
  bool _flagHighRiskPayments = true;

  static const _tabs = [
    {
      'label': 'General',
      'icon': Icons.tune_rounded,
      'color': Color(0xFF5B58E2),
    },
    {
      'label': 'Security',
      'icon': Icons.shield_outlined,
      'color': Color(0xFF14A800),
    },
    {
      'label': 'Notifications',
      'icon': Icons.notifications_outlined,
      'color': Color(0xFFF59E0B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(
      () => setState(() => _selectedTab = _tabController.index),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Row(
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final selected = _selectedTab == i;
                  final color = tab['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? LinearGradient(
                                  colors: [
                                    color.withOpacity(0.15),
                                    color.withOpacity(0.05),
                                  ],
                                )
                              : null,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: selected ? color : Colors.transparent,
                              width: 2,
                            ),
                            left: BorderSide(
                              color: selected
                                  ? color.withOpacity(0.2)
                                  : Colors.transparent,
                            ),
                            right: BorderSide(
                              color: selected
                                  ? color.withOpacity(0.2)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab['icon'] as IconData,
                              size: 16,
                              color: selected ? color : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tab['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: selected ? color : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              Divider(height: 1, color: Colors.grey.shade100),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGeneralSettings(),
              _buildSecuritySettings(),
              _buildNotificationSettings(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Platform Controls',
            Icons.settings_suggest_rounded,
            _kAccent,
          ),
          const SizedBox(height: 12),
          _settingsCard([
            _switchTile(
              'Maintenance Mode',
              'Temporarily disable user access to the platform.',
              Icons.construction_rounded,
              Colors.orange,
              _maintenanceMode,
              (v) => setState(() => _maintenanceMode = v),
            ),
            _divider(),
            _switchTile(
              'Allow New Registrations',
              'Enable signup for new users on the platform.',
              Icons.person_add_outlined,
              _kGreen,
              _allowNewRegistrations,
              (v) => setState(() => _allowNewRegistrations = v),
            ),
          ]),

          const SizedBox(height: 20),
          _sectionHeader(
            'Default Configuration',
            Icons.dashboard_customize_outlined,
            _kAccent,
          ),
          const SizedBox(height: 12),
          _settingsCard([
            _arrowTile(
              'Default Client Plan',
              'Starter',
              Icons.subscriptions_outlined,
              _kAccent,
            ),
            _divider(),
            _arrowTile(
              'Default Freelancer Visibility',
              'Public',
              Icons.visibility_outlined,
              _kGreen,
            ),
            _divider(),
            _arrowTile(
              'Platform Commission Rate',
              '10%',
              Icons.percent_rounded,
              Colors.orange,
            ),
          ]),

          const SizedBox(height: 20),
          _sectionHeader('Appearance', Icons.palette_outlined, _kAccent),
          const SizedBox(height: 12),
          _settingsCard([
            _arrowTile(
              'Platform Theme',
              'Default',
              Icons.color_lens_outlined,
              Colors.purple,
            ),
            _divider(),
            _arrowTile(
              'Logo & Branding',
              'Configured',
              Icons.image_outlined,
              Colors.blue,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Verification', Icons.verified_user_outlined, _kGreen),
          const SizedBox(height: 12),
          _settingsCard([
            _switchTile(
              'Auto Verify Email Domains',
              'Automatically verify trusted business email domains.',
              Icons.mark_email_read_outlined,
              _kGreen,
              _autoVerifyEmail,
              (v) => setState(() => _autoVerifyEmail = v),
            ),
            _divider(),
            _switchTile(
              'Flag High-Risk Payments',
              'Detect and mark suspicious payment activity.',
              Icons.security_outlined,
              Colors.red,
              _flagHighRiskPayments,
              (v) => setState(() => _flagHighRiskPayments = v),
            ),
          ]),

          const SizedBox(height: 20),
          _sectionHeader(
            'Access Rules',
            Icons.admin_panel_settings_outlined,
            _kGreen,
          ),
          const SizedBox(height: 12),
          _settingsCard([
            _arrowTile(
              'Admin Session Timeout',
              '45 minutes',
              Icons.timer_outlined,
              Colors.orange,
            ),
            _divider(),
            _arrowTile(
              '2FA Requirement',
              'Required for admins',
              Icons.phonelink_lock_outlined,
              _kAccent,
            ),
            _divider(),
            _arrowTile(
              'IP Whitelist',
              'Not configured',
              Icons.language_outlined,
              Colors.grey,
            ),
          ]),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGreen.withOpacity(0.08), _kGreen.withOpacity(0.02)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGreen.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14A800), Color(0xFF0A6E00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Status: Good',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1B3E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All critical security features are configured properly.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Admin Alerts',
            Icons.notifications_active_outlined,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _settingsCard([
            _switchTile(
              'Weekly Performance Report',
              'Receive a comprehensive summary every Monday morning.',
              Icons.assessment_outlined,
              const Color(0xFFF59E0B),
              _sendWeeklyReports,
              (v) => setState(() => _sendWeeklyReports = v),
            ),
            _divider(),
            _arrowTile(
              'Critical Incident Alerts',
              'Email + in-app',
              Icons.warning_amber_rounded,
              Colors.red,
            ),
            _divider(),
            _arrowTile(
              'Dispute Escalation Alerts',
              'Instant push',
              Icons.gavel_rounded,
              Colors.orange,
            ),
            _divider(),
            _arrowTile(
              'New User Registrations',
              'Daily digest',
              Icons.person_add_outlined,
              _kAccent,
            ),
          ]),

          const SizedBox(height: 20),
          _sectionHeader(
            'Email Configuration',
            Icons.email_outlined,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _settingsCard([
            _arrowTile(
              'SMTP Settings',
              'Configured',
              Icons.settings_outlined,
              _kGreen,
            ),
            _divider(),
            _arrowTile(
              'Email Templates',
              '12 templates',
              Icons.description_outlined,
              _kAccent,
            ),
            _divider(),
            _arrowTile(
              'Sender Name & Address',
              'Platform Admin',
              Icons.alternate_email_rounded,
              Colors.grey,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1B3E),
          ),
        ),
      ],
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    indent: 20,
    endIndent: 20,
    color: Colors.grey.shade100,
  );

  Widget _switchTile(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1B3E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _kAccent,
          ),
        ],
      ),
    );
  }

  Widget _arrowTile(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1B3E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }
}
