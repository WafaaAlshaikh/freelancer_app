// screens/client/freelancer_profile_preview_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';

class FreelancerProfilePreviewScreen extends StatefulWidget {
  final int freelancerId;
  final String? projectId;

  const FreelancerProfilePreviewScreen({
    super.key,
    required this.freelancerId,
    this.projectId,
  });

  @override
  State<FreelancerProfilePreviewScreen> createState() =>
      _FreelancerProfilePreviewScreenState();
}

class _FreelancerProfilePreviewScreenState
    extends State<FreelancerProfilePreviewScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _profileData = {};
  bool _loading = true;
  bool _isHiring = false;
  late TabController _tabController;

  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dark = Color(0xFF1F2937);
  static const Color _gray = Color(0xFF6B7280);
  static const Color _lightGray = Color(0xFFF3F4F6);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFreelancerProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFreelancerProfile() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getFreelancerPublicProfile(
        widget.freelancerId,
      );
      if (mounted) {
        setState(() {
          _profileData = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        Fluttertoast.showToast(
          msg: 'Error loading profile: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _startChat() async {
    setState(() => _isHiring = true);
    try {
      final result = await ChatService.createChat(widget.freelancerId);
      if (!mounted) return;

      if (result['success'] == true || result['id'] != null) {
        final chatId = result['chat']?['id'] ?? result['id'];
        final freelancerName = _profileData['user']?['name'] ?? 'Freelancer';
        final freelancerAvatar = _profileData['user']?['avatar'];

        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'chatId': chatId,
            'otherUserId': widget.freelancerId,
            'otherUserName': freelancerName,
            'otherUserAvatar': freelancerAvatar,
          },
        );
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Failed to start chat',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isHiring = false);
    }
  }

  Future<void> _hireFreelancer() async {
    if (widget.projectId == null) {
      Fluttertoast.showToast(
        msg: 'Please select a project first',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isHiring = true);
    try {
      Navigator.pushNamed(
        context,
        '/client/hire-freelancer',
        arguments: {
          'freelancerId': widget.freelancerId,
          'projectId': widget.projectId,
          'freelancerName': _profileData['user']?['name'],
        },
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      if (mounted) setState(() => _isHiring = false);
    }
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    return 'http://localhost:5000$avatar';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} years ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return 'Recently';
  }

  double _getSafeDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  int _getSafeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  Widget _buildHeader() {
    final user = _profileData['user'] ?? {};
    final profile = _profileData['profile'] ?? {};
    final stats = _profileData['stats'] ?? {};
    final name = user['name'] ?? 'Freelancer';
    final title =
        profile['title'] ?? user['tagline'] ?? 'Professional Freelancer';
    final avatarUrl = _getAvatarUrl(user['avatar']);
    final rating = _getSafeDouble(stats['rating']);
    final completedProjects = _getSafeInt(stats['completed_projects']);
    final jobSuccessScore = _getSafeInt(stats['job_success_score']);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: avatarUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.white24,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.white24,
                                child: Center(
                                  child: Text(
                                    _initials(name),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.white24,
                              child: Center(
                                child: Text(
                                  _initials(name),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRatingStar(rating),
                      const SizedBox(width: 8),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.work_outline,
                        size: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$completedProjects projects',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$jobSuccessScore% JSS',
                          style: const TextStyle(
                            color: _success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'Message',
                          onPressed: _startChat,
                          isLoading: _isHiring,
                          outlined: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.work_outline,
                          label: widget.projectId != null
                              ? 'Hire Now'
                              : 'Contact',
                          onPressed: _hireFreelancer,
                          isLoading: _isHiring,
                          outlined: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStar(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index < rating && rating - index > 0.5) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isLoading,
    required bool outlined,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _profileData['stats'] ?? {};
    final profile = _profileData['profile'] ?? {};

    final completedProjects = _getSafeInt(stats['completed_projects']);
    final totalEarnings = _getSafeDouble(stats['total_earnings']);
    final activeProjects = _getSafeInt(stats['active_projects']);
    final responseTime = _getSafeInt(
      profile['response_time'],
      defaultValue: 24,
    );
    final rating = _getSafeDouble(stats['rating']);
    final experienceYears = _getSafeInt(profile['experience_years']);
    final hourlyRate = _getSafeDouble(profile['hourly_rate']);

    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Professional Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  value: '$completedProjects',
                  label: 'Completed',
                  icon: Icons.check_circle_outline,
                  color: _success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  value: '\$${totalEarnings.toStringAsFixed(0)}',
                  label: 'Earnings',
                  icon: Icons.attach_money,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  value: '$activeProjects',
                  label: 'Active',
                  icon: Icons.trending_up,
                  color: _warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: _border),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoRow(
                Icons.access_time,
                'Response Time',
                '$responseTime hours',
              ),
              const Spacer(),
              _buildInfoRow(
                Icons.star,
                'Avg. Rating',
                rating.toStringAsFixed(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoRow(Icons.work, 'Experience', '$experienceYears years'),
              const Spacer(),
              _buildInfoRow(
                Icons.attach_money,
                'Hourly Rate',
                '\$${hourlyRate.toStringAsFixed(0)}/hr',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: _gray)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _gray),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: _gray)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _dark,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final profile = _profileData['profile'] ?? {};
    final List<dynamic> skills = profile['skills'] ?? [];
    final List<dynamic> topSkills = profile['top_skills'] ?? [];

    if (skills.isEmpty && topSkills.isEmpty) {
      return const SizedBox.shrink();
    }

    final displaySkills = topSkills.isNotEmpty ? topSkills : skills;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills & Expertise',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displaySkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  skill.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: _primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final profile = _profileData['profile'] ?? {};
    final bio = profile['bio'] ?? '';
    final location =
        profile['location'] ?? _profileData['user']?['location'] ?? '';

    if (bio.isEmpty && location.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          if (location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: _gray),
                  const SizedBox(width: 6),
                  Text(
                    location,
                    style: const TextStyle(fontSize: 13, color: _dark),
                  ),
                ],
              ),
            ),
          if (bio.isNotEmpty)
            Text(
              bio,
              style: const TextStyle(fontSize: 13, height: 1.5, color: _dark),
            ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection() {
    final portfolio = _profileData['portfolio'] ?? [];
    if (portfolio.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: portfolio.length > 3 ? 3 : portfolio.length,
              itemBuilder: (context, index) {
                final item = portfolio[index];
                final images = item['images'] ?? [];
                final imageUrl = images.isNotEmpty ? images[0] : null;

                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _getAvatarUrl(imageUrl),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: _lightGray,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: _lightGray,
                              child: const Icon(Icons.image, size: 30),
                            ),
                          )
                        : Container(
                            color: _lightGray,
                            child: const Icon(Icons.image, size: 30),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final reviews = _profileData['reviews'] ?? [];
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Client Reviews',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 12),
          ...reviews.take(3).map((review) {
            final rating = _getSafeDouble(review['rating']);
            final createdAt = review['createdAt'] != null
                ? DateTime.tryParse(review['createdAt'])
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: review['from_user']?['avatar'] != null
                            ? NetworkImage(
                                _getAvatarUrl(review['from_user']['avatar']),
                              )
                            : null,
                        child: review['from_user']?['avatar'] == null
                            ? Text(
                                _initials(review['from_user']?['name'] ?? 'U'),
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['from_user']?['name'] ?? 'Client',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            _buildRatingStar(rating),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(fontSize: 11, color: _gray),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review['comment'] ?? '',
                    style: const TextStyle(fontSize: 13, color: _dark),
                  ),
                  const Divider(height: 16),
                ],
              ),
            );
          }),
          if (reviews.length > 3)
            TextButton(onPressed: () {}, child: const Text('View all reviews')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _lightGray,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildStatsSection(),
                const SizedBox(height: 12),
                _buildSkillsSection(),
                const SizedBox(height: 12),
                _buildAboutSection(),
                const SizedBox(height: 12),
                _buildPortfolioSection(),
                const SizedBox(height: 12),
                _buildReviewsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
