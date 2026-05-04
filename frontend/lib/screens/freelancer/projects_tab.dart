// screens/freelancer/projects_tab.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import 'project_details_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/favorite_button.dart';
import '../../theme/app_theme.dart';

class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  List<Project> projects = [];
  List<Project> filteredProjects = [];
  bool loading = true;
  String selectedCategory = 'All';
  final searchController = TextEditingController();

  List<String> get categories {
    final t = AppLocalizations.of(context);
    return [
      t!.all,
      'Flutter',
      'React',
      'Node.js',
      'Python',
      'UI/UX',
      'Mobile',
      'Web',
    ];
  }

  static const Color accent = Color(0xFF2ECC71);

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProjects() async {
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final data = await ApiService.getAllProjects();

      if (!mounted) return;

      setState(() {
        projects = data.map((json) => Project.fromJson(json)).toList();
        filteredProjects = projects;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(msg: "${t!.errorLoadingProjects} $e");
    }
  }

  void filterProjects(String query) {
    final t = AppLocalizations.of(context);

    setState(() {
      if (query.isEmpty && selectedCategory == t!.all) {
        filteredProjects = projects;
      } else {
        filteredProjects = projects.where((project) {
          final titleMatch =
              project.title?.toLowerCase().contains(query.toLowerCase()) ??
              false;
          final descMatch =
              project.description?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
          final categoryMatch =
              selectedCategory == t!.all ||
              (project.category?.toLowerCase() ==
                  selectedCategory.toLowerCase()) ||
              (project.skills?.any(
                    (skill) => skill.toLowerCase().contains(
                      selectedCategory.toLowerCase(),
                    ),
                  ) ??
                  false);

          return (titleMatch || descMatch) && categoryMatch;
        }).toList();
      }
    });
  }

  void _showSortOptions() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.access_time, color: AppColors.accent),
            title: Text(
              t.newestFirst,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            onTap: () {
              setState(() {
                filteredProjects.sort(
                  (a, b) => b.createdAt!.compareTo(a.createdAt!),
                );
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.attach_money, color: AppColors.accent),
            title: Text(
              t.budgetLowToHigh,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            onTap: () {
              setState(() {
                filteredProjects.sort(
                  (a, b) => (a.budget ?? 0).compareTo(b.budget ?? 0),
                );
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.attach_money, color: AppColors.accent),
            title: Text(
              t.budgetHighToLow,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            onTap: () {
              setState(() {
                filteredProjects.sort(
                  (a, b) => (b.budget ?? 0).compareTo(a.budget ?? 0),
                );
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.timer, color: AppColors.accent),
            title: Text(
              t.durationShortestFirst,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            onTap: () {
              setState(() {
                filteredProjects.sort(
                  (a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0),
                );
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
      elevation: isDark ? 1 : 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailsScreen(projectId: project.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.title ?? t.untitled,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$${project.budget?.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  FavoriteButton(projectId: project.id!),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                    backgroundImage: project.client?.avatar != null
                        ? NetworkImage(project.client!.avatar!)
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
                      project.client?.name ?? t.unknownClient,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(project.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                project.description ?? t.noDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
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
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.accent : AppColors.primary,
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
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.lightTextHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${project.duration} ${t.days}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.lightTextHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.remote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProjectDetailsScreen(projectId: project.id!),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      minimumSize: const Size(80, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      t.apply,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    final t = AppLocalizations.of(context);
    if (date == null) return t!.unknown;

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${t!.daysAgo}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${t!.hoursAgo}';
    } else {
      return t!.justNow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: t.searchProjects,
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextHint
                    : AppColors.lightTextHint,
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.accent),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear, color: AppColors.accent),
                onPressed: () {
                  searchController.clear();
                  filterProjects('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
            onChanged: filterProjects,
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selectedCategory;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    category,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.secondary
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = category;
                      filterProjects(searchController.text);
                    });
                  },
                  backgroundColor: isDark
                      ? AppColors.darkCard
                      : Colors.grey.shade100,
                  selectedColor: AppColors.secondary.withOpacity(0.2),
                  checkmarkColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredProjects.length} ${t.projectsFound}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint,
                ),
              ),
              TextButton.icon(
                onPressed: _showSortOptions,
                icon: Icon(Icons.sort, size: 18, color: AppColors.accent),
                label: Text(t.sort, style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : filteredProjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.lightTextHint,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.noProjectsFound,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchProjects,
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
                      return _buildProjectCard(project);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
