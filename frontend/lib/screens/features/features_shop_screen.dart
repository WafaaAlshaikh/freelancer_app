// lib/screens/features/features_shop_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/models/project_model.dart';
import '../../services/api_service.dart';

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
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getFeaturePrices();
      if (response['success'] == true && response['prices'] != null) {
        setState(() {
          _prices = Map<String, double>.from(response['prices']);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Error loading prices: $e');
    }
  }

  Future<void> _purchaseFeature(String feature, {int? entityId}) async {
    if (feature == 'project_highlight' && entityId == null) {
      final selectedProject = await _selectProject();
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
        Fluttertoast.showToast(msg: '✅ Feature purchased successfully!');
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Purchase failed');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _purchasingFeature = null);
    }
  }

  Future<Project?> _selectProject() async {
    final projects = await ApiService.getMyProjects();
    if (projects.isEmpty) {
      Fluttertoast.showToast(msg: 'You have no projects to highlight');
      return null;
    }
    return await showDialog<Project>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Select a project'),
        children: projects
            .map(
              (p) => SimpleDialogOption(
                child: Text(p.title ?? 'Untitled'),
                onPressed: () => Navigator.pop(context, p),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Boost Your Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFeatureCard(
                  title: 'Feature Your Profile',
                  description:
                      'Get featured at the top of search results for 7 days',
                  price: _prices['profile_feature'] ?? 9.99,
                  icon: Icons.rocket_launch,
                  color: Colors.orange,
                  feature: 'profile_feature',
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  title: 'Highlight Your Project',
                  description:
                      'Make your project stand out with a highlight badge',
                  price: _prices['project_highlight'] ?? 4.99,
                  icon: Icons.bolt,
                  color: Colors.amber,
                  feature: 'project_highlight',
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  title: 'Skill Certificate',
                  description: 'Get certified and earn a verified badge',
                  price: _prices['skill_certificate'] ?? 29.00,
                  icon: Icons.verified,
                  color: Colors.purple,
                  feature: 'skill_certificate',
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  title: 'AI Resume Review',
                  description: 'Get professional feedback on your resume',
                  price: _prices['ai_resume_review'] ?? 9.99,
                  icon: Icons.auto_awesome,
                  color: Colors.blue,
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
    final isPurchasing = _purchasingFeature == feature;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
              onPressed: isPurchasing ? null : () => _purchaseFeature(feature),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isPurchasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buy Now'),
            ),
          ),
        ],
      ),
    );
  }
}
