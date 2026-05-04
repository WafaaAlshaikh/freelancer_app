import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freelancer_platform/screens/client/client_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/profile_api_service.dart';
import '../../services/api_service.dart';
import '../../models/client_profile.dart';

class EnhancedClientProfileScreen extends StatefulWidget {
  final int? targetUserId;
  const EnhancedClientProfileScreen({super.key, this.targetUserId});

  @override
  State<EnhancedClientProfileScreen> createState() =>
      _EnhancedClientProfileScreenState();
}

class _EnhancedClientProfileScreenState
    extends State<EnhancedClientProfileScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _isOwnProfile = false;
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;

  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _secondary = Color(0xFF10B981);
  static const Color _accent = Color(0xFFF59E0B);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dark = Color(0xFF1F2937);
  static const Color _gray = Color(0xFF6B7280);
  static const Color _light = Color(0xFFF9FAFB);
  static const Color _white = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _load();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showAppBarTitle) {
      setState(() => _showAppBarTitle = true);
    } else if (_scrollController.offset <= 200 && _showAppBarTitle) {
      setState(() => _showAppBarTitle = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = widget.targetUserId;
    final ownIdStr = await _getOwnUserId();
    _isOwnProfile = userId == null || userId.toString() == ownIdStr;

    Map<String, dynamic> data;
    if (_isOwnProfile) {
      data = await ProfileApiService.getMyClientProfile();
    } else {
      data = await ProfileApiService.getClientPublicProfile(userId!);
    }

    if (mounted)
      setState(() {
        _data = data;
        _loading = false;
      });
  }

  Future<String?> _getOwnUserId() async {
    try {
      final profile = await ApiService.getProfile();
      return profile['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  String _img(String? p) => ProfileApiService.fullImageUrl(p);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _light,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primary, _primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: _white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Profile...',
                style: TextStyle(
                  fontSize: 16,
                  color: _gray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = Map<String, dynamic>.from(_data['user'] ?? {});
    final profile = Map<String, dynamic>.from(_data['profile'] ?? {});
    final stats = Map<String, dynamic>.from(_data['stats'] ?? {});
    final jobs = List<Map<String, dynamic>>.from(
      (_data['jobs'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );
    final reviews = List<Map<String, dynamic>>.from(
      (_data['reviews'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );

    final name = user['name'] ?? 'Client';
    final companyName = profile['company_name'] ?? '';
    final title = profile['tagline'] ?? user['tagline'] ?? '';
    final bio = profile['bio'] ?? user['bio'] ?? '';
    final location = user['location'] ?? profile['location'] ?? '';
    final industry = profile['industry'] ?? '';
    final companySize = profile['company_size'] ?? '';
    final website = profile['company_website'] ?? '';
    final foundedYear = profile['founded_year'];
    final badges = List.from(profile['badges'] ?? []);

    final totalSpent = (profile['total_spent'] ?? 0) as num;
    final totalProjects = (profile['total_projects'] ?? 0) as num;
    final activeContracts = (profile['active_contracts'] ?? 0) as num;
    final completedContracts = (profile['completed_contracts'] ?? 0) as num;
    final clientRating = (profile['client_rating'] ?? 0) as num;
    final totalReviewsReceived =
        (profile['total_reviews_received'] ?? 0) as num;
    final hireRate = (profile['hire_rate'] ?? 0) as num;
    final avgProjectBudget = (profile['avg_project_budget'] ?? 0) as num;

    final isPaymentVerified = profile['payment_verified'] ?? false;
    final isIdVerified = profile['id_verified'] ?? false;
    final isCompanyVerified = profile['company_verified'] ?? false;
    final isTopClient = profile['is_top_client'] ?? false;

    return Scaffold(
      backgroundColor: _light,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: _dark, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isOwnProfile) ...[
                _buildActionButton(Icons.edit, 'Edit', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditClientProfileScreen(),
                    ),
                  ).then((_) => _load());
                }),
                _buildActionButton(Icons.share, 'Share', () {}),
              ] else ...[
                _buildActionButton(Icons.message, 'Message', () {}),
                _buildActionButton(Icons.more_vert, 'More', () {}),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: _showAppBarTitle
                  ? Text(
                      companyName.isNotEmpty ? companyName : name,
                      style: TextStyle(
                        color: _dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  user['cover_image'] != null &&
                          user['cover_image'].toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _img(user['cover_image']),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primary, _secondary, _accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _buildQuickStats(
                      totalSpent.toDouble(),
                      totalProjects.toInt(),
                      completedContracts.toInt(),
                      hireRate.toInt(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _buildProfileHeader(
                    user,
                    profile,
                    name,
                    companyName,
                    title,
                    bio,
                    location,
                    industry,
                    isPaymentVerified,
                    isIdVerified,
                    isCompanyVerified,
                  ),
                ),

                const SizedBox(height: 24),

                if (badges.isNotEmpty || isTopClient)
                  _buildBadgesSection(badges, isTopClient),

                const SizedBox(height: 24),

                _buildCompanySection(companySize, foundedYear, website),

                const SizedBox(height: 24),

                _buildHiringStats(profile, stats),

                const SizedBox(height: 24),

                _buildTabsSection(),
              ],
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(profile, user),
                _buildJobsTab(jobs),
                _buildReviewsTab(
                  reviews,
                  clientRating.toDouble(),
                  totalReviewsReceived.toInt(),
                ),
                _buildAnalyticsTab(profile, stats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getClientTypeIcon() {
    final clientType = _data['profile']?['client_type'] ?? 'individual';
    return clientType == 'company' ? '🏢' : '👤';
  }

  String _getClientTypeText() {
    final clientType = _data['profile']?['client_type'] ?? 'individual';
    return clientType == 'company' ? 'Verified Business' : 'Individual Client';
  }

  Widget _buildClientTypeBadge() {
    final clientType = _data['profile']?['client_type'] ?? 'individual';
    final isCompany = clientType == 'company';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompany
              ? [_success, _success.withOpacity(0.8)]
              : [_primary, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompany ? Icons.business : Icons.person,
            size: 14,
            color: _white,
          ),
          const SizedBox(width: 6),
          Text(
            _getClientTypeText(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: _dark, size: 18),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildQuickStats(
    double totalSpent,
    int totalProjects,
    int completedContracts,
    int hireRate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat(
            '\$',
            '\$${totalSpent.toStringAsFixed(0)}',
            'Total Spent',
          ),
          _buildQuickStat('📋', totalProjects.toString(), 'Projects'),
          _buildQuickStat('✅', completedContracts.toString(), 'Completed'),
          if (hireRate > 0) _buildQuickStat('🎯', '$hireRate%', 'Hire Rate'),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: _white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    Map user,
    Map profile,
    String name,
    String companyName,
    String title,
    String bio,
    String location,
    String industry,
    bool isPaymentVerified,
    bool isIdVerified,
    bool isCompanyVerified,
  ) {
    final companySize = profile['company_size'] ?? '';
    final foundedYear = profile['founded_year'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_primary, _primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: _white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          profile['company_logo'] != null &&
                              profile['company_logo'].toString().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _img(profile['company_logo']),
                              fit: BoxFit.cover,
                            )
                          : user['avatar'] != null &&
                                user['avatar'].toString().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _img(user['avatar']),
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                (companyName.isNotEmpty ? companyName : name)
                                        .isNotEmpty
                                    ? (companyName.isNotEmpty
                                              ? companyName
                                              : name)[0]
                                          .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: _white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (isPaymentVerified || isIdVerified || isCompanyVerified)
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCompanyVerified)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _success,
                                shape: BoxShape.circle,
                                border: Border.all(color: _white, width: 2),
                              ),
                              child: const Icon(
                                Icons.business,
                                color: _white,
                                size: 14,
                              ),
                            ),
                          if (isPaymentVerified)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: _white, width: 2),
                              ),
                              child: const Icon(
                                Icons.payment,
                                color: _white,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            companyName.isNotEmpty ? companyName : name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _dark,
                            ),
                          ),
                        ),
                        if (companyName.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildClientTypeBadge(),
                        ],
                        if (!_isOwnProfile)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primary, _primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.handshake,
                                color: _white,
                                size: 16,
                              ),
                              label: const Text(
                                'Hire',
                                style: TextStyle(color: _white),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (title.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            color: _gray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (industry.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          industry,
                          style: TextStyle(fontSize: 14, color: _gray),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (location.isNotEmpty)
                          _buildHeaderIcon(
                            Icons.location_on_outlined,
                            location,
                          ),
                        if (companySize.isNotEmpty)
                          _buildHeaderIcon(Icons.people_outline, companySize),
                        if (foundedYear != null)
                          _buildHeaderIcon(
                            Icons.calendar_today,
                            'Since $foundedYear',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_isOwnProfile) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: _primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.message_outlined, color: _primary),
                      label: const Text(
                        'Message',
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primary, _primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border, color: _white),
                      label: const Text(
                        'Follow',
                        style: TextStyle(
                          color: _white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _gray),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: _gray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(List badges, bool isTopClient) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (isTopClient) _buildBadge('Top Client', Icons.star, _warning),
              ...badges.map(
                (badge) => _buildBadge(
                  badge['name'] ?? 'Badge',
                  Icons.emoji_events,
                  _primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySection(
    String companySize,
    int? foundedYear,
    String website,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Company Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Company Size',
                  companySize.isNotEmpty ? companySize : 'Not specified',
                  Icons.people,
                  _primary,
                ),
              ),
              if (foundedYear != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Founded',
                    foundedYear.toString(),
                    Icons.calendar_today,
                    _secondary,
                  ),
                ),
              ],
            ],
          ),
          if (website.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.language, color: _primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      website,
                      style: TextStyle(
                        fontSize: 14,
                        color: _primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => launchUrl(Uri.parse('https://$website')),
                    icon: Icon(Icons.open_in_new, color: _primary, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _gray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiringStats(Map profile, Map stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hiring Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Budget',
                  '\$${(profile['avg_project_budget'] ?? 0).toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  _success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Active Contracts',
                  '${profile['active_contracts'] ?? 0}',
                  Icons.assignment,
                  _warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Client Rating',
                  '${(profile['client_rating'] ?? 0).toStringAsFixed(1)}',
                  Icons.star,
                  _accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Repeat Hire Rate',
                  '${(profile['repeat_hire_rate'] ?? 0).toStringAsFixed(0)}%',
                  Icons.repeat,
                  _primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _gray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _primary,
        unselectedLabelColor: _gray,
        indicatorColor: _primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Jobs'),
          Tab(text: 'Reviews'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map profile, Map user) {
    final bio = profile['bio'] ?? user['bio'] ?? '';
    final preferredSkills = List<String>.from(
      profile['preferred_skills'] ?? [],
    );
    final hiringFor = List<String>.from(profile['hiring_for'] ?? []);
    final communicationMethods = List<String>.from(
      profile['preferred_communication_methods'] ?? [],
    );
    final projectTools = List<String>.from(
      profile['project_management_tools'] ?? [],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (bio.isNotEmpty) ...[
            _buildSectionCard('About Company', Icons.business, [
              Text(
                bio,
                style: TextStyle(fontSize: 15, color: _gray, height: 1.5),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          if (preferredSkills.isNotEmpty) ...[
            _buildSectionCard('Preferred Skills', Icons.psychology, [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: preferredSkills
                    .map((skill) => _buildSkillChip(skill))
                    .toList(),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          if (hiringFor.isNotEmpty) ...[
            _buildSectionCard('Currently Hiring For', Icons.person_search, [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: hiringFor
                    .map((role) => _buildSkillChip(role))
                    .toList(),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          if (communicationMethods.isNotEmpty) ...[
            _buildSectionCard('Communication Methods', Icons.chat, [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: communicationMethods
                    .map((method) => _buildSkillChip(method))
                    .toList(),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          if (projectTools.isNotEmpty) ...[
            _buildSectionCard('Project Management Tools', Icons.settings, [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: projectTools
                    .map((tool) => _buildSkillChip(tool))
                    .toList(),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.1), _primaryDark.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.3)),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontSize: 14,
          color: _primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildJobsTab(List jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: _gray),
            const SizedBox(height: 16),
            Text(
              'No active jobs',
              style: TextStyle(
                fontSize: 18,
                color: _gray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isOwnProfile
                  ? 'Post a job to start hiring freelancers'
                  : 'This client hasn\'t posted any jobs yet',
              style: TextStyle(fontSize: 14, color: _gray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildJobCard(Map job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
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
                  job['title'] ?? 'Job Title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  job['status'] ?? 'Active',
                  style: TextStyle(
                    fontSize: 12,
                    color: _success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job['description'] ?? '',
            style: TextStyle(fontSize: 14, color: _gray, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.attach_money, color: _primary, size: 16),
              const SizedBox(width: 4),
              Text(
                '\$${job['budget'] ?? '0'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule, color: _gray, size: 16),
              const SizedBox(width: 4),
              Text(
                job['duration'] ?? 'Not specified',
                style: TextStyle(fontSize: 14, color: _gray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(List reviews, double avg, int total) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (total > 0) ...[
            _buildRatingOverview(avg, total),
            const SizedBox(height: 20),
          ],
          if (reviews.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.star_outline, size: 64, color: _gray),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: _gray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reviews from freelancers will appear here',
                    style: TextStyle(fontSize: 14, color: _gray),
                  ),
                ],
              ),
            )
          else
            ...reviews.map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildReviewCard(review),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingOverview(double avg, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.05), _primaryDark.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < avg.floor() ? Icons.star : Icons.star_border,
                        color: _accent,
                        size: 20,
                      );
                    }),
                  ),
                  Text(
                    '$total reviews',
                    style: TextStyle(fontSize: 14, color: _gray),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map review) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primary, _primaryDark]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    (review['freelancer_name'] ?? 'F')[0].toUpperCase(),
                    style: const TextStyle(
                      color: _white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['freelancer_name'] ?? 'Freelancer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (review['rating'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: _accent,
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          review['created_at'] ?? '',
                          style: TextStyle(fontSize: 12, color: _gray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review['comment'] ?? '',
            style: TextStyle(fontSize: 14, color: _gray, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(Map profile, Map stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAnalyticsCard(
            'Profile Views',
            profile['profile_views'] ?? 0,
            Icons.visibility,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            'Jobs Posted',
            profile['jobs_posted'] ?? 0,
            Icons.work,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            'Invitations Sent',
            profile['invitations_sent'] ?? 0,
            Icons.email,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            'Applications Received',
            profile['applications_received'] ?? 0,
            Icons.inbox,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  ),
                ),
                Text(title, style: TextStyle(fontSize: 14, color: _gray)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
