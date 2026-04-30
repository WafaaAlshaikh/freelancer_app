// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:freelancer_platform/services/api_service.dart';
import 'package:freelancer_platform/services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChange;

  const SettingsScreen({super.key, this.onLocaleChange});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en';
  String _selectedCurrency = 'USD';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final savedLocale = await LanguageService.getSavedLocale();
    setState(() {
      _selectedLanguage = savedLocale.languageCode;
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() => _isLoading = true);

    final newLocale = Locale(languageCode);
    await LanguageService.setLocale(newLocale);

    setState(() {
      _selectedLanguage = languageCode;
      _isLoading = false;
    });

    if (widget.onLocaleChange != null) {
      widget.onLocaleChange!(newLocale);
    }

    Fluttertoast.showToast(
      msg: languageCode == 'ar'
          ? 'تم تغيير اللغة إلى العربية'
          : 'Language changed to English',
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings), centerTitle: false, elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader(
                  context,
                  t.appearance,
                  Icons.palette_outlined,
                ),

                _buildSettingsTile(
                  context,
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  title: t.darkMode,
                  subtitle: t.switchTheme,
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeColor: AppColors.primary,
                  ),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.brightness_auto,
                  title: t.useSystemTheme,
                  subtitle: t.followSystemTheme,
                  trailing: Switch(
                    value: themeProvider.themeMode == ThemeMode.system,
                    onChanged: (value) {
                      if (value) {
                        themeProvider.setThemeMode(ThemeMode.system);
                      }
                    },
                    activeColor: AppColors.primary,
                  ),
                ),

                const Divider(),

                _buildSectionHeader(context, t.account, Icons.person_outline),

                _buildSettingsTile(
                  context,
                  icon: Icons.edit_outlined,
                  title: t.editProfile,
                  subtitle: t.updatePersonalInfo,
                  onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.lock_outline,
                  title: t.changePassword,
                  subtitle: t.updatePassword,
                  onTap: () => Navigator.pushNamed(context, '/change-password'),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: t.notifications,
                  subtitle: t.manageNotifications,
                  onTap: () =>
                      Navigator.pushNamed(context, '/notification-settings'),
                ),

                const Divider(),

                _buildSectionHeader(
                  context,
                  t.preferences,
                  Icons.tune_outlined,
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.language_outlined,
                  title: t.language,
                  subtitle: _selectedLanguage == 'ar'
                      ? 'العربية'
                      : 'English (US)',
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _showLanguageDialog(context),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.attach_money,
                  title: t.currency,
                  subtitle: _getCurrencyText(),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _showCurrencyDialog(context),
                ),

                const Divider(),

                _buildSectionHeader(
                  context,
                  t.support,
                  Icons.support_agent_outlined,
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: t.helpCenter,
                  subtitle: t.getHelpSupport,
                  onTap: () => Navigator.pushNamed(context, '/help'),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.description_outlined,
                  title: t.termsOfService,
                  subtitle: t.readTerms,
                  onTap: () => Navigator.pushNamed(context, '/terms'),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: t.privacyPolicy,
                  subtitle: t.readPrivacy,
                  onTap: () => Navigator.pushNamed(context, '/privacy'),
                ),

                _buildSettingsTile(
                  context,
                  icon: Icons.star_outline,
                  title: t.rateUs,
                  subtitle: t.rateApp,
                  onTap: () => _showRateDialog(context),
                ),

                const Divider(),

                _buildSectionHeader(context, t.about, Icons.info_outline),

                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: t.about,
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      t.logout,
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  String _getCurrencyText() {
    switch (_selectedCurrency) {
      case 'USD':
        return 'USD - US Dollar';
      case 'EUR':
        return 'EUR - Euro';
      case 'GBP':
        return 'GBP - British Pound';
      default:
        return 'USD - US Dollar';
    }
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ??
          (onTap != null ? const Icon(Icons.chevron_right, size: 20) : null),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English (US)'),
              trailing: _selectedLanguage == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _changeLanguage('en');
              },
            ),
            ListTile(
              leading: const Text('🇸🇦'),
              title: const Text('العربية'),
              trailing: _selectedLanguage == 'ar'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _changeLanguage('ar');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('USD - US Dollar'),
              trailing: _selectedCurrency == 'USD'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedCurrency = 'USD');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('EUR - Euro'),
              trailing: _selectedCurrency == 'EUR'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedCurrency = 'EUR');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('GBP - British Pound'),
              trailing: _selectedCurrency == 'GBP'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedCurrency = 'GBP');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Us'),
        content: const Text(
          'If you enjoy using our app, please take a moment to rate it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Freelancer Platform',
      applicationVersion: 'Version 1.0.0',
      applicationLegalese: '© 2024 Freelancer Platform',
      children: const [
        SizedBox(height: 16),
        Text('Connect freelancers with clients around the world.'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.logout),
        content: Text(t.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.logout),
          ),
        ],
      ),
    );
  }
}
