// ===== frontend/lib/screens/freelancer/advanced_search_screen.dart =====
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../models/project_model.dart';
import '../../models/financial_model.dart';
import '../../services/api_service.dart';
import 'project_details_screen.dart';
import '../../theme/app_theme.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _minDurationController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  List<Project> _projects = [];
  List<SavedFilter> _savedFilters = [];
  List<ProjectAlert> _alerts = [];

  String _selectedCategory = 'all';
  String _selectedSortBy = 'newest';
  bool _loading = false;
  bool _loadingFilters = false;
  bool _showFilters = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  List<String> get _categories {
    final t = AppLocalizations.of(context);
    return [
      'all',
      t!.mobileDevelopment,
      t.webDevelopment,
      t.backendDevelopment,
      t.uiUxDesign,
      t.graphicDesign,
      t.contentWriting,
      t.digitalMarketing,
      t.devOps,
      t.database,
    ];
  }

  List<Map<String, dynamic>> get _sortOptions {
    final t = AppLocalizations.of(context);
    return [
      {'value': 'newest', 'label': t!.newestFirst},
      {'value': 'budget_high', 'label': t.budgetHighToLow},
      {'value': 'budget_low', 'label': t.budgetLowToHigh},
      {'value': 'duration_short', 'label': t.durationShortestFirst},
      {'value': 'duration_long', 'label': t.durationLongestFirst},
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _minDurationController.dispose();
    _maxDurationController.dispose();
    _skillsController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_loading) {
        _searchProjects(loadMore: true);
      }
    }
  }

  Future<void> _loadData() async {
    await Future.wait([_loadSavedFilters(), _loadAlerts()]);
    _searchProjects();
  }

  Future<void> _loadSavedFilters() async {
    setState(() => _loadingFilters = true);
    try {
      final filters = await ApiService.getSavedFilters();
      setState(() {
        _savedFilters = filters;
        _loadingFilters = false;
      });
    } catch (e) {
      setState(() => _loadingFilters = false);
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await ApiService.getUserAlerts();
      setState(() => _alerts = alerts);
    } catch (e) {
      print('Error loading alerts: $e');
    }
  }

  Future<void> _searchProjects({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;

    setState(() => _loading = true);

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final response = await ApiService.advancedProjectSearch(
        query: _searchController.text,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        minBudget: _minBudgetController.text.isNotEmpty
            ? double.tryParse(_minBudgetController.text)
            : null,
        maxBudget: _maxBudgetController.text.isNotEmpty
            ? double.tryParse(_maxBudgetController.text)
            : null,
        minDuration: _minDurationController.text.isNotEmpty
            ? int.tryParse(_minDurationController.text)
            : null,
        maxDuration: _maxDurationController.text.isNotEmpty
            ? int.tryParse(_maxDurationController.text)
            : null,
        skills: _skillsController.text.isNotEmpty
            ? _skillsController.text
            : null,
        sortBy: _selectedSortBy,
        page: page,
      );

      setState(() {
        if (loadMore) {
          _projects.addAll(response.projects);
          _currentPage = response.page;
        } else {
          _projects = response.projects;
          _currentPage = response.page;
        }
        _totalPages = response.totalPages;
        _hasMore = _currentPage < _totalPages;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      final t = AppLocalizations.of(context);
      Fluttertoast.showToast(msg: '${t!.searchError}: $e');
    }
  }

  Future<void> _saveCurrentFilter() async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.saveSearchFilter),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: t.filterName,
            hintText: t.filterHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: Text(t.save),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final filterData = {
        'query': _searchController.text,
        'category': _selectedCategory,
        'minBudget': _minBudgetController.text,
        'maxBudget': _maxBudgetController.text,
        'minDuration': _minDurationController.text,
        'maxDuration': _maxDurationController.text,
        'skills': _skillsController.text,
        'sortBy': _selectedSortBy,
      };

      try {
        await ApiService.saveSearchFilter(
          name: nameController.text,
          filterData: filterData,
          isDefault: false,
        );
        Fluttertoast.showToast(msg: t.filterSaved);
        _loadSavedFilters();
      } catch (e) {
        Fluttertoast.showToast(msg: '${t.errorSavingFilter}: $e');
      }
    }
  }

  void _applySavedFilter(SavedFilter filter) {
    final data = filter.filterData;
    setState(() {
      _searchController.text = data['query'] ?? '';
      _selectedCategory = data['category'] ?? 'all';
      _minBudgetController.text = data['minBudget'] ?? '';
      _maxBudgetController.text = data['maxBudget'] ?? '';
      _minDurationController.text = data['minDuration'] ?? '';
      _maxDurationController.text = data['maxDuration'] ?? '';
      _skillsController.text = data['skills'] ?? '';
      _selectedSortBy = data['sortBy'] ?? 'newest';
    });
    _searchProjects();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'all';
      _minBudgetController.clear();
      _maxBudgetController.clear();
      _minDurationController.clear();
      _maxDurationController.clear();
      _skillsController.clear();
      _selectedSortBy = 'newest';
    });
    _searchProjects();
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
          tabs: [
            Tab(text: t.search, icon: const Icon(Icons.search)),
            Tab(text: t.saved, icon: const Icon(Icons.bookmark)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _showFilters ? AppColors.secondary : theme.iconTheme.color,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFiltersPanel(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSearchResults(), _buildSavedTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: t.searchProjects,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: t.category,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.cardColor,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              dropdownColor: theme.cardColor,
              style: TextStyle(color: theme.colorScheme.onSurface),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat == 'all' ? t.all : cat),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t.minBudget,
                      prefixText: '\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t.maxBudget,
                      prefixText: '\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minDurationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t.minDuration,
                      suffixText: t.days,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxDurationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t.maxDuration,
                      suffixText: t.days,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skillsController,
              decoration: InputDecoration(
                hintText: t.skillsCommaSeparated,
                prefixIcon: const Icon(Icons.code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.cardColor,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSortBy,
              decoration: InputDecoration(
                labelText: t.sortBy,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.cardColor,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              dropdownColor: theme.cardColor,
              style: TextStyle(color: theme.colorScheme.onSurface),
              items: _sortOptions.map<DropdownMenuItem<String>>((opt) {
                return DropdownMenuItem<String>(
                  value: opt['value'] as String,
                  child: Text(opt['label'] as String),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSortBy = value!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(t.reset),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _searchProjects(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(t.search),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _saveCurrentFilter,
              icon: Icon(
                Icons.save,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                t.saveThisSearch,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading && _projects.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              t.noProjectsFound,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _showFilters = true),
              child: Text(
                t.adjustYourFilters,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _searchProjects(),
      color: theme.colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _projects.length) {
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
          return _buildProjectCard(_projects[index]);
        },
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title ?? t.untitled,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                        const Icon(Icons.access_time, size: 12),
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
                  if (project.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        project.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                  _FavoriteButton(projectId: project.id!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedTab() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadSavedFilters();
        await _loadAlerts();
      },
      color: theme.colorScheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingFilters)
            Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          else ...[
            if (_savedFilters.isNotEmpty) ...[
              Text(
                t.savedSearches,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._savedFilters.map((filter) => _buildSavedFilterCard(filter)),
            ],

            const SizedBox(height: 24),

            if (_alerts.isNotEmpty) ...[
              Text(
                t.projectAlerts,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._alerts.map((alert) => _buildAlertCard(alert)),
            ],

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _showCreateAlertDialog,
              icon: const Icon(Icons.add_alert),
              label: Text(t.createNewAlert),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildSavedFilterCard(SavedFilter filter) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.cardColor,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.bookmark, color: AppColors.secondary),
        ),
        title: Text(
          filter.name,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          '${filter.filterData['category'] ?? t.all} • ${filter.filterData['minBudget'] != null ? '\$${filter.filterData['minBudget']}' : t.any} ${t.budget}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteFilter(filter),
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        onTap: () => _applySavedFilter(filter),
      ),
    );
  }

  Widget _buildAlertCard(ProjectAlert alert) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.cardColor,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alert.isActive
                ? AppColors.secondary.withOpacity(0.1)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.notifications_active,
            color: alert.isActive ? AppColors.secondary : Colors.grey,
          ),
        ),
        title: Text(
          alert.name,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          alert.keywords.isNotEmpty ? alert.keywords.join(', ') : t.anyKeywords,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: alert.isActive,
              onChanged: (_) => _toggleAlert(alert),
              activeColor: AppColors.secondary,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteAlert(alert),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFilter(SavedFilter filter) async {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteFilter),
        content: Text('${t.deleteFilterQuestion} "${filter.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteSavedFilter(filter.id);
        _loadSavedFilters();
        Fluttertoast.showToast(msg: t.filterDeleted);
      } catch (e) {
        Fluttertoast.showToast(msg: '${t.error}: $e');
      }
    }
  }

  Future<void> _deleteAlert(ProjectAlert alert) async {
    final t = AppLocalizations.of(context)!;
    try {
      await ApiService.deleteAlert(alert.id);
      _loadAlerts();
      Fluttertoast.showToast(msg: t.alertDeleted);
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    }
  }

  Future<void> _toggleAlert(ProjectAlert alert) async {
    try {
      await ApiService.toggleAlert(alert.id);
      _loadAlerts();
    } catch (e) {
      final t = AppLocalizations.of(context)!;
      Fluttertoast.showToast(msg: '${t.error}: $e');
    }
  }

  void _showCreateAlertDialog() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final keywordsController = TextEditingController();
    final skillsController = TextEditingController();
    final minBudgetController = TextEditingController();
    final maxBudgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.createProjectAlert),
        backgroundColor: theme.cardColor,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t.alertName,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keywordsController,
                decoration: InputDecoration(
                  labelText: t.keywordsCommaSeparated,
                  hintText: t.keywordsHint,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skillsController,
                decoration: InputDecoration(
                  labelText: t.skillsCommaSeparated,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minBudgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t.minBudget,
                        prefixText: '\$ ',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxBudgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t.maxBudget,
                        prefixText: '\$ ',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final keywords = keywordsController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              final skills = skillsController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              await ApiService.createProjectAlert(
                name: nameController.text,
                keywords: keywords,
                skills: skills,
                minBudget: minBudgetController.text.isNotEmpty
                    ? double.tryParse(minBudgetController.text)
                    : null,
                maxBudget: maxBudgetController.text.isNotEmpty
                    ? double.tryParse(maxBudgetController.text)
                    : null,
              );

              Navigator.pop(context);
              _loadAlerts();
              Fluttertoast.showToast(msg: t.alertCreated);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: Text(t.create),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final int projectId;
  const _FavoriteButton({required this.projectId});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _isFavorite = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final isFav = await ApiService.isProjectFavorite(widget.projectId);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final t = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      if (_isFavorite) {
        await ApiService.removeFromFavorites(widget.projectId);
        if (mounted) {
          setState(() => _isFavorite = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t?.removedFromFavorites ?? 'Removed from favorites',
              ),
            ),
          );
        }
      } else {
        await ApiService.addToFavorites(widget.projectId);
        if (mounted) {
          setState(() => _isFavorite = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t?.addedToFavorites ?? 'Added to favorites'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${t?.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.grey,
        size: 22,
      ),
      onPressed: _toggleFavorite,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
