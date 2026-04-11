// lib/screens/client/compare_freelancers_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

class CompareFreelancersScreen extends StatefulWidget {
  final int projectId;
  final List<int> freelancerIds;

  const CompareFreelancersScreen({
    super.key,
    required this.projectId,
    required this.freelancerIds,
  });

  @override
  State<CompareFreelancersScreen> createState() =>
      _CompareFreelancersScreenState();
}

class _CompareFreelancersScreenState extends State<CompareFreelancersScreen> {
  List<dynamic> _freelancers = [];
  bool _loading = true;
  int _selectedMetric = 0;

  final List<String> _metrics = [
    'Rating',
    'Experience',
    'Completion Rate',
    'Projects',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final result = await ApiService.compareFreelancers(
      freelancerIds: widget.freelancerIds,
      projectId: widget.projectId,
    );

    setState(() {
      _freelancers = result['comparisons'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Compare Freelancers'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _showComparisonChart(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMetricSelector(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _freelancers.length,
                    itemBuilder: (context, index) {
                      return _buildComparisonCard(_freelancers[index], index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_metrics.length, (index) {
          final isSelected = _selectedMetric == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedMetric = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _metrics[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildComparisonCard(dynamic freelancer, int rank) {
    final score = _getMetricValue(freelancer, _selectedMetric);
    final maxScore = _getMaxScore(_selectedMetric);

    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: rank == 0
                    ? [Colors.amber.shade400, Colors.amber.shade600]
                    : [Colors.grey.shade400, Colors.grey.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${rank + 1}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: rank == 0 ? Colors.amber : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundImage: freelancer['avatar'] != null
                      ? NetworkImage(freelancer['avatar'])
                      : null,
                  child: freelancer['avatar'] == null
                      ? Text(
                          freelancer['name'][0].toUpperCase(),
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        freelancer['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${freelancer['skills']?.take(3).join(', ')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getMetricDisplay(freelancer, _selectedMetric),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rank == 0 ? Colors.amber : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow(
                  'Overall Rating',
                  freelancer['rating']?.toStringAsFixed(1) ?? 'N/A',
                  Icons.star,
                  Colors.amber,
                ),
                const Divider(),
                _buildStatRow(
                  'Experience',
                  '${freelancer['experience']} years',
                  Icons.work,
                  Colors.blue,
                ),
                const Divider(),
                _buildStatRow(
                  'Completion Rate',
                  '${freelancer['completionRate']?.toStringAsFixed(0)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
                const Divider(),
                _buildStatRow(
                  'Total Interviews',
                  '${freelancer['totalInterviews']}',
                  Icons.interpreter_mode,
                  Colors.purple,
                ),
                const Divider(),
                _buildStatRow(
                  'Projects Completed',
                  '${freelancer['projectsCompleted']}',
                  Icons.work,
                  Colors.orange,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewProfile(freelancer['id']),
                    icon: const Icon(Icons.person),
                    label: const Text('Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _hireFreelancer(freelancer['id']),
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('Hire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff14A800),
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

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _getMetricValue(dynamic freelancer, int metric) {
    switch (metric) {
      case 0:
        return freelancer['rating'] ?? 0;
      case 1:
        return freelancer['experience'] ?? 0;
      case 2:
        return freelancer['completionRate'] ?? 0;
      case 3:
        return freelancer['projectsCompleted'] ?? 0;
      default:
        return 0;
    }
  }

  double _getMaxScore(int metric) {
    switch (metric) {
      case 0:
        return 5;
      case 1:
        return 20;
      case 2:
        return 100;
      case 3:
        return 50;
      default:
        return 100;
    }
  }

  String _getMetricDisplay(dynamic freelancer, int metric) {
    switch (metric) {
      case 0:
        return '${freelancer['rating']?.toStringAsFixed(1)}/5';
      case 1:
        return '${freelancer['experience']} yrs';
      case 2:
        return '${freelancer['completionRate']?.toStringAsFixed(0)}%';
      case 3:
        return '${freelancer['projectsCompleted']} projects';
      default:
        return '';
    }
  }

  void _showComparisonChart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Comparison'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barGroups: List.generate(_freelancers.length, (index) {
                final freelancer = _freelancers[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: (freelancer['rating'] ?? 0) * 20,
                      color: Colors.amber,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: freelancer['completionRate'] ?? 0,
                      color: Colors.green,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < _freelancers.length) {
                        return Text(
                          _freelancers[index]['name'][0],
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewProfile(int userId) {
    Navigator.pushNamed(context, '/profile', arguments: userId);
  }

  void _hireFreelancer(int userId) {
    Navigator.pop(context, userId);
  }
}
