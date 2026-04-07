// ===== frontend/lib/screens/freelancer/advanced_search_screen.dart =====
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/project_model.dart';
import '../../models/financial_model.dart';
import '../../services/api_service.dart';
import 'project_details_screen.dart';

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

  final List<String> _categories = [
    'all',
    'Mobile Development',
    'Web Development',
    'Backend Development',
    'UI/UX Design',
    'Graphic Design',
    'Content Writing',
    'Digital Marketing',
    'DevOps',
    'Database',
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First'},
    {'value': 'budget_high', 'label': 'Budget: High to Low'},
    {'value': 'budget_low', 'label': 'Budget: Low to High'},
    {'value': 'duration_short', 'label': 'Duration: Shortest First'},
    {'value': 'duration_long', 'label': 'Duration: Longest First'},
  ];

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
      Fluttertoast.showToast(msg: 'Search error: $e');
    }
  }

  Future<void> _saveCurrentFilter() async {
    final nameController = TextEditingController();
    final isDefault = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Search Filter'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Filter Name',
            hintText: 'e.g., High Budget Flutter Jobs',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff14A800),
            ),
            child: const Text('Save'),
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
          isDefault: isDefault,
        );
        Fluttertoast.showToast(msg: 'Filter saved successfully');
        _loadSavedFilters();
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error saving filter: $e');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Advanced Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xff14A800),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Search', icon: Icon(Icons.search)),
            Tab(text: 'Saved', icon: Icon(Icons.bookmark)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            color: _showFilters ? const Color(0xff14A800) : null,
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              decoration: const InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.toUpperCase()),
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
                    decoration: const InputDecoration(
                      labelText: 'Min Budget',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Budget',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
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
                    decoration: const InputDecoration(
                      labelText: 'Min Duration',
                      suffixText: 'days',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxDurationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Duration',
                      suffixText: 'days',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skillsController,
              decoration: const InputDecoration(
                hintText: 'Skills (comma separated)',
                prefixIcon: Icon(Icons.code),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSortBy,
              decoration: const InputDecoration(labelText: 'Sort By'),
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
                      foregroundColor: Colors.grey,
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _searchProjects(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff14A800),
                    ),
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _saveCurrentFilter,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save this search'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_loading && _projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _showFilters = true),
              child: const Text('Adjust your search filters'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _searchProjects(),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                project.title ?? 'Untitled',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                project.description ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$${project.budget?.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${project.duration} days',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        _FavoriteButton(projectId: project.id!),
                      ],
                    ),
                  ),
                  if (project.category != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
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
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadSavedFilters();
        await _loadAlerts();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingFilters)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (_savedFilters.isNotEmpty) ...[
              const Text(
                'Saved Searches',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._savedFilters.map((filter) => _buildSavedFilterCard(filter)),
            ],

            const SizedBox(height: 24),

            if (_alerts.isNotEmpty) ...[
              const Text(
                'Project Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._alerts.map((alert) => _buildAlertCard(alert)),
            ],

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _showCreateAlertDialog,
              icon: const Icon(Icons.add_alert),
              label: const Text('Create New Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff14A800),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildSavedFilterCard(SavedFilter filter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xff14A800).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.bookmark, color: Color(0xff14A800)),
        ),
        title: Text(filter.name),
        subtitle: Text(
          '${filter.filterData['category'] ?? 'All'} • ${filter.filterData['minBudget'] != null ? '\$${filter.filterData['minBudget']}' : 'Any'} budget',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteFilter(filter),
        ),
        onTap: () => _applySavedFilter(filter),
      ),
    );
  }

  Widget _buildAlertCard(ProjectAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alert.isActive
                ? Colors.green.shade100
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.notifications_active,
            color: alert.isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(alert.name),
        subtitle: Text(
          '${alert.keywords.isNotEmpty ? alert.keywords.join(', ') : 'Any keywords'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: alert.isActive,
              onChanged: (_) => _toggleAlert(alert),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteAlert(alert),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFilter(SavedFilter filter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Filter'),
        content: Text('Delete "${filter.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteSavedFilter(filter.id);
        _loadSavedFilters();
        Fluttertoast.showToast(msg: 'Filter deleted');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error: $e');
      }
    }
  }

  Future<void> _deleteAlert(ProjectAlert alert) async {
    try {
      await ApiService.deleteAlert(alert.id);
      _loadAlerts();
      Fluttertoast.showToast(msg: 'Alert deleted');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> _toggleAlert(ProjectAlert alert) async {
    try {
      await ApiService.toggleAlert(alert.id);
      _loadAlerts();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  void _showCreateAlertDialog() {
    final nameController = TextEditingController();
    final keywordsController = TextEditingController();
    final skillsController = TextEditingController();
    final minBudgetController = TextEditingController();
    final maxBudgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Project Alert'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Alert Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keywordsController,
                decoration: const InputDecoration(
                  labelText: 'Keywords (comma separated)',
                  hintText: 'flutter, mobile, app',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minBudgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min Budget',
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxBudgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Budget',
                        prefixText: '\$ ',
                      ),
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
            child: const Text('Cancel'),
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
              Fluttertoast.showToast(msg: 'Alert created successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff14A800),
            ),
            child: const Text('Create'),
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
    setState(() => _loading = true);
    try {
      if (_isFavorite) {
        await ApiService.removeFromFavorites(widget.projectId);
        if (mounted) {
          setState(() => _isFavorite = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      } else {
        await ApiService.addToFavorites(widget.projectId);
        if (mounted) {
          setState(() => _isFavorite = true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
