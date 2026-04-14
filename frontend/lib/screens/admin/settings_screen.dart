// lib/screens/admin/settings_screen.dart
import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  bool _autoVerifyEmail = false;
  bool _sendWeeklyReports = true;
  bool _flagHighRiskPayments = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Platform Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.tune)),
            Tab(text: 'Security', icon: Icon(Icons.shield_outlined)),
            Tab(text: 'Notifications', icon: Icon(Icons.notifications_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralSettings(),
          _buildSecuritySettings(),
          _buildNotificationSettings(),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Platform Controls',
          icon: Icons.settings_suggest,
          children: [
            _switchTile(
              title: 'Maintenance Mode',
              subtitle: 'Temporarily disable user access to the platform.',
              value: _maintenanceMode,
              onChanged: (v) => setState(() => _maintenanceMode = v),
            ),
            _switchTile(
              title: 'Allow New Registrations',
              subtitle: 'Enable signup for new users.',
              value: _allowNewRegistrations,
              onChanged: (v) => setState(() => _allowNewRegistrations = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Default Configuration',
          icon: Icons.dashboard_customize_outlined,
          children: const [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Default Client Plan'),
              subtitle: Text('Starter'),
              trailing: Icon(Icons.chevron_right),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Default Freelancer Visibility'),
              subtitle: Text('Public'),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Verification',
          icon: Icons.verified_user_outlined,
          children: [
            _switchTile(
              title: 'Auto Verify Email Domains',
              subtitle: 'Automatically verify trusted business domains.',
              value: _autoVerifyEmail,
              onChanged: (v) => setState(() => _autoVerifyEmail = v),
            ),
            _switchTile(
              title: 'Flag High-Risk Payments',
              subtitle: 'Detect and mark suspicious payment activity.',
              value: _flagHighRiskPayments,
              onChanged: (v) => setState(() => _flagHighRiskPayments = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Access Rules',
          icon: Icons.admin_panel_settings_outlined,
          children: const [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Admin Session Timeout'),
              subtitle: Text('45 minutes'),
              trailing: Icon(Icons.chevron_right),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('2FA Requirement'),
              subtitle: Text('Required for admins'),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Admin Alerts',
          icon: Icons.notifications_active_outlined,
          children: [
            _switchTile(
              title: 'Weekly Performance Report',
              subtitle: 'Receive summary every Monday.',
              value: _sendWeeklyReports,
              onChanged: (v) => setState(() => _sendWeeklyReports = v),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Critical Incident Alerts'),
              subtitle: Text('Email + in-app'),
              trailing: Icon(Icons.chevron_right),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Dispute Escalation Alerts'),
              subtitle: Text('Instant push'),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF6C63FF),
    );
  }
}