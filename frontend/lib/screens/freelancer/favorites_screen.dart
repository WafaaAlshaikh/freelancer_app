// ===== frontend/lib/screens/freelancer/favorites_screen.dart =====
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../models/favorite_model.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import 'project_details_screen.dart';
import '../../theme/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteProject> _favorites = [];
  bool _loading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_loading) {
        _loadFavorites(loadMore: true);
      }
    }
  }

  Future<void> _loadFavorites({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;

    setState(() => _loading = true);

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final response = await ApiService.getUserFavorites(page: page);

      if (response.success) {
        setState(() {
          if (loadMore) {
            _favorites.addAll(response.favorites);
            _currentPage = response.page;
          } else {
            _favorites = response.favorites;
            _currentPage = response.page;
          }
          _totalPages = response.totalPages;
          _hasMore = _currentPage < _totalPages;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      final t = AppLocalizations.of(context)!;
      Fluttertoast.showToast(msg: '${t.errorLoadingFavorites}: $e');
    }
  }

  Future<void> _removeFromFavorites(int projectId) async {
    final t = AppLocalizations.of(context)!;
    try {
      final success = await ApiService.removeFromFavorites(projectId);
      if (success) {
        setState(() {
          _favorites.removeWhere((f) => f.project.id == projectId);
        });
        Fluttertoast.showToast(msg: t.removedFromFavorites);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    }
  }

  void _navigateToProject(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(projectId: project.id!),
      ),
    ).then((_) => _loadFavorites());
  }

  void _showRemoveDialog(FavoriteProject favorite) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          t.removeFromFavorites,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          t.removeFromFavoritesConfirmation(
            favorite.project.title ?? t.untitled,
          ),
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t.cancel,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromFavorites(favorite.project.id!);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(t.remove),
          ),
        ],
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
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: () => _loadFavorites(),
          ),
        ],
      ),
      body: _loading && _favorites.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _favorites.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () => _loadFavorites(),
              color: theme.colorScheme.primary,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _favorites.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _favorites.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final favorite = _favorites[index];
                  return _buildFavoriteCard(favorite);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            t.noFavoritesYet,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.saveProjectsByTappingHeart,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.search),
            label: Text(t.browseProjects),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteProject favorite) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final project = favorite.project;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardColor,
      elevation: isDark ? 1 : 2,
      child: InkWell(
        onTap: () => _navigateToProject(project),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title ?? t.untitled,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => _showRemoveDialog(favorite),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${project.duration} ${t.days}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${t.added}: ${_formatDate(favorite.addedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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

  String _formatDate(DateTime date) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} ${t?.daysAgo ?? 'd ago'}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ${t?.hoursAgo ?? 'h ago'}';
    } else {
      return t?.justNow ?? 'Just now';
    }
  }
}
