import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart' as AppTheme;

class TopPerformersScreen extends StatefulWidget {
  const TopPerformersScreen({super.key});

  @override
  State<TopPerformersScreen> createState() => _TopPerformersScreenState();
}

class _TopPerformersScreenState extends State<TopPerformersScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _performers = {};
  bool _loading = true;
  String? _errorMessage;
  late TabController _tabController;
  String _selectedCriteria = 'freelancers_by_rating';

  final List<Map<String, dynamic>> _criteriaOptions = [
    {'value': 'overall', 'label': 'Overall Score', 'icon': Icons.leaderboard},
    {
      'value': 'freelancers_by_earnings',
      'label': 'Top Earners',
      'icon': Icons.attach_money,
    },
    {
      'value': 'freelancers_by_rating',
      'label': 'Top Rated',
      'icon': Icons.star,
    },
    {
      'value': 'clients_by_spending',
      'label': 'Top Spenders',
      'icon': Icons.shopping_cart,
    },
    {
      'value': 'fastest_growing',
      'label': 'Fastest Growing',
      'icon': Icons.trending_up,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPerformers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPerformers() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      print('📡 Loading performers with criteria: $_selectedCriteria');
      final response = await ApiService.getTopPerformers(
        criteria: _selectedCriteria,
        limit: 15,
      );
      print('📡 Response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        final performersData = response['performers'] ?? {};
        print('📊 Performers data keys: ${performersData.keys}');

        setState(() {
          _performers = performersData;
          _loading = false;
        });

        if (_getAllPerformersList().isEmpty) {
          Fluttertoast.showToast(msg: 'No data available for this criteria');
        }
      } else {
        setState(() {
          _loading = false;
          _errorMessage = response['message'] ?? 'Failed to load data';
        });
        Fluttertoast.showToast(msg: _errorMessage!);
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Connection error: $e';
        });
      }
      Fluttertoast.showToast(msg: 'Error loading performers: $e');
    }
  }

  List<Map<String, dynamic>> _getAllPerformersList() {
    List<Map<String, dynamic>> allItems = [];

    final possibleKeys = [
      'freelancers',
      'clients',
      'users',
      'items',
      'data',
      'rows',
      'results',
    ];

    for (var key in possibleKeys) {
      if (_performers.containsKey(key)) {
        final data = _performers[key];
        if (data is List) {
          allItems.addAll(data.map((e) => _toMap(e)).toList());
        } else if (data is Map) {
          for (var subKey in ['rows', 'items', 'data']) {
            if (data[subKey] is List) {
              allItems.addAll(
                (data[subKey] as List).map((e) => _toMap(e)).toList(),
              );
            }
          }
        }
      }
    }

    return allItems;
  }

  Map<String, dynamic> _toMap(dynamic item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) {
      return Map<String, dynamic>.fromEntries(
        item.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );
    }
    return {};
  }

  List<dynamic> _getPerformersList(String type) {
    final data = _performers[type];

    print('🔍 Getting list for type: $type');
    print('📦 Data: $data');

    if (data == null) {
      print('⚠️ No data for type: $type');
      return [];
    }

    if (data is List) {
      print('✅ Data is List with ${data.length} items');
      return data;
    }

    if (data is Map) {
      if (data.containsKey('data') && data['data'] is List) {
        print('✅ Found data in map["data"]');
        return data['data'];
      }
      if (data.containsKey('rows') && data['rows'] is List) {
        print('✅ Found data in map["rows"]');
        return data['rows'];
      }
      if (data.containsKey('items') && data['items'] is List) {
        print('✅ Found data in map["items"]');
        return data['items'];
      }

      for (var value in data.values) {
        if (value is List) {
          print('✅ Found list in map values');
          return value;
        }
      }
    }

    print('⚠️ Could not extract list from data');
    return [];
  }

  Map<String, dynamic> _getStats() {
    if (_performers.containsKey('stats') && _performers['stats'] is Map) {
      return _performers['stats'];
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.AppColors.darkBackground
          : const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Top Performers',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.AppColors.darkSurface : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildCriteriaSelector(theme, isDark),
        ),
      ),
      body: _buildBody(isDark, theme),
    );
  }

  Widget _buildBody(bool isDark, ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPerformers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    List<dynamic> freelancers = [];
    List<dynamic> clients = [];
    List<dynamic> users = [];

    switch (_selectedCriteria) {
      case 'freelancers_by_rating':
      case 'freelancers_by_earnings':
      case 'overall':
        freelancers = _getPerformersList('freelancers');
        break;
      case 'clients_by_spending':
        clients = _getPerformersList('clients');
        break;
      case 'fastest_growing':
        users = _getPerformersList('users');
        break;
    }

    if (freelancers.isEmpty && clients.isEmpty && users.isEmpty) {
      freelancers = _getAllPerformersList();
    }

    final hasFreelancers = freelancers.isNotEmpty;
    final hasClients = clients.isNotEmpty;
    final hasUsers = users.isNotEmpty;

    if (!hasFreelancers && !hasClients && !hasUsers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No performers data available',
              style: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different criteria',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPerformers,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_getStats().isNotEmpty)
              _buildStatsSummary(_getStats(), isDark, theme),

            if (hasFreelancers) ...[
              if (_getStats().isNotEmpty) const SizedBox(height: 20),
              _buildSection(
                _getSectionTitle('Freelancers', isDark),
                freelancers,
                isDark,
                theme,
                showScore: _selectedCriteria == 'overall',
                showRating:
                    _selectedCriteria == 'freelancers_by_rating' ||
                    _selectedCriteria == 'overall',
                showEarnings:
                    _selectedCriteria == 'freelancers_by_earnings' ||
                    _selectedCriteria == 'overall',
              ),
            ],

            if (hasClients) ...[
              if (hasFreelancers) const SizedBox(height: 20),
              _buildSection(
                _getSectionTitle('Clients', isDark),
                clients,
                isDark,
                theme,
                showSpending: true,
              ),
            ],

            if (hasUsers) ...[
              if (hasFreelancers || hasClients) const SizedBox(height: 20),
              _buildSection(
                _getSectionTitle('Fastest Growing Users', isDark),
                users,
                isDark,
                theme,
                showGrowth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSectionTitle(String type, bool isDark) {
    switch (_selectedCriteria) {
      case 'freelancers_by_rating':
        return '⭐ Top Rated Freelancers';
      case 'freelancers_by_earnings':
        return '💰 Top Earning Freelancers';
      case 'clients_by_spending':
        return '💎 Top Spending Clients';
      case 'fastest_growing':
        return '🚀 Fastest Growing Users';
      default:
        return '🏆 Top $type';
    }
  }

  Widget _buildStatsSummary(
    Map<String, dynamic> stats,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Total',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  '${stats['total'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 30, width: 1, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Average',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  '${stats['average'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 30, width: 1, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Top 10%',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  '${stats['topPercentile'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaSelector(ThemeData theme, bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _criteriaOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _criteriaOptions[index];
          final isSelected = _selectedCriteria == option['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCriteria = option['value']);
              _loadPerformers();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? AppTheme.AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark
                            ? AppTheme.AppColors.grayDark
                            : Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    option['icon'],
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    option['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<dynamic> data,
    bool isDark,
    ThemeData theme, {
    bool showScore = false,
    bool showRating = false,
    bool showEarnings = false,
    bool showSpending = false,
    bool showGrowth = false,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Top ${data.length > 10 ? 10 : data.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length > 10 ? 10 : data.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = _toMap(data[index]);
              final rank = index + 1;
              Color rankColor = Colors.grey;
              if (rank == 1) rankColor = const Color(0xFFFFD700);
              if (rank == 2) rankColor = const Color(0xFFC0C0C0);
              if (rank == 3) rankColor = const Color(0xFFCD7F32);

              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  item['name'] ?? item['fullName'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item['email'] ?? item['title'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showEarnings && item['total_earnings'] != null)
                        Text(
                          _formatCurrency(item['total_earnings']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14A800),
                            fontSize: 13,
                          ),
                        ),
                      if (showSpending && item['total_spent'] != null)
                        Text(
                          _formatCurrency(item['total_spent']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B),
                            fontSize: 13,
                          ),
                        ),
                      if (showRating && item['avg_rating'] != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatRating(item['avg_rating']),
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (item['total_reviews'] != null)
                              Text(
                                ' (${item['total_reviews']})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      if (showScore && item['score'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getScoreColor(
                              item['score'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Score: ${item['score']}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getScoreColor(item['score']),
                            ),
                          ),
                        ),
                      if (showGrowth && item['growth_rate'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (item['growth_rate'] >= 0
                                        ? Colors.green
                                        : Colors.red)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item['growth_rate'] >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 10,
                                color: item['growth_rate'] >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${item['growth_rate'].abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: item['growth_rate'] >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatCurrency(dynamic value) {
    final number = _parseToDouble(value);
    return '\$${number.toStringAsFixed(0)}';
  }

  String _formatRating(dynamic value) {
    final number = _parseToDouble(value);
    return number.toStringAsFixed(1);
  }

  Color _getScoreColor(dynamic score) {
    final intValue = score is int
        ? score
        : (score is double ? score.toInt() : 0);
    if (intValue >= 80) return const Color(0xFF14A800);
    if (intValue >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
