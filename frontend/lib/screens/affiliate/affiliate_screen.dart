import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AffiliateScreen extends StatefulWidget {
  const AffiliateScreen({super.key});

  @override
  State<AffiliateScreen> createState() => _AffiliateScreenState();
}

class _AffiliateScreenState extends State<AffiliateScreen> {
  String? _referralCode;
  double _totalEarnings = 0;
  List<dynamic> _referrals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final response = await ApiService.getAffiliateInfo();
      setState(() {
        _referralCode = response['referralCode'];
        _totalEarnings = response['totalEarnings'] ?? 0;
        _referrals = response['referrals'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: t.errorLoadingData);
    }
  }

  void _shareCode() {
    final t = AppLocalizations.of(context)!;
    if (_referralCode != null) {
      Share.share('${t.shareReferralMessage} $_referralCode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.referAndEarn),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    color: theme.cardColor,
                    elevation: isDark ? 1 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            t.yourReferralCode,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              _referralCode ?? t.loading,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _shareCode,
                            icon: const Icon(Icons.share),
                            label: Text(t.shareCode),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: theme.cardColor,
                    elevation: isDark ? 1 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            t.totalEarnings,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${t.dollar}${_totalEarnings.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_referrals.isNotEmpty)
                    Card(
                      color: theme.cardColor,
                      elevation: isDark ? 1 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.referredFriends,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._referrals.map(
                              (ref) => ListTile(
                                leading: Icon(
                                  Icons.person,
                                  color: theme.colorScheme.primary,
                                ),
                                title: Text(
                                  ref['name'] ?? t.user,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  ref['joinedAt'] ?? '',
                                  style: TextStyle(color: AppColors.gray),
                                ),
                                trailing: Text(
                                  '${t.dollar}${ref['commission'] ?? 0}',
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
