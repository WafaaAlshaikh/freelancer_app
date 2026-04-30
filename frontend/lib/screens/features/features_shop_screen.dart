// lib/screens/features/features_shop_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class FeaturesShopScreen extends StatefulWidget {
  const FeaturesShopScreen({super.key});

  @override
  State<FeaturesShopScreen> createState() => _FeaturesShopScreenState();
}

class _FeaturesShopScreenState extends State<FeaturesShopScreen> {
  Map<String, double> _prices = {};
  bool _loading = true;
  String? _purchasingFeature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPrices(context);
      }
    });
  }

  Future<void> _loadPrices(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;
    
    setState(() => _loading = true);
    try {
      final response = await ApiService.getFeaturePrices();
      if (response['success'] == true && response['prices'] != null) {
        if (!mounted) return;
        setState(() {
          _prices = Map<String, double>.from(response['prices']);
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: '${t.errorLoadingPrices}: $e');
    }
  }

  Future<void> _purchaseFeature(BuildContext context, String feature, {int? entityId}) async {
    final t = AppLocalizations.of(context)!;
    if (feature == 'project_highlight' && entityId == null) {
      final selectedProject = await _selectProject(context);
      if (selectedProject == null) return;
      entityId = selectedProject.id;
    }
    setState(() => _purchasingFeature = feature);

    try {
      final response = await ApiService.purchaseFeature(
        feature,
        entityId: entityId,
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: t.featurePurchasedSuccess);
        if (mounted) Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? t.purchaseFailed);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    } finally {
      if (mounted) setState(() => _purchasingFeature = null);
    }
  }

  Future<Project?> _selectProject(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final projects = await ApiService.getMyProjects();
    if (projects.isEmpty) {
      Fluttertoast.showToast(msg: t.noProjectsToHighlight);
      return null;
    }
    return await showDialog<Project>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.selectProject,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        children: projects
            .map(
              (p) => SimpleDialogOption(
                child: Text(
                  p.title ?? t.untitled,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                onPressed: () => Navigator.pop(context, p),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.boostYourProfile),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFeatureCard(
                  title: t.featureYourProfile,
                  description: t.featureYourProfileDesc,
                  price: _prices['profile_feature'] ?? 9.99,
                  icon: Icons.rocket_launch,
                  color: AppColors.warning,
                  feature: 'profile_feature',
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  title: t.highlightYourProject,
                  description: t.highlightYourProjectDesc,
                  price: _prices['project_highlight'] ?? 4.99,
                  icon: Icons.bolt,
                  color: AppColors.secondary,
                  feature: 'project_highlight',
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  title: t.skillCertificate,
                  description: t.skillCertificateDesc,
                  price: _prices['skill_certificate'] ?? 29.00,
                  icon: Icons.verified,
                  color: Colors.purple,
                  feature: 'skill_certificate',
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  title: t.aiResumeReview,
                  description: t.aiResumeReviewDesc,
                  price: _prices['ai_resume_review'] ?? 9.99,
                  icon: Icons.auto_awesome,
                  color: AppColors.info,
                  feature: 'ai_resume_review',
                ),
              ],
            ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required double price,
    required IconData icon,
    required Color color,
    required String feature,
  }) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPurchasing = _purchasingFeature == feature;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: isPurchasing ? null : () => _purchaseFeature(context, feature), 
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isPurchasing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.buyNow),
            ),
          ),
        ],
      ),
    );
  }
}