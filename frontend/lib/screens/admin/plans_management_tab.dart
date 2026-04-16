// screens/admin/plans_management_tab.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/subscription_plan_model.dart';

const _kAccent = Color(0xFF5B58E2);
const _kGreen = Color(0xFF14A800);
const _kPageBg = Color(0xFFF0F2F8);

class PlansManagementTab extends StatefulWidget {
  const PlansManagementTab({super.key});
  @override
  State<PlansManagementTab> createState() => _PlansManagementTabState();
}

class _PlansManagementTabState extends State<PlansManagementTab> {
  List<SubscriptionPlan> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await ApiService.getAdminPlans();
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load plans: $e';
        _loading = false;
      });
    }
  }

  Future<void> _deletePlan(SubscriptionPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${plan.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await ApiService.deletePlan(plan.id);
    if (success) {
      _loadPlans();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan deleted successfully'),
          backgroundColor: Colors.black87,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete plan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPlanDialog({SubscriptionPlan? plan}) {
    showDialog(
      context: context,
      builder: (ctx) => PlanFormDialog(plan: plan, onSaved: _loadPlans),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPlans,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                '${_plans.length} plans configured',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF888888),
                ),
              ),
              const Spacer(),
              _buildAddButton('New Plan', () => _showPlanDialog()),
            ],
          ),
        ),
        Expanded(
          child: _plans.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: _plans.length,
                  itemBuilder: (_, i) => _buildPlanCard(_plans[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kGreen, Color(0xFF0A6E00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kGreen.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isRecommended = plan.isRecommended;
    final isFree = plan.price == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isRecommended
            ? Border.all(color: _kGreen, width: 2)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: isRecommended
                ? _kGreen.withOpacity(0.12)
                : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isRecommended
                  ? _kGreen.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isFree
                        ? const LinearGradient(
                            colors: [Color(0xFF888888), Color(0xFF555555)],
                          )
                        : isRecommended
                        ? const LinearGradient(
                            colors: [Color(0xFF14A800), Color(0xFF0A6E00)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF5B58E2), Color(0xFF3D35CC)],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFree
                        ? Icons.card_giftcard_rounded
                        : isRecommended
                        ? Icons.stars_rounded
                        : Icons.subscriptions_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1B3E),
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF14A800),
                                    Color(0xFF0A6E00),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Recommended',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFree
                            ? 'Free'
                            : '\$${plan.price.toStringAsFixed(2)} / ${plan.billingPeriod}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isFree ? Colors.grey.shade500 : _kGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _iconBtn(
                      Icons.edit_outlined,
                      _kAccent,
                      () => _showPlanDialog(plan: plan),
                    ),
                    const SizedBox(width: 6),
                    _iconBtn(
                      Icons.delete_outline,
                      Colors.red.shade400,
                      () => _deletePlan(plan),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.description != null &&
                    plan.description!.isNotEmpty) ...[
                  Text(
                    plan.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _featureChip(
                      '${plan.proposalLimit == null ? '∞' : plan.proposalLimit} Proposals',
                    ),
                    _featureChip(
                      '${plan.activeProjectLimit == null ? '∞' : plan.activeProjectLimit} Projects',
                    ),
                    _featureChip('${plan.trialDays}d Trial'),
                    if (plan.aiInsights)
                      _featureChip('AI Insights', highlight: true),
                    if (plan.prioritySupport)
                      _featureChip('Priority Support', highlight: true),
                    if (plan.apiAccess)
                      _featureChip('API Access', highlight: true),
                    if (plan.customBranding)
                      _featureChip('Custom Brand', highlight: true),
                  ],
                ),
                if (plan.features.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: plan.features
                        .map(
                          (f) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: _kGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                f,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _featureChip(String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? _kAccent.withOpacity(0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: highlight ? Border.all(color: _kAccent.withOpacity(0.2)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: highlight ? _kAccent : Colors.grey.shade700,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: _kPageBg, shape: BoxShape.circle),
            child: Icon(
              Icons.subscriptions_outlined,
              size: 40,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No plans configured',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _buildAddButton('Add First Plan', () => _showPlanDialog()),
        ],
      ),
    );
  }
}

class PlanFormDialog extends StatefulWidget {
  final SubscriptionPlan? plan;
  final VoidCallback onSaved;
  const PlanFormDialog({super.key, this.plan, required this.onSaved});
  @override
  State<PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl,
      _slugCtrl,
      _descCtrl,
      _priceCtrl,
      _proposalLimitCtrl,
      _activeProjectLimitCtrl,
      _trialCtrl,
      _sortCtrl;
  late String _billingPeriod;
  late bool _aiInsights,
      _prioritySupport,
      _apiAccess,
      _customBranding,
      _isRecommended;
  late List<String> _features;
  final _featureInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.plan?.name ?? '');
    _slugCtrl = TextEditingController(text: widget.plan?.slug ?? '');
    _descCtrl = TextEditingController(text: widget.plan?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.plan?.price.toString() ?? '0',
    );
    _billingPeriod = widget.plan?.billingPeriod ?? 'monthly';
    _proposalLimitCtrl = TextEditingController(
      text: widget.plan?.proposalLimit?.toString() ?? '',
    );
    _activeProjectLimitCtrl = TextEditingController(
      text: widget.plan?.activeProjectLimit?.toString() ?? '',
    );
    _aiInsights = widget.plan?.aiInsights ?? false;
    _prioritySupport = widget.plan?.prioritySupport ?? false;
    _apiAccess = widget.plan?.apiAccess ?? false;
    _customBranding = widget.plan?.customBranding ?? false;
    _trialCtrl = TextEditingController(
      text: widget.plan?.trialDays.toString() ?? '14',
    );
    _sortCtrl = TextEditingController(
      text: widget.plan?.sortOrder.toString() ?? '0',
    );
    _isRecommended = widget.plan?.isRecommended ?? false;
    _features = List<String>.from(widget.plan?.features ?? []);
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _slugCtrl,
      _descCtrl,
      _priceCtrl,
      _proposalLimitCtrl,
      _activeProjectLimitCtrl,
      _trialCtrl,
      _sortCtrl,
      _featureInputCtrl,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'name': _nameCtrl.text.trim(),
      'slug': _slugCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text),
      'billing_period': _billingPeriod,
      'features': _features,
      'proposal_limit': _proposalLimitCtrl.text.trim().isEmpty
          ? null
          : int.parse(_proposalLimitCtrl.text),
      'active_project_limit': _activeProjectLimitCtrl.text.trim().isEmpty
          ? null
          : int.parse(_activeProjectLimitCtrl.text),
      'ai_insights': _aiInsights,
      'priority_support': _prioritySupport,
      'api_access': _apiAccess,
      'custom_branding': _customBranding,
      'trial_days': int.parse(_trialCtrl.text),
      'sort_order': int.parse(_sortCtrl.text),
      'is_recommended': _isRecommended,
      'is_active': true,
    };

    SubscriptionPlan? result;
    if (widget.plan != null) {
      result = await ApiService.updatePlan(widget.plan!.id, data);
    } else {
      final newPlan = SubscriptionPlan(
        id: 0,
        name: data['name'] as String,
        slug: data['slug'] as String,
        description: data['description'] as String?,
        price: data['price'] as double,
        billingPeriod: data['billing_period'] as String,
        features: data['features'] as List<String>,
        proposalLimit: data['proposal_limit'] as int?,
        activeProjectLimit: data['active_project_limit'] as int?,
        aiInsights: data['ai_insights'] as bool,
        prioritySupport: data['priority_support'] as bool,
        apiAccess: data['api_access'] as bool,
        customBranding: data['custom_branding'] as bool,
        trialDays: data['trial_days'] as int,
        sortOrder: data['sort_order'] as int,
        isRecommended: data['is_recommended'] as bool,
        isActive: true,
      );
      result = await ApiService.createPlan(newPlan);
    }

    if (result != null) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Plan ${widget.plan != null ? 'updated' : 'created'} successfully',
          ),
          backgroundColor: Colors.black87,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save plan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B88FF), _kAccent],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.subscriptions_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.plan != null ? 'Edit Plan' : 'New Plan',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row([
                  _field(_nameCtrl, 'Plan Name *', required: true),
                  _field(_slugCtrl, 'Slug * (e.g. pro)', required: true),
                ]),
                _field(_descCtrl, 'Description', maxLines: 2),
                _row([
                  _field(
                    _priceCtrl,
                    'Price *',
                    keyboardType: TextInputType.number,
                    required: true,
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? 'Invalid number'
                        : null,
                  ),
                  _dropdown(
                    'Billing Period',
                    _billingPeriod,
                    ['monthly', 'yearly'],
                    (v) => setState(() => _billingPeriod = v!),
                  ),
                ]),
                _row([
                  _field(
                    _proposalLimitCtrl,
                    'Proposal Limit (empty=∞)',
                    keyboardType: TextInputType.number,
                  ),
                  _field(
                    _activeProjectLimitCtrl,
                    'Project Limit (empty=∞)',
                    keyboardType: TextInputType.number,
                  ),
                ]),
                _row([
                  _field(
                    _trialCtrl,
                    'Trial Days',
                    keyboardType: TextInputType.number,
                  ),
                  _field(
                    _sortCtrl,
                    'Sort Order',
                    keyboardType: TextInputType.number,
                  ),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Features',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ..._switches(),
                    _switchChip(
                      'Recommended',
                      _isRecommended,
                      (v) => setState(() => _isRecommended = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Custom Features',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _field(_featureInputCtrl, 'Add feature...'),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final f = _featureInputCtrl.text.trim();
                        if (f.isNotEmpty)
                          setState(() {
                            _features.add(f);
                            _featureInputCtrl.clear();
                          });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _kAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_features.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _features
                        .asMap()
                        .entries
                        .map(
                          (e) => Chip(
                            label: Text(
                              e.value,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onDeleted: () =>
                                setState(() => _features.removeAt(e.key)),
                            deleteIconColor: Colors.grey.shade500,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Save Plan',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  List<Widget> _switches() => [
    _switchChip(
      'AI Insights',
      _aiInsights,
      (v) => setState(() => _aiInsights = v),
    ),
    _switchChip(
      'Priority Support',
      _prioritySupport,
      (v) => setState(() => _prioritySupport = v),
    ),
    _switchChip(
      'API Access',
      _apiAccess,
      (v) => setState(() => _apiAccess = v),
    ),
    _switchChip(
      'Custom Branding',
      _customBranding,
      (v) => setState(() => _customBranding = v),
    ),
  ];

  Widget _switchChip(String label, bool value, ValueChanged<bool> onChange) {
    return GestureDetector(
      onTap: () => onChange(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? _kAccent.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? _kAccent.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 14,
              color: value ? _kAccent : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: value ? _kAccent : Colors.grey.shade600,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: children
            .map(
              (w) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: w,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    int? maxLines,
    TextInputType? keyboardType,
    bool required = false,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines ?? 1,
        keyboardType: keyboardType,
        validator:
            validator ??
            (required
                ? (v) => v == null || v.isEmpty ? 'Required' : null
                : null),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kAccent),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kAccent),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          isDense: true,
        ),
        items: options
            .map(
              (o) => DropdownMenuItem(
                value: o,
                child: Text(
                  o[0].toUpperCase() + o.substring(1),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
