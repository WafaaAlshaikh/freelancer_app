import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/screens/chat/chat_screen.dart';
import 'package:freelancer_platform/services/chat_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'compare_freelancers_screen.dart';
import 'freelancer_profile_preview_screen.dart';
import 'hire_freelancer_dialog.dart';
import '../chat/chats_list_screen.dart';

class FindFreelancersScreen extends StatefulWidget {
  const FindFreelancersScreen({super.key});

  @override
  State<FindFreelancersScreen> createState() => _FindFreelancersScreenState();
}

class _FindFreelancersScreenState extends State<FindFreelancersScreen> {
  List<FreelancerSearchItem> _freelancers = [];
  List<int> _selectedForComparison = [];
  bool _loading = true;
  bool _isGridView = false;

  String _searchQuery = '';
  String _selectedSkill = '';
  double _minRating = 0;
  double _maxHourlyRate = 200;
  int _minExperience = 0;
  String _sortBy = 'rating';

  List<String> _allSkills = [];

  @override
  void initState() {
    super.initState();
    _loadFreelancers();
  }

  Future<void> _loadFreelancers() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.searchFreelancers(
        query: _searchQuery,
        skill: _selectedSkill,
        minRating: _minRating,
        maxHourlyRate: _maxHourlyRate,
        minExperience: _minExperience,
        sortBy: _sortBy,
      );

      if (mounted) {
        final List freelancersList = result['freelancers'] ?? [];

        setState(() {
          _freelancers = freelancersList
              .map((j) => FreelancerSearchItem.fromJson(j))
              .toList();
          _allSkills = _extractAllSkills(_freelancers);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading freelancers: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _extractAllSkills(List<FreelancerSearchItem> list) {
    final skills = <String>{};
    for (final f in list) {
      skills.addAll(f.skills);
    }
    return skills.toList();
  }

  void _navigateToCompare() {
    if (_selectedForComparison.length >= 2) {
      _getOpenProjectId().then((projectId) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompareFreelancersScreen(
                projectId: projectId,
                freelancerIds: _selectedForComparison,
              ),
            ),
          ).then((_) => _loadFreelancers());
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.selectAtLeastTwoFreelancers,
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<int> _getOpenProjectId() async {
    try {
      final result = await ApiService.getOpenProjectsForHiring();
      if (result['success'] == true &&
          result['projects'] != null &&
          result['projects'].isNotEmpty) {
        return result['projects'][0]['id'] as int;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void _viewProfile(int freelancerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FreelancerProfilePreviewScreen(
          freelancerId: freelancerId,
          projectId: null,
        ),
      ),
    );
  }

  void _showHireDialog(FreelancerSearchItem freelancer) {
    showDialog(
      context: context,
      builder: (context) => HireFreelancerDialog(
        freelancerId: freelancer.id,
        freelancerName: freelancer.name,
        onSuccess: () {
          _loadFreelancers();
        },
      ),
    );
  }

  void _showHireOptions(FreelancerSearchItem freelancer) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkTextHint : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.hireFreelancer,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              freelancer.name,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.send, color: AppColors.accent),
              ),
              title: Text(
                t.sendOffer,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                t.sendCustomOfferToFreelancer,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showHireDialog(freelancer);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat, color: AppColors.info),
              ),
              title: Text(
                t.sendMessage,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                t.discussBeforeHiring,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _startChat(freelancer.id, freelancer.name, freelancer.avatar);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _startChat(
    int freelancerId,
    String freelancerName,
    String? freelancerAvatar,
  ) async {
    try {
      final chatResult = await ChatService.getOrCreateChat(freelancerId);

      int chatId;
      if (chatResult['success'] == true && chatResult['chatId'] != null) {
        chatId = chatResult['chatId'] as int;
      } else {
        chatId = 0;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: freelancerId,
              otherUserName: freelancerName,
              otherUserAvatar: freelancerAvatar,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting chat: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start chat: $e')));
    }
  }

  bool _isDarkMode() {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          _buildActiveFilters(),
          _buildResultsHeader(t),
          Expanded(
            child: _loading
                ? _buildLoadingState()
                : _freelancers.isEmpty
                ? _buildEmptyState(t)
                : _isGridView
                ? _buildGridView()
                : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: _selectedForComparison.length >= 2
          ? FloatingActionButton.extended(
              onPressed: _navigateToCompare,
              icon: const Icon(Icons.compare_arrows),
              label: Text('${t.compare} (${_selectedForComparison.length})'),
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) {
                _searchQuery = v;
                _loadFreelancers();
              },
              decoration: InputDecoration(
                hintText: t.searchFreelancers,
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkCard
                    : AppColors.lightBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _showFilterDialog(),
            icon: const Icon(Icons.filter_list),
            color: AppColors.accent,
          ),
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final t = AppLocalizations.of(context)!;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip(t.sortBy, _getSortLabel(), () => _showSortDialog()),
          _buildChip(t.rating, '${_minRating}+', () => _showRatingDialog()),
          _buildChip(
            t.hourlyRate,
            '\$${_maxHourlyRate.toInt()}+',
            () => _showPriceDialog(),
          ),
          _buildChip(
            t.experience,
            '${_minExperience}+ ${t.years}',
            () => _showExperienceDialog(),
          ),
          if (_selectedSkill.isNotEmpty)
            _buildChip(
              t.skill,
              _selectedSkill,
              () => setState(() {
                _selectedSkill = '';
                _loadFreelancers();
              }),
            ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'rating':
        return 'Rating';
      case 'hourlyRate_asc':
        return 'Price: Low to High';
      case 'hourlyRate_desc':
        return 'Price: High to Low';
      case 'experience_desc':
        return 'Experience';
      default:
        return 'Rating';
    }
  }

  Widget _buildChip(String label, String value, VoidCallback onTap) {
    final isDark = _isDarkMode();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label: $value'),
        onSelected: (_) => onTap(),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        selectedColor: AppColors.accent.withOpacity(0.2),
        checkmarkColor: AppColors.accent,
      ),
    );
  }

  Widget _buildActiveFilters() {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();

    if (_searchQuery.isEmpty &&
        _selectedSkill.isEmpty &&
        _minRating <= 0 &&
        _minExperience <= 0 &&
        _maxHourlyRate >= 200) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              '${t.activeFilters}:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
              ),
            ),
            const SizedBox(width: 8),
            if (_searchQuery.isNotEmpty)
              _buildFilterChipActive(t.search, _searchQuery, () {
                setState(() => _searchQuery = '');
                _loadFreelancers();
              }),
            if (_selectedSkill.isNotEmpty)
              _buildFilterChipActive(t.skill, _selectedSkill, () {
                setState(() => _selectedSkill = '');
                _loadFreelancers();
              }),
            if (_minRating > 0)
              _buildFilterChipActive(t.rating, '${_minRating}+', () {
                setState(() => _minRating = 0);
                _loadFreelancers();
              }),
            if (_minExperience > 0)
              _buildFilterChipActive(
                t.experience,
                '${_minExperience}+ ${t.years}',
                () {
                  setState(() => _minExperience = 0);
                  _loadFreelancers();
                },
              ),
            if (_maxHourlyRate < 200)
              _buildFilterChipActive(
                t.hourlyRate,
                '\$${_maxHourlyRate.toInt()}+',
                () {
                  setState(() => _maxHourlyRate = 200);
                  _loadFreelancers();
                },
              ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedSkill = '';
                  _minRating = 0;
                  _minExperience = 0;
                  _maxHourlyRate = 200;
                  _sortBy = 'rating';
                });
                _loadFreelancers();
              },
              child: Text(t.clearAll, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipActive(
    String label,
    String value,
    VoidCallback onRemove,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: $value', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(t) {
    final isDark = _isDarkMode();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_freelancers.length} ${t.freelancersFound}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
          if (_selectedForComparison.isNotEmpty)
            Text(
              '${_selectedForComparison.length} ${t.selected}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _freelancers.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(
                child: _buildFreelancerCard(_freelancers[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _freelancers.length,
      itemBuilder: (context, index) =>
          _buildFreelancerCardGrid(_freelancers[index]),
    );
  }

  Widget _buildFreelancerCard(FreelancerSearchItem f) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();
    final isSelected = _selectedForComparison.contains(f.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? AppColors.accent
              : (isDark ? AppColors.primaryDark : Colors.grey.shade200),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewProfile(f.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(f.name, f.avatar, 50),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            f.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Checkbox(
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedForComparison.add(f.id);
                              } else {
                                _selectedForComparison.remove(f.id);
                              }
                            });
                          },
                          activeColor: AppColors.accent,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.gray,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          f.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.work, size: 14, color: AppColors.gray),
                        const SizedBox(width: 4),
                        Text(
                          '${f.experience} ${t.years}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.gray,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.attach_money,
                          size: 14,
                          color: AppColors.gray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${f.hourlyRate.toInt()}/${t.hr}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: f.skills.take(3).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.accent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _viewProfile(f.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: BorderSide(color: AppColors.accent),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              t.viewProfile,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showHireOptions(f),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              t.hire,
                              style: const TextStyle(fontSize: 12),
                            ),
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
      ),
    );
  }

  Widget _buildFreelancerCardGrid(FreelancerSearchItem f) {
    final t = AppLocalizations.of(context)!;
    final isDark = _isDarkMode();
    final isSelected = _selectedForComparison.contains(f.id);

    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? AppColors.accent
              : (isDark ? AppColors.primaryDark : Colors.grey.shade200),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewProfile(f.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAvatar(f.name, f.avatar, 45),
                  Checkbox(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedForComparison.add(f.id);
                        } else {
                          _selectedForComparison.remove(f.id);
                        }
                      });
                    },
                    activeColor: AppColors.accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                f.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                f.title,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.star, size: 12, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    f.rating.toStringAsFixed(1),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.work, size: 10, color: AppColors.gray),
                  const SizedBox(width: 2),
                  Text(
                    '${f.experience}y',
                    style: TextStyle(fontSize: 10, color: AppColors.gray),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '\$${f.hourlyRate.toInt()}/${t.hr}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: f.skills.take(2).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(skill, style: const TextStyle(fontSize: 8)),
                  );
                }).toList(),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewProfile(f.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        side: BorderSide(color: AppColors.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        t.viewProfile,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showHireOptions(f),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(t.hire, style: const TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? avatar, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accentLight],
        ),
      ),
      child: avatar != null && avatar.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarInitial(name, size),
              ),
            )
          : _avatarInitial(name, size),
    );
  }

  Widget _avatarInitial(String name, double size) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final isDark = _isDarkMode();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.loading,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(t) {
    final isDark = _isDarkMode();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: isDark ? AppColors.darkTextHint : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            t.noFreelancersFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.tryDifferentFilters,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBottom) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.filters,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedSkill.isEmpty ? null : _selectedSkill,
                  decoration: InputDecoration(labelText: t.skill),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Skills'),
                    ),
                    ..._allSkills.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: (value) {
                    setStateBottom(() => _selectedSkill = value ?? '');
                  },
                ),
                const SizedBox(height: 16),

                Text('${t.minRating}: ${_minRating.toStringAsFixed(1)}'),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  onChanged: (v) => setStateBottom(() => _minRating = v),
                ),

                Text('${t.minExperience}: ${_minExperience} ${t.years}'),
                Slider(
                  value: _minExperience.toDouble(),
                  min: 0,
                  max: 20,
                  divisions: 20,
                  onChanged: (v) =>
                      setStateBottom(() => _minExperience = v.toInt()),
                ),

                Text('${t.maxHourlyRate}: \$${_maxHourlyRate.toInt()}'),
                Slider(
                  value: _maxHourlyRate,
                  min: 0,
                  max: 500,
                  divisions: 50,
                  onChanged: (v) => setStateBottom(() => _maxHourlyRate = v),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadFreelancers();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                        ),
                        child: Text(t.apply),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSortDialog() {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.sortBy,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.star),
              title: Text(t.rating),
              trailing: _sortBy == 'rating' ? const Icon(Icons.check) : null,
              onTap: () => setState(() {
                _sortBy = 'rating';
                _loadFreelancers();
                Navigator.pop(context);
              }),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text('${t.hourlyRate} (${t.lowestFirst})'),
              trailing: _sortBy == 'hourlyRate_asc'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => setState(() {
                _sortBy = 'hourlyRate_asc';
                _loadFreelancers();
                Navigator.pop(context);
              }),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text('${t.hourlyRate} (${t.highestFirst})'),
              trailing: _sortBy == 'hourlyRate_desc'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => setState(() {
                _sortBy = 'hourlyRate_desc';
                _loadFreelancers();
                Navigator.pop(context);
              }),
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: Text('${t.experience} (${t.mostFirst})'),
              trailing: _sortBy == 'experience_desc'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => setState(() {
                _sortBy = 'experience_desc';
                _loadFreelancers();
                Navigator.pop(context);
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.minRating),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  onChanged: (v) => setStateDialog(() => _minRating = v),
                ),
                Text('${_minRating.toStringAsFixed(1)} / 5'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadFreelancers();
            },
            child: Text(t.apply),
          ),
        ],
      ),
    );
  }

  void _showPriceDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.maxHourlyRate),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _maxHourlyRate,
                  min: 0,
                  max: 500,
                  divisions: 50,
                  onChanged: (v) => setStateDialog(() => _maxHourlyRate = v),
                ),
                Text('\$${_maxHourlyRate.toInt()} / ${t.hr}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadFreelancers();
            },
            child: Text(t.apply),
          ),
        ],
      ),
    );
  }

  void _showExperienceDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.minExperience),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _minExperience.toDouble(),
                  min: 0,
                  max: 20,
                  divisions: 20,
                  onChanged: (v) =>
                      setStateDialog(() => _minExperience = v.toInt()),
                ),
                Text('${_minExperience} ${t.years}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadFreelancers();
            },
            child: Text(t.apply),
          ),
        ],
      ),
    );
  }
}

class FreelancerSearchItem {
  final int id;
  final String name;
  final String? avatar;
  final String title;
  final double rating;
  final List<String> skills;
  final int experience;
  final int completedProjects;
  final double hourlyRate;

  FreelancerSearchItem({
    required this.id,
    required this.name,
    this.avatar,
    required this.title,
    required this.rating,
    required this.skills,
    required this.experience,
    required this.completedProjects,
    required this.hourlyRate,
  });

  factory FreelancerSearchItem.fromJson(Map<String, dynamic> json) {
    return FreelancerSearchItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      avatar: json['avatar'],
      title: json['title'] ?? 'Professional Freelancer',
      rating: (json['rating'] ?? 0).toDouble(),
      skills: List<String>.from(json['skills'] ?? []),
      experience: json['experience'] ?? 0,
      completedProjects: json['completedProjects'] ?? 0,
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
    );
  }
}
