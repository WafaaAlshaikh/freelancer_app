// screens/freelancer/freelancer_home_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freelancer_platform/screens/affiliate/affiliate_screen.dart';
import 'package:freelancer_platform/screens/chat/chats_list_screen.dart';
import 'package:freelancer_platform/screens/contract/my_contracts_screen.dart';
import 'package:freelancer_platform/screens/features/features_shop_screen.dart';
import 'package:freelancer_platform/screens/freelancer/advanced_search_screen.dart';
import 'package:freelancer_platform/screens/freelancer/edit_profile_screen.dart';
import 'package:freelancer_platform/screens/freelancer/favorites_screen.dart';
import 'package:freelancer_platform/screens/freelancer/financial_dashboard_screen.dart';
import 'package:freelancer_platform/screens/notifications/notifications_screen.dart';
import 'package:freelancer_platform/screens/skill_tests/skill_tests_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/freelancer_model.dart';
import '../../models/project_model.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import 'project_details_screen.dart';
import 'my_proposals_screen.dart';
import 'my_projects_screen.dart';
import 'projects_tab.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppColors {
  static const sidebarBg = Color(0xFF2D2B55);
  static const sidebarText = Color(0xFFC8C6E8);
  static const sidebarActive = Color(0xFF5B58E2);
  static const accent = Color(0xFF6C63FF);
  static const accentLight = Color(0xFFA78BFA);
  static const green = Color(0xFF14A800);
  static const pageBg = Color(0xFFF5F6F8);
  static const cardBg = Colors.white;
}

enum ProjectFilter { bestMatches, mostRecent, saved }

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumber;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final fill = (rating >= index + 1)
              ? 1.0
              : (rating > index ? rating - index : 0.0);
          return Icon(
            fill >= 0.5 ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          );
        }),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}

class PortfolioCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const PortfolioCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(item['images'] ?? []);
    final technologies = List<String>.from(item['technologies'] ?? []);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: images.length == 1
                    ? CachedNetworkImage(
                        imageUrl: images[0],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 40,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: images[i],
                            width: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['description'] ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (technologies.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: technologies
                          .map(
                            (tech) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tech,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  final int? badge;
  final bool badgeGreen;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.badge,
    this.badgeGreen = false,
  });
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final FreelancerProfile? profile;
  final String avatarUrl;
  final VoidCallback onEditProfile;

  const _Sidebar({
    required this.selectedIndex,
    required this.onItemTap,
    required this.profile,
    required this.avatarUrl,
    required this.onEditProfile,
  });

  static const _items = [
    _SidebarItem(icon: Icons.person_outline, label: 'Home'),
    _SidebarItem(icon: Icons.search, label: 'Find Work'),
    _SidebarItem(icon: Icons.send_outlined, label: 'My Proposals', badge: 3),
    _SidebarItem(icon: Icons.work_outline, label: 'My Projects'),
    _SidebarItem(
      icon: Icons.description_outlined,
      label: 'Contracts',
      badge: 2,
      badgeGreen: true,
    ),
    _SidebarItem(icon: Icons.favorite_border, label: 'Favorites'),
    _SidebarItem(icon: Icons.attach_money, label: 'Financial'),
    _SidebarItem(icon: Icons.filter_alt, label: 'Advanced Search'),
    _SidebarItem(icon: Icons.chat_bubble_outline, label: 'Messages', badge: 1),
    _SidebarItem(icon: Icons.quiz_outlined, label: 'Skill Tests'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Text(
              'FREELANCER',
              style: TextStyle(
                color: AppColors.accentLight,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),

          GestureDetector(
            onTap: onEditProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accentLight,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            profile?.name?.isNotEmpty == true
                                ? profile!.name![0].toUpperCase()
                                : 'F',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.name ?? 'Freelancer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          profile?.title ?? 'Developer',
                          style: const TextStyle(
                            color: AppColors.accentLight,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                final isActive = selectedIndex == i;
                return GestureDetector(
                  onTap: () => onItemTap(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accent.withOpacity(0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isActive
                          ? Border(
                              left: const BorderSide(
                                color: AppColors.accent,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: isActive
                              ? Colors.white
                              : AppColors.sidebarText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.sidebarText,
                              fontWeight: isActive
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (item.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.badgeGreen
                                  ? AppColors.green
                                  : AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.badge}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _sidebarActionBtn(Icons.settings_outlined, 'Settings'),
                const SizedBox(height: 6),
                _sidebarActionBtn(
                  Icons.logout,
                  'Logout',
                  color: Colors.red.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarActionBtn(
    IconData icon,
    String label, {
    Color color = AppColors.sidebarText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Card number',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '236 *** **** 265',
              style: TextStyle(letterSpacing: 2, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: [
              _pmItem(
                'Western Union',
                Colors.orange.shade50,
                Colors.orange.shade700,
              ),
              _pmItem('G Pay', Colors.blue.shade50, Colors.blue.shade700),
              _pmItem('Mastercard', Colors.red.shade50, Colors.red.shade700),
              _pmItem('VISA', Colors.green.shade50, Colors.green.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pmItem(String label, Color bg, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final VoidCallback onSubscribe;

  const _PremiumCard({required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Freelancer Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Individual subscription',
            style: TextStyle(color: AppColors.accentLight, fontSize: 11),
          ),
          const SizedBox(height: 12),
          ...[
            '1 month Premium free',
            '2 months for students discount',
            'Cancel anytime',
            'Best deals & offers monthly',
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check,
                    color: AppColors.accentLight,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.sidebarText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.sidebarBg,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Subscribe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});

  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen> {
  FreelancerProfile? profile;
  List<Project> recommendedProjects = [];
  List<Project> aiSuggestedProjects = [];
  List<Contract> activeContracts = [];
  Map<String, dynamic>? stats;
  List<Map<String, dynamic>> portfolioItems = [];
  int _unreadNotificationsCount = 0;
  int _selectedNavIndex = 0;

  bool loadingProfile = true;
  bool loadingProjects = true;
  bool loadingSuggestions = true;
  bool loadingContracts = true;
  bool loadingPortfolio = true;

  final int _unreadMessages = 3;
  ProjectFilter _projectFilter = ProjectFilter.bestMatches;
  List<Project> _savedProjects = [];
  bool _loadingSaved = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _loadUnreadNotificationsCount();
  }

  Future<void> _loadUnreadNotificationsCount() async {
    try {
      final result = await ApiService.getUnreadCount();
      setState(() {
        _unreadNotificationsCount = result['unreadCount'] ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      fetchProfile(),
      fetchRecommendedProjects(),
      fetchAISuggestions(),
      fetchStats(),
      fetchActiveContracts(),
      fetchPortfolio(),
    ]);
  }

  Future<void> _loadSavedProjects() async {
    setState(() => _loadingSaved = true);
    try {
      final response = await ApiService.getUserFavorites();
      if (response.success) {
        setState(() {
          _savedProjects = response.favorites.map((f) => f.project).toList();
          _loadingSaved = false;
        });
      }
    } catch (e) {
      setState(() => _loadingSaved = false);
    }
  }

  List<Project> get _filteredProjects {
    switch (_projectFilter) {
      case ProjectFilter.bestMatches:
        return aiSuggestedProjects;
      case ProjectFilter.mostRecent:
        return [...recommendedProjects]
          ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      case ProjectFilter.saved:
        return _savedProjects;
    }
  }

  String get _filterTitle {
    switch (_projectFilter) {
      case ProjectFilter.bestMatches:
        return "Best Matches";
      case ProjectFilter.mostRecent:
        return "Most Recent";
      case ProjectFilter.saved:
        return "Saved Jobs";
    }
  }

  Widget _buildProjectFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildFilterTab(ProjectFilter.bestMatches, "Best Matches"),
          const SizedBox(width: 16),
          _buildFilterTab(ProjectFilter.mostRecent, "Most Recent"),
          const SizedBox(width: 16),
          _buildFilterTab(ProjectFilter.saved, "Saved Jobs"),
        ],
      ),
    );
  }

  Widget _buildFilterTab(ProjectFilter filter, String label) {
    final isSelected = _projectFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _projectFilter = filter);
        if (filter == ProjectFilter.saved && _savedProjects.isEmpty) {
          _loadSavedProjects();
        }
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? const Color(0xff14A800)
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            color: isSelected ? const Color(0xff14A800) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
    final projects = _filteredProjects;

    if (_projectFilter == ProjectFilter.saved &&
        _savedProjects.isEmpty &&
        !_loadingSaved) {
      _loadSavedProjects();
    }

    final isLoading = _projectFilter == ProjectFilter.bestMatches
        ? loadingSuggestions
        : _projectFilter == ProjectFilter.saved
        ? _loadingSaved
        : false;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (projects.isEmpty) {
      if (_projectFilter == ProjectFilter.saved) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.favorite_border,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No saved jobs yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    setState(() => _projectFilter = ProjectFilter.bestMatches),
                child: const Text('Browse projects'),
              ),
            ],
          ),
        );
      }

      if (_projectFilter == ProjectFilter.bestMatches &&
          loadingSuggestions == false) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.auto_awesome, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No AI suggestions yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: fetchAISuggestions,
                child: const Text('Refresh suggestions'),
              ),
            ],
          ),
        );
      }

      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _filterTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (projects.length > 3)
                TextButton(
                  onPressed: () => setState(() => _selectedNavIndex = 1),
                  child: const Text('View All'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...projects.take(3).map((project) => _buildProjectCard(project)),
      ],
    );
  }

  Future<void> fetchProfile() async {
    setState(() => loadingProfile = true);
    try {
      final res = await ApiService.getProfile();
      setState(() {
        profile = FreelancerProfile.fromJson(res);
        loadingProfile = false;
      });
    } catch (e) {
      setState(() => loadingProfile = false);
      Fluttertoast.showToast(msg: 'Error loading profile: $e');
    }
  }

  Future<void> fetchRecommendedProjects() async {
    setState(() => loadingProjects = true);
    try {
      final data = await ApiService.getAllProjects();
      setState(() {
        recommendedProjects = data
            .map((j) => Project.fromJson(j))
            .take(5)
            .toList();
        loadingProjects = false;
      });
    } catch (e) {
      setState(() => loadingProjects = false);
    }
  }

  Future<void> fetchAISuggestions() async {
    setState(() => loadingSuggestions = true);
    try {
      final response = await ApiService.getAISuggestedProjects();
      if (response['success'] == true && response['suggestions'] != null) {
        setState(() {
          aiSuggestedProjects = (response['suggestions'] as List).map((j) {
            final project = Project.fromJson(j);
            if (j['matchScore'] != null) {
              project.matchScore = j['matchScore'];
            }
            return project;
          }).toList();
          loadingSuggestions = false;
        });
      } else {
        setState(() => loadingSuggestions = false);
      }
    } catch (e) {
      setState(() => loadingSuggestions = false);
    }
  }

  Future<void> fetchActiveContracts() async {
    setState(() => loadingContracts = true);
    try {
      final data = await ApiService.getFreelancerContracts();
      setState(() {
        activeContracts = data
            .map((j) => Contract.fromJson(j))
            .where(
              (c) =>
                  c.status == 'active' ||
                  c.status == 'pending_freelancer' ||
                  c.status == 'pending_client',
            )
            .toList();
        loadingContracts = false;
      });
    } catch (e) {
      setState(() {
        activeContracts = [];
        loadingContracts = false;
      });
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await ApiService.getFreelancerStats();
      setState(() => stats = response['stats']);
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<void> fetchPortfolio() async {
    setState(() => loadingPortfolio = true);
    try {
      final response = await ApiService.getPortfolio(profile?.id);
      setState(() {
        portfolioItems = List<Map<String, dynamic>>.from(response);
        loadingPortfolio = false;
      });
    } catch (e) {
      setState(() => loadingPortfolio = false);
    }
  }

  void navigateToEditProfile() async {
    if (profile == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile!)),
    );
    if (result == true) {
      await fetchProfile();
      await fetchPortfolio();
    }
  }

  Future<void> _openChatWithClient(
    int? clientId,
    String clientName,
    String? clientAvatar,
  ) async {
    if (clientId == null || clientId == 0) {
      Fluttertoast.showToast(msg: 'Cannot start chat: Client ID is missing');
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await ChatService.createChat(clientId);
      if (mounted) Navigator.pop(context);
      final chatId = result['success'] == true
          ? (result['chat']?['id'])
          : result['id'];
      if (chatId == null || chatId == 0) {
        Fluttertoast.showToast(msg: 'Failed to create chat.');
        return;
      }
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'chatId': chatId,
            'otherUserId': clientId,
            'otherUserName': clientName.isNotEmpty ? clientName : 'Client',
            'otherUserAvatar': clientAvatar,
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Error opening chat: $e');
    }
  }

  double get profileCompletion {
    int completed = 0;
    const int total = 9;
    if (profile?.name?.isNotEmpty == true) completed++;
    if (profile?.title?.isNotEmpty == true) completed++;
    if (profile?.bio?.isNotEmpty == true) completed++;
    if (profile?.avatar?.isNotEmpty == true) completed++;
    if (profile?.skills?.isNotEmpty == true) completed++;
    if (profile?.cvUrl?.isNotEmpty == true) completed++;
    if (portfolioItems.isNotEmpty) completed++;
    if ((profile?.hourlyRate ?? 0) > 0) completed++;
    if (profile?.location?.isNotEmpty == true) completed++;
    return completed / total * 100;
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    return 'http://localhost:5000$avatar';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  Color _getMatchScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.blue;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending_freelancer':
      case 'pending_client':
        return Colors.orange;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'active':
        return 'In Progress';
      case 'pending_freelancer':
        return 'Pending Your Signature';
      case 'pending_client':
        return 'Pending Client';
      case 'completed':
        return 'Completed';
      default:
        return status ?? 'Unknown';
    }
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await ApiService.logout();
                  Navigator.pop(context);
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),

          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _selectedNavIndex = 1),
          ),

          IconButton(
            icon: const Icon(Icons.star_border),
            tooltip: 'Upgrade Plan',
            onPressed: () =>
                Navigator.pushNamed(context, '/subscription/plans'),
          ),

          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Wallet',
            onPressed: () => Navigator.pushNamed(
              context,
              '/wallet',
              arguments: 'freelancer',
            ),
          ),

          IconButton(
            icon: const Icon(Icons.shopping_bag),
            tooltip: 'Buy Features',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeaturesShopScreen()),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.interpreter_mode),
            onPressed: () {
              Navigator.pushNamed(context, '/interviews');
            },
            tooltip: 'Interviews',
          ),

          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatsListScreen()),
                ),
              ),
              if (_unreadMessages > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    child: Text(
                      '$_unreadMessages',
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ).then((_) => _loadUnreadNotificationsCount());
                },
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    child: Text(
                      _unreadNotificationsCount > 99
                          ? '99+'
                          : '$_unreadNotificationsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final shareUrl =
                  '${dotenv.env['FRONTEND_URL']}/freelancer/${profile?.id}';
              await Share.share('Check out my profile: $shareUrl');
            },
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'affiliate') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AffiliateScreen()),
                );
              } else if (value == 'compare') {
                Navigator.pushNamed(context, '/subscription/comparison');
              } else if (value == 'subscriptionn') {
                Navigator.pushNamed(context, '/subscription/plans');
              } else if (value == 'subscription') {
                Navigator.pushNamed(context, '/subscription/my');
              } else if (value == 'settings') {
                Fluttertoast.showToast(msg: 'Settings coming soon');
              } else if (value == 'help') {
                Fluttertoast.showToast(msg: 'Help coming soon');
              } else if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'subscriptionn',
                child: Row(
                  children: [
                    Icon(Icons.star_border),
                    SizedBox(width: 12),
                    Text('My Subscription'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'affiliate',
                child: Row(
                  children: [
                    Icon(Icons.people),
                    SizedBox(width: 12),
                    Text('Refer & Earn'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'compare',
                child: Row(
                  children: [
                    Icon(Icons.compare_arrows),
                    SizedBox(width: 12),
                    Text('Compare Plans'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help),
                    SizedBox(width: 12),
                    Text('Help & Support'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'subscription',
                child: Row(
                  children: [
                    Icon(Icons.subscriptions),
                    SizedBox(width: 12),
                    Text('Subscription Plans'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    final avatarUrl = _getAvatarUrl(profile?.avatar);
    final totalProposals = stats?['totalProposals'] ?? 0;
    final acceptedProposals = stats?['acceptedProposals'] ?? 0;
    final jss = totalProposals > 0
        ? (acceptedProposals / totalProposals * 100).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.accentLight,
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        profile?.name?.isNotEmpty == true
                            ? profile!.name![0].toUpperCase()
                            : 'F',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? 'Freelancer',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (profile?.title?.isNotEmpty == true)
                      Text(
                        profile!.title!,
                        style: TextStyle(fontSize: 13, color: AppColors.accent),
                      ),
                    const SizedBox(height: 8),
                    // _infoRow(Icons.calendar_today_outlined,
                    //     'Joined: ${_formatDate(profile?.createdAt)}'),
                    if (profile?.location?.isNotEmpty == true)
                      _infoRow(Icons.location_on_outlined, profile!.location!),
                    if (profile?.email?.isNotEmpty == true)
                      _infoRow(Icons.email_outlined, profile!.email!),
                  ],
                ),
              ),
              GestureDetector(
                onTap: navigateToEditProfile,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.work_outline,
                  value: stats?['activeProjects']?.toString() ?? '0',
                  label: 'Active',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.send_outlined,
                  value: stats?['totalProposals']?.toString() ?? '0',
                  label: 'Proposals',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.star_outline,
                  value: profile?.rating?.toStringAsFixed(1) ?? '0.0',
                  label: 'Rating',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  value: '$jss%',
                  label: 'JSS',
                  color: AppColors.green,
                ),
              ),
            ],
          ),

          if (profileCompletion < 100) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile Completion',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  '${profileCompletion.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: profileCompletion / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProjectsList() {
    if (loadingContracts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (activeContracts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Projects 🔥',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedNavIndex = 4),
                child: const Text(
                  'View All',
                  style: TextStyle(color: AppColors.accent, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...activeContracts.take(3).map(_buildContractListItem),
        ],
      ),
    );
  }

  Widget _buildContractListItem(Contract contract) {
    final project = contract.project;
    if (project == null) return const SizedBox.shrink();

    double progress = 0;
    if (contract.milestones?.isNotEmpty == true) {
      final completed = contract.milestones!
          .where((m) => m['status'] == 'completed')
          .length;
      progress = completed / contract.milestones!.length;
    } else {
      progress = contract.status == 'active' ? 0.5 : 0.2;
    }

    final statusColor = _getStatusColor(contract.status);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/contract',
        arguments: {'contractId': contract.id, 'userRole': 'freelancer'},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    project.skills?.take(3).join(' · ') ?? '',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(contract.status),
                    style: TextStyle(
                      fontSize: 9,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _openChatWithClient(
                    project.client?.id ?? 0,
                    project.client?.name ?? 'Client',
                    project.client?.avatar,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 12,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSkills() {
    final skills = [
      {'name': 'Flutter', 'color': Colors.blue},
      {'name': 'React', 'color': Colors.cyan},
      {'name': 'Python', 'color': Colors.green},
      {'name': 'UI/UX', 'color': Colors.purple},
      {'name': 'Node.js', 'color': Colors.orange},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Skills 🔥',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((s) {
              final color = s['color'] as Color;
              final isMySkill = profile?.skills?.contains(s['name']) == true;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isMySkill
                      ? color.withOpacity(0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMySkill
                        ? color.withOpacity(0.4)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  s['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMySkill ? color : Colors.grey.shade700,
                    fontWeight: isMySkill ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    if (loadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppColors.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeaderCard(),
            const SizedBox(height: 16),
            _buildActiveProjectsList(),
            const SizedBox(height: 16),
            _buildTrendingSkills(),
            const SizedBox(height: 16),

            _buildProjectFilterTabs(),
            const SizedBox(height: 12),
            _buildProjectsSection(),

            const SizedBox(height: 20),

            if (portfolioItems.isNotEmpty) ...[
              const Text(
                'My Portfolio 🎨',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...portfolioItems
                  .take(2)
                  .map((item) => PortfolioCard(item: item, onTap: () {})),
              const SizedBox(height: 4),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailsScreen(projectId: project.id!),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.title ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (project.matchScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getMatchScoreColor(
                        project.matchScore!,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${project.matchScore}% Match',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getMatchScoreColor(project.matchScore!),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              project.description ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${project.duration} days',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Remote',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${project.budget?.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightColumn() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _PaymentCard(),
          const SizedBox(height: 14),
          _PremiumCard(
            onSubscribe: () =>
                Navigator.pushNamed(context, '/subscription/plans'),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skill Tests 🏆',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _skillTestRow(Icons.code, 'Programming', Colors.blue),
                _skillTestRow(Icons.design_services, 'Design', Colors.purple),
                _skillTestRow(Icons.trending_up, 'Marketing', Colors.orange),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SkillTestsScreen(),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'View All Tests',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillTestRow(IconData icon, String title, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SkillTestsScreen()),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildHomeTabWithRightPanel();
      case 1:
        return const ProjectsTab();
      case 2:
        return const MyProposalsScreen();
      case 3:
        return const MyProjectsScreen();
      case 4:
        return const MyContractsScreen(userRole: 'freelancer');
      case 5:
        return const FavoritesScreen();
      case 6:
        return const FinancialDashboardScreen();
      case 7:
        return AdvancedSearchScreen();
      case 8:
        return const ChatsListScreen();
      case 9:
        return const SkillTestsScreen();
      default:
        return _buildHomeTabWithRightPanel();
    }
  }

  Widget _buildHomeTabWithRightPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildHomeContent()),
              SizedBox(width: 280, child: _buildRightColumn()),
            ],
          );
        }
        return _buildHomeContent();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final avatarUrl = _getAvatarUrl(profile?.avatar);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: _selectedNavIndex,
            onItemTap: (i) => setState(() => _selectedNavIndex = i),
            profile: profile,
            avatarUrl: avatarUrl,
            onEditProfile: navigateToEditProfile,
          ),

          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
