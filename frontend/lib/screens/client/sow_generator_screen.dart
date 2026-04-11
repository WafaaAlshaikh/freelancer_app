// frontend/lib/screens/client/sow_generator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';

class SOWGeneratorScreen extends StatefulWidget {
  final Project project;
  final User freelancer;
  final double agreedAmount;
  final VoidCallback? onSOWGenerated;
  final int contractId;
  final int proposalId;

  const SOWGeneratorScreen({
    super.key,
    required this.project,
    required this.freelancer,
    required this.agreedAmount,
    this.onSOWGenerated,
    required this.contractId,
    required this.proposalId,
  });

  @override
  State<SOWGeneratorScreen> createState() => _SOWGeneratorScreenState();
}

class _SOWGeneratorScreenState extends State<SOWGeneratorScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _milestones = [];
  bool _loading = true;
  bool _generating = false;
  bool _analyzing = true;
  String? _sowHtml;
  Map<String, dynamic>? _analysis;
  List<Map<String, dynamic>> _recommendations = [];

  final TextEditingController _additionalTermsController =
      TextEditingController();
  late TabController _tabController;

  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dark = Color(0xFF1F2937);
  static const Color _gray = Color(0xFF6B7280);
  static const Color _light = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _additionalTermsController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _analyzing = true;
      _loading = true;
    });

    try {
      final analysis = await ApiService.analyzeProjectWithMarket(
        widget.project.id!,
      );

      setState(() {
        _analysis = analysis;
        _recommendations = List<Map<String, dynamic>>.from(
          analysis['final_recommendations'] ?? [],
        );

        if (analysis['suggested_milestones'] != null) {
          _milestones = List<Map<String, dynamic>>.from(
            analysis['suggested_milestones'],
          );
          _autoCalculateAmounts();
        } else {
          _initDefaultMilestones();
        }

        _analyzing = false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _analyzing = false;
        _loading = false;
      });
      Fluttertoast.showToast(msg: 'Error loading analysis: $e');
      _initDefaultMilestones();
    }
  }

  void _initDefaultMilestones() {
    final totalAmount = widget.agreedAmount;
    _milestones = [
      {
        'title': 'Project Setup & Planning',
        'description':
            'Initial setup, requirements analysis, and architecture design',
        'amount': totalAmount * 0.2,
        'percentage': 20,
        'due_date': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
      },
      {
        'title': 'Core Development',
        'description': 'Main features implementation',
        'amount': totalAmount * 0.5,
        'percentage': 50,
        'due_date': DateTime.now()
            .add(const Duration(days: 14))
            .toIso8601String(),
      },
      {
        'title': 'Testing & Final Delivery',
        'description': 'QA testing, bug fixes, and final deployment',
        'amount': totalAmount * 0.3,
        'percentage': 30,
        'due_date': DateTime.now()
            .add(const Duration(days: 21))
            .toIso8601String(),
      },
    ];
  }

  void _autoCalculateAmounts() {
    final total = _milestones.fold<double>(
      0,
      (sum, m) => sum + (m['percentage'] ?? 0),
    );
    if (total > 0) {
      for (var milestone in _milestones) {
        final percentage = milestone['percentage'] ?? 0;
        milestone['amount'] = widget.agreedAmount * percentage / 100;
      }
    }
  }

  Future<void> _generateSOW() async {
    if (_milestones.isEmpty) {
      Fluttertoast.showToast(msg: 'Please add at least one milestone');
      return;
    }

    setState(() => _generating = true);

    try {
      final response = await ApiService.generateSOW(
        projectId: widget.project.id!,
        freelancerId: widget.freelancer.id!,
        contractId: widget.contractId,
        agreedAmount: widget.agreedAmount,
        milestones: _milestones,
        additionalTerms: _additionalTermsController.text,
      );

      if (response['success'] == true) {
        final sowHtml = response['sow'];
        final sowAnalysis = response['analysis'];

        final updateResult = await ApiService.updateContractWithSOW(
          contractId: widget.contractId,
          sowHtml: sowHtml,
          sowAnalysis: sowAnalysis,
        );

        if (updateResult['success'] == true) {
          setState(() {
            _sowHtml = sowHtml;
            _generating = false;
          });

          Fluttertoast.showToast(msg: '✅ SOW generated and saved to contract!');

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/contract',
              arguments: {
                'contractId': widget.contractId,
                'userRole': 'client',
              },
            );
          }
        } else {
          throw Exception(
            updateResult['message'] ?? 'Failed to update contract',
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to generate SOW');
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _generating = false);
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  void _updateMilestones(List<Map<String, dynamic>> newMilestones) {
    setState(() => _milestones = newMilestones);
  }

  void _addMilestone() {
    setState(() {
      _milestones.add({
        'title': 'New Milestone',
        'description': '',
        'amount': 0,
        'percentage': 0,
        'due_date': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
      });
    });
  }

  void _removeMilestone(int index) {
    setState(() => _milestones.removeAt(index));
  }

  void _applyRecommendation(Map<String, dynamic> recommendation) {
    if (recommendation['type'] == 'budget') {
      Fluttertoast.showToast(
        msg: 'Consider adjusting your budget based on market data',
      );
    } else if (recommendation['type'] == 'timeline') {
      Fluttertoast.showToast(msg: 'Consider extending your project timeline');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sowHtml != null) {
      return _buildSOWPreview();
    }

    return Scaffold(
      backgroundColor: _light,
      appBar: AppBar(
        title: const Text('AI Smart SOW Generator'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: _gray,
          tabs: const [
            Tab(text: 'Milestones', icon: Icon(Icons.flag)),
            Tab(text: 'Analysis', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _loading
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: [_buildMilestonesTab(), _buildAnalysisTab()],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
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
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _analyzing ? 'AI is analyzing your project...' : 'Loading...',
            style: TextStyle(fontSize: 16, color: _gray),
          ),
          if (_analyzing) ...[
            const SizedBox(height: 8),
            Text(
              'Analyzing market data and similar projects',
              style: TextStyle(fontSize: 12, color: _gray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestonesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_success, _success.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contract Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.project.title ?? 'Project',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'with ${widget.freelancer.name}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          '\$${widget.agreedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Payment Milestones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Define project phases and payment schedule',
            style: TextStyle(color: _gray),
          ),
          const SizedBox(height: 16),

          ..._milestones.asMap().entries.map((entry) {
            final index = entry.key;
            final milestone = entry.value;
            return _buildMilestoneCard(milestone, index);
          }),

          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _addMilestone,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Milestone'),
            style: TextButton.styleFrom(foregroundColor: _primary),
          ),

          const SizedBox(height: 20),

          const Text(
            'Additional Terms (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _additionalTermsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any special terms or conditions...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: milestone['title'],
                    decoration: const InputDecoration(
                      labelText: 'Milestone Title',
                      border: UnderlineInputBorder(),
                    ),
                    onChanged: (value) => milestone['title'] = value,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: _danger),
                  onPressed: () => _removeMilestone(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: milestone['description'],
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: UnderlineInputBorder(),
              ),
              onChanged: (value) => milestone['description'] = value,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: milestone['percentage']?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Percentage (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    onChanged: (value) {
                      milestone['percentage'] = double.tryParse(value) ?? 0;
                      _autoCalculateAmounts();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: milestone['amount']?.toStringAsFixed(2),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (\$)',
                      border: const OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    onChanged: (value) {
                      milestone['amount'] = double.tryParse(value) ?? 0;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, size: 18),
              title: const Text('Due Date'),
              subtitle: Text(
                milestone['due_date'] != null
                    ? _formatDate(DateTime.parse(milestone['due_date']))
                    : 'Select date',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    milestone['due_date'] = date.toIso8601String();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_analysis == null) {
      return const Center(child: Text('No analysis data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'AI Market Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAnalysisRow(
                  'Difficulty Level',
                  _analysis!['difficulty_level']?.toUpperCase() ?? 'N/A',
                  Icons.speed,
                ),
                _buildAnalysisRow(
                  'Estimated Duration',
                  '${_analysis!['estimated_duration_days'] ?? '?'} days',
                  Icons.calendar_today,
                ),
                _buildAnalysisRow(
                  'Confidence Score',
                  '${_analysis!['confidence_score'] ?? 85}%',
                  Icons.analytics,
                  color: _success,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_analysis!['market_insights'] != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Market Insights',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInsightRow(
                    'Similar Projects',
                    '${_analysis!['market_insights']['similar_projects_count']} projects analyzed',
                  ),
                  _buildInsightRow(
                    'Market Average Price',
                    '\$${_analysis!['market_insights']['market_average_cost']}',
                  ),
                  _buildInsightRow(
                    'Market Average Duration',
                    '${_analysis!['market_insights']['market_average_duration']} days',
                  ),
                  _buildInsightRow(
                    'Success Rate',
                    '${_analysis!['market_insights']['success_rate']}%',
                    color: _success,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (_recommendations.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: _warning),
                      SizedBox(width: 8),
                      Text(
                        'Recommendations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._recommendations.map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8, right: 8),
                            decoration: BoxDecoration(
                              color: rec['priority'] == 'high'
                                  ? _danger
                                  : _warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rec['message'],
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (rec['suggested_action'] != null)
                                  TextButton(
                                    onPressed: () => _applyRecommendation(rec),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Apply suggestion →',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _gray),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: _gray)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? _dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _gray)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? _dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _generating ? null : _generateSOW,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _generating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Generate Professional SOW',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSOWPreview() {
    return Scaffold(
      backgroundColor: _light,
      appBar: AppBar(
        title: const Text('Generated SOW'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              Fluttertoast.showToast(msg: 'Print feature coming soon');
            },
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              Fluttertoast.showToast(msg: 'PDF export coming soon');
            },
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              Navigator.pop(context, true);
            },
            tooltip: 'Proceed to Contract',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Html(data: _sowHtml!),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
