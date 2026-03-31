// screens/freelancer/freelancer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freelancer_platform/screens/chat/chats_list_screen.dart';
import 'package:freelancer_platform/screens/contract/my_contracts_screen.dart';
import 'package:freelancer_platform/screens/freelancer/edit_profile_screen.dart';
import 'package:freelancer_platform/screens/notifications/notifications_screen.dart';
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
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: images.length == 1
                    ? CachedNetworkImage(
                        imageUrl: images[0],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, index) => CachedNetworkImage(
                            imageUrl: images[index],
                            width: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 200,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                      ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    item['description'] ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  if (technologies.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: technologies
                          .map(
                            (tech) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tech,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      if (item['project_url'] != null &&
                          item['project_url'].toString().isNotEmpty)
                        _buildLinkButton(
                          icon: Icons.open_in_browser,
                          label: 'Live Demo',
                          url: item['project_url'],
                        ),
                      if (item['github_url'] != null &&
                          item['github_url'].toString().isNotEmpty)
                        const SizedBox(width: 12),
                      if (item['github_url'] != null &&
                          item['github_url'].toString().isNotEmpty)
                        _buildLinkButton(
                          icon: Icons.code,
                          label: 'GitHub',
                          url: item['github_url'],
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

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required String url,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: Open URL
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

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
          final starValue = index + 1;
          double fill;

          if (rating >= starValue) {
            fill = 1;
          } else if (rating > index && rating < starValue) {
            fill = rating - index;
          } else {
            fill = 0;
          }

          return SizedBox(
            width: size,
            height: size,
            child: Icon(
              fill >= 0.5 ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: size,
            ),
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

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});

  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen>
    with SingleTickerProviderStateMixin {
  FreelancerProfile? profile;
  List<Project> recommendedProjects = [];
  List<Project> aiSuggestedProjects = [];
  List<Contract> activeContracts = [];
  Map<String, dynamic>? stats;
  List<Map<String, dynamic>> portfolioItems = [];
  int _unreadNotificationsCount = 0;

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  bool loadingProfile = true;
  bool loadingProjects = true;
  bool loadingSuggestions = true;
  bool loadingContracts = true;
  bool loadingPortfolio = true;

  late TabController tabController;

  final int _unreadMessages = 3;
  Future<void> _loadUnreadNotificationsCount() async {
    try {
      final result = await ApiService.getUnreadCount();
      setState(() {
        _unreadNotificationsCount = result['unreadCount'] ?? 0;
      });
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 6, vsync: this);

    _loadAllData();
    _loadUnreadNotificationsCount();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
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
      Fluttertoast.showToast(msg: "Error loading profile: $e");
    }
  }

  Future<void> fetchRecommendedProjects() async {
    setState(() => loadingProjects = true);
    try {
      final data = await ApiService.getAllProjects();
      setState(() {
        recommendedProjects = data
            .map((json) => Project.fromJson(json))
            .toList();
        recommendedProjects = recommendedProjects.take(5).toList();
        loadingProjects = false;
      });
    } catch (e) {
      setState(() => loadingProjects = false);
      print('Error fetching recommended: $e');
    }
  }

  Future<void> fetchAISuggestions() async {
    setState(() => loadingSuggestions = true);
    try {
      final response = await ApiService.getAISuggestedProjects();
      if (response['success'] == true && response['suggestions'] != null) {
        setState(() {
          aiSuggestedProjects = (response['suggestions'] as List)
              .map((json) => Project.fromJson(json))
              .toList();
          loadingSuggestions = false;
        });
      } else {
        setState(() => loadingSuggestions = false);
      }
    } catch (e) {
      setState(() => loadingSuggestions = false);
      print('Error fetching AI suggestions: $e');
    }
  }

  Future<void> fetchActiveContracts() async {
    setState(() => loadingContracts = true);
    try {
      print('📥 Fetching active contracts for freelancer...');
      final data = await ApiService.getFreelancerContracts();
      print('✅ Contracts fetched: ${data.length}');

      setState(() {
        activeContracts = data
            .map((json) => Contract.fromJson(json))
            .where(
              (contract) =>
                  contract.status == 'active' ||
                  contract.status == 'pending_freelancer' ||
                  contract.status == 'pending_client',
            )
            .toList();
        loadingContracts = false;
      });
    } catch (e) {
      print('❌ Error fetching contracts: $e');
      setState(() {
        activeContracts = [];
        loadingContracts = false;
      });
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await ApiService.getFreelancerStats();
      setState(() {
        stats = response['stats'];
      });
    } catch (e) {
      print('Error fetching stats: $e');
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
      print('Error fetching portfolio: $e');
      setState(() => loadingPortfolio = false);
    }
  }

  void navigateToEditProfile() async {
    if (profile == null) {
      print('Profile is null, cannot navigate');
      Fluttertoast.showToast(msg: "Loading profile...");
      return;
    }

    print('Navigating to EditProfileScreen with profile: ${profile?.name}');

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
      Fluttertoast.showToast(
        msg:
            "Cannot start chat: Client information is not available for this project.",
        backgroundColor: Colors.orange,
      );
      print('❌ Invalid client ID: $clientId');
      return;
    }
    if (clientId == null || clientId == 0) {
      Fluttertoast.showToast(msg: "Cannot start chat: Client ID is missing");
      print('❌ Invalid client ID: $clientId');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('📱 Opening chat with client ID: $clientId');

      final result = await ChatService.createChat(clientId);

      if (mounted) Navigator.pop(context);

      int? chatId;
      if (result['success'] == true) {
        chatId = result['chat']?['id'];
      } else {
        chatId = result['id'];
      }

      if (chatId == null || chatId == 0) {
        Fluttertoast.showToast(msg: "Failed to create chat. Please try again.");
        return;
      }

      if (mounted) {
        print('✅ Navigating to chat with ID: $chatId, other user: $clientId');

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
      print('❌ Error opening chat: $e');
      Fluttertoast.showToast(msg: "Error opening chat: ${e.toString()}");
    }
  }

  double get profileCompletion {
    int completed = 0;
    int total = 9;

    if (profile?.name != null && profile!.name!.isNotEmpty) completed++;
    if (profile?.title != null && profile!.title!.isNotEmpty) completed++;
    if (profile?.bio != null && profile!.bio!.isNotEmpty) completed++;
    if (profile?.avatar != null && profile!.avatar!.isNotEmpty) completed++;
    if (profile?.skills != null && profile!.skills!.isNotEmpty) completed++;
    if (profile?.cvUrl != null && profile!.cvUrl!.isNotEmpty) completed++;
    if (portfolioItems.isNotEmpty) completed++;
    if (profile?.hourlyRate != null && profile!.hourlyRate! > 0) completed++;
    if (profile?.location != null && profile!.location!.isNotEmpty) completed++;

    return total > 0 ? (completed / total * 100) : 0;
  }

  String _getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    return 'http://localhost:5000$avatar';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day} ${now.year}';
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Logout"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _getDaysRemaining(Contract contract) {
    if (contract.milestones == null || contract.milestones!.isEmpty) {
      return 'No deadline';
    }

    final milestones = contract.milestones!;
    final futureMilestones = milestones
        .where((m) => m['status'] != 'completed' && m['due_date'] != null)
        .toList();

    if (futureMilestones.isEmpty) return 'Finalizing';

    try {
      final nextDue = DateTime.parse(futureMilestones.first['due_date']);
      final days = nextDue.difference(DateTime.now()).inDays;

      if (days < 0) return 'Overdue';
      if (days == 0) return 'Due today';
      return '$days days left';
    } catch (e) {
      return 'No deadline';
    }
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final totalProposals = stats?['totalProposals'] ?? 0;
    final acceptedProposals = stats?['acceptedProposals'] ?? 0;
    final jobSuccessScore = totalProposals > 0
        ? (acceptedProposals / totalProposals * 100).toInt()
        : 0;

    final totalEarnings = stats?['totalEarnings'] ?? 12500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                Icons.work,
                stats?['activeProjects']?.toString() ?? "0",
                "Active",
                Colors.blue,
              ),
              _statItem(
                Icons.send,
                stats?['totalProposals']?.toString() ?? "0",
                "Proposals",
                Colors.orange,
              ),
              _statItem(
                Icons.star,
                profile?.rating?.toStringAsFixed(1) ?? "0.0",
                "Rating",
                Colors.amber,
              ),
              _statItem(
                Icons.trending_up,
                "$jobSuccessScore%",
                "JSS",
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                Icons.attach_money,
                "\$${totalEarnings}",
                "Earnings",
                Colors.green,
              ),
              _statItem(Icons.access_time, "2h", "Response", Colors.orange),
              _statItem(
                Icons.percent,
                "${profileCompletion.toStringAsFixed(0)}%",
                "Profile",
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    if (profile == null) return const SizedBox.shrink();

    double completion = profileCompletion;
    if (completion >= 100) return const SizedBox.shrink();

    List<String> missingItems = [];
    if (profile?.name == null || profile!.name!.isEmpty)
      missingItems.add("Full Name");
    if (profile?.title == null || profile!.title!.isEmpty)
      missingItems.add("Title");
    if (profile?.bio == null || profile!.bio!.isEmpty) missingItems.add("Bio");
    if (profile?.avatar == null || profile!.avatar!.isEmpty)
      missingItems.add("Profile Photo");
    if (profile?.skills == null || profile!.skills!.isEmpty)
      missingItems.add("Skills");
    if (profile?.cvUrl == null || profile!.cvUrl!.isEmpty)
      missingItems.add("CV");
    if (portfolioItems.isEmpty) missingItems.add("Portfolio Items");
    if (profile?.hourlyRate == null || profile!.hourlyRate! <= 0)
      missingItems.add("Hourly Rate");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Complete your profile to get better project matches",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completion / 100,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Completion: ${completion.toStringAsFixed(0)}%",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              TextButton(
                onPressed: navigateToEditProfile,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: Text(
                  "Complete Now",
                  style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                ),
              ),
            ],
          ),
          if (missingItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list, color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Missing: ${missingItems.take(3).join(", ")}${missingItems.length > 3 ? " +${missingItems.length - 3}" : ""}",
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveProjects() {
    if (loadingContracts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (activeContracts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Active Projects 🔥",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: fetchActiveContracts,
                ),
                TextButton(
                  onPressed: () => tabController.animateTo(3),
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Color(0xff14A800)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activeContracts.length,
            itemBuilder: (context, index) {
              final contract = activeContracts[index];
              return _buildActiveProjectCard(contract);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveProjectCard(Contract contract) {
    final project = contract.project;
    if (project == null) return const SizedBox.shrink();

    double progress = 0;
    if (contract.milestones != null && contract.milestones!.isNotEmpty) {
      final completed = contract.milestones!
          .where((m) => m['status'] == 'completed')
          .length;
      progress = completed / contract.milestones!.length;
    } else {
      progress = contract.status == 'active' ? 0.5 : 0.2;
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/contract',
          arguments: {'contractId': contract.id, 'userRole': 'freelancer'},
        );
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.title ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _openChatWithClient(
                      project.client?.id ?? 0,
                      project.client?.name ?? 'Client',
                      project.client?.avatar,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xff14A800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: Color(0xff14A800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              project.client?.name ?? 'Client',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(contract.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusText(contract.status),
                style: TextStyle(
                  fontSize: 9,
                  color: _getStatusColor(contract.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${project.budget?.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  "${project.duration} days",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Progress: ${(progress * 100).toInt()}%",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                if (contract.status == 'active')
                  Text(
                    _getDaysRemaining(contract),
                    style: const TextStyle(fontSize: 9, color: Colors.green),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                contract.status == 'active' ? Colors.green : Colors.orange,
              ),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending_freelancer':
      case 'pending_client':
        return Colors.orange;
      case 'draft':
        return Colors.blue;
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
      case 'draft':
        return 'Draft';
      case 'completed':
        return 'Completed';
      default:
        return status ?? 'Unknown';
    }
  }

  Widget _buildAISuggestions() {
    if (loadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (aiSuggestedProjects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              "AI Recommended For You 🤖",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...aiSuggestedProjects
            .take(3)
            .map((project) => _buildProjectCard(project)),
      ],
    );
  }

  Widget _buildRecommendedProjects() {
    if (loadingProjects) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recommendedProjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.work_off, size: 50, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Text(
                "No projects available",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                "Check back later or create your first project",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recommendedProjects
          .map((project) => _buildProjectCard(project))
          .toList(),
    );
  }

  Widget _buildPortfolioSection() {
    if (loadingPortfolio) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (portfolioItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.work_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              "No portfolio items yet",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              "Showcase your work to attract more clients",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: navigateToEditProfile,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add Your First Project"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff14A800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.work, color: Color(0xff14A800), size: 20),
            SizedBox(width: 8),
            Text(
              "My Portfolio 🎨",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...portfolioItems
            .take(2)
            .map(
              (item) => PortfolioCard(
                item: item,
                onTap: () {
                  // TODO: Show portfolio detail dialog
                },
              ),
            ),
        if (portfolioItems.length > 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton(
              onPressed: () {
                // TODO: Navigate to full portfolio screen
              },
              child: Text(
                "View all ${portfolioItems.length} projects →",
                style: const TextStyle(color: Color(0xff14A800)),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: navigateToEditProfile,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add New Project"),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Project project) {
    final hasValidClient =
        project.client != null &&
        project.client!.id != null &&
        project.client!.id! > 0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailsScreen(projectId: project.id!),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.title ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (project.matchScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getMatchScoreColor(
                        project.matchScore!,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: _getMatchScoreColor(project.matchScore!),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${project.matchScore}% Match',
                          style: TextStyle(
                            fontSize: 10,
                            color: _getMatchScoreColor(project.matchScore!),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: project.client?.avatar != null
                      ? NetworkImage(_getAvatarUrl(project.client!.avatar))
                      : null,
                  child: project.client?.avatar == null
                      ? Text(
                          project.client?.name?[0].toUpperCase() ?? 'C',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    project.client?.name ?? 'Unknown Client',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _openChatWithClient(
                      project.client?.id ?? 0,
                      project.client?.name ?? 'Client',
                      project.client?.avatar,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xff14A800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: const Color(0xff14A800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  _formatDate(project.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              project.description ?? 'No description',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            if (project.skills != null && project.skills!.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.skills!.take(3).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${project.duration} days',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
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
                    fontSize: 16,
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

  Widget _buildMessageCard(
    String sender,
    String content,
    String time, {
    bool isUnread = false,
    String? avatar,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blueGrey.shade300,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        sender.isNotEmpty ? sender[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              if (isUnread)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: isUnread ? Colors.black87 : Colors.black54,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xff14A800),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMatchScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.blue;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildHomeTab() {
    if (loadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      displacement: 40,
      color: const Color(0xff14A800),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.purple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back, ${profile?.name?.split(' ')[0] ?? 'Freelancer'}! 👋",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.title ?? "Let's find your next project",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildProfileCompletionCard(),
            _buildQuickStats(),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search for projects...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () => tabController.animateTo(1),
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (query) {
                  tabController.animateTo(1);
                },
              ),
            ),

            const SizedBox(height: 20),

            _buildActiveProjects(),
            const SizedBox(height: 20),
            _buildPortfolioSection(),
            const SizedBox(height: 16),
            _buildAISuggestions(),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recommended for You 🎯",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => tabController.animateTo(1),
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Color(0xff14A800)),
                  ),
                ),
              ],
            ),

            _buildRecommendedProjects(),

            const SizedBox(height: 24),

            _buildReminders(),
            const SizedBox(height: 16),
            _buildTrendingSkills(),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Messages 💬",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => tabController.animateTo(5),
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Color(0xff14A800)),
                  ),
                ),
              ],
            ),

            _buildMessageCard(
              "Ahmed",
              "Hi! Are you available for a quick chat?",
              "2h",
              isUnread: true,
              avatar: null,
            ),
            _buildMessageCard(
              "Sara",
              "I reviewed your proposal, let's discuss",
              "5h",
              isUnread: false,
              avatar: null,
            ),
            _buildMessageCard(
              "Mohammed",
              "Great work on the project!",
              "1d",
              isUnread: false,
              avatar: null,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReminders() {
    List<Map<String, dynamic>> reminders = [];

    for (var contract in activeContracts) {
      if (contract.milestones != null) {
        for (var milestone in contract.milestones!) {
          if (milestone['status'] != 'completed' &&
              milestone['due_date'] != null) {
            try {
              final dueDate = DateTime.parse(milestone['due_date']);
              final daysLeft = dueDate.difference(DateTime.now()).inDays;

              if (daysLeft <= 3 && daysLeft >= 0) {
                reminders.add({
                  'title': milestone['title'],
                  'date': daysLeft == 0 ? 'Today' : 'In $daysLeft days',
                  'type': 'deadline',
                  'priority': daysLeft == 0 ? 'high' : 'medium',
                  'contractId': contract.id,
                });
              }
            } catch (e) {}
          }
        }
      }
    }

    if (profileCompletion < 80) {
      reminders.insert(0, {
        'title': 'Complete your profile',
        'date': 'Recommended',
        'type': 'task',
        'priority': 'high',
      });
    }

    if (reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    reminders = reminders.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                "Reminders 📅",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reminders.map((reminder) => _buildReminderItem(reminder)).toList(),
        ],
      ),
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> reminder) {
    Color color;
    IconData icon;

    switch (reminder['type']) {
      case 'deadline':
        color = Colors.red;
        icon = Icons.access_time;
        break;
      default:
        color = Colors.grey;
        icon = Icons.task;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder['date'],
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: reminder['priority'] == 'high'
                  ? Colors.red.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              reminder['priority'] == 'high' ? 'Urgent' : 'Normal',
              style: TextStyle(
                fontSize: 10,
                color: reminder['priority'] == 'high'
                    ? Colors.red
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSkills() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Trending Skills 🔥",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _skillChip("Flutter", "150+", Colors.blue),
                const SizedBox(width: 8),
                _skillChip("React", "120+", Colors.cyan),
                const SizedBox(width: 8),
                _skillChip("Python", "90+", Colors.green),
                const SizedBox(width: 8),
                _skillChip("UI/UX", "80+", Colors.purple),
                const SizedBox(width: 8),
                _skillChip("Node.js", "70+", Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillChip(String skill, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(count, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text("Freelancer Dashboard")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final avatarUrl = _getAvatarUrl(profile?.avatar);

    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: navigateToEditProfile,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade400,
              backgroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      profile?.name?.isNotEmpty == true
                          ? profile!.name![0].toUpperCase()
                          : "F",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello ${profile?.name?.split(' ')[0] ?? 'Freelancer'}! 👋",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              _getCurrentDate(),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          indicatorColor: const Color(0xff14A800),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Home"),
            Tab(text: "Find Work"),
            Tab(text: "My Proposals"),
            Tab(text: "My Projects"),
            Tab(text: "Contracts"),
            Tab(text: "Messages"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => tabController.animateTo(1),
          ),

          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (_unreadMessages > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xff14A800),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadMessages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatsListScreen()),
              );
            },
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
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationsCount > 99
                          ? '99+'
                          : '$_unreadNotificationsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
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
                  "${dotenv.env['FRONTEND_URL']}/freelancer/${profile?.id}";
              await Share.share("Check out my profile: $shareUrl");
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              bool confirm = await _showLogoutDialog();
              if (confirm) {
                await ApiService.logout();
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, "/login");
                }
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _buildHomeTab(),
          const ProjectsTab(),
          const MyProposalsScreen(),
          const MyProjectsScreen(),
          const MyContractsScreen(userRole: 'freelancer'),
          const Center(
            child: Text(
              "Messages Tab - Coming Soon",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
