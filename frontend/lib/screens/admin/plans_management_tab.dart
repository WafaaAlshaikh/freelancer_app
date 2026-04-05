import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/subscription_plan_model.dart';

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
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan.name}"?'),
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
    if (confirm != true) return;

    final success = await ApiService.deletePlan(plan.id);
    if (success) {
      _loadPlans();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan deleted successfully')),
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
      builder: (context) =>
          PlanFormDialog(plan: plan, onSaved: () => _loadPlans()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPlans,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showPlanDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff14A800),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _plans.length,
            itemBuilder: (context, index) {
              final plan = _plans[index];
              return _buildPlanCard(plan);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: plan.isRecommended
            ? Border.all(color: const Color(0xff14A800), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (plan.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff14A800),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Recommended',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showPlanDialog(plan: plan),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deletePlan(plan),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.formattedPrice,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: plan.price == 0 ? Colors.grey : const Color(0xff14A800),
            ),
          ),
          if (plan.description != null) ...[
            const SizedBox(height: 8),
            Text(
              plan.description!,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildFeatureChip(
                'Proposals: ${plan.proposalLimit == null ? 'Unlimited' : plan.proposalLimit}',
              ),
              _buildFeatureChip(
                'Active Projects: ${plan.activeProjectLimit == null ? 'Unlimited' : plan.activeProjectLimit}',
              ),
              if (plan.aiInsights) _buildFeatureChip('AI Insights'),
              if (plan.prioritySupport) _buildFeatureChip('Priority Support'),
              if (plan.apiAccess) _buildFeatureChip('API Access'),
              if (plan.customBranding) _buildFeatureChip('Custom Branding'),
              _buildFeatureChip('Trial: ${plan.trialDays} days'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Features: ${plan.features.join(', ')}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
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
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late String _billingPeriod;
  late TextEditingController _proposalLimitController;
  late TextEditingController _activeProjectLimitController;
  late bool _aiInsights;
  late bool _prioritySupport;
  late bool _apiAccess;
  late bool _customBranding;
  late TextEditingController _trialDaysController;
  late TextEditingController _sortOrderController;
  late bool _isRecommended;
  late List<String> _features;
  final TextEditingController _featureInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _slugController = TextEditingController(text: widget.plan?.slug ?? '');
    _descriptionController = TextEditingController(
      text: widget.plan?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.plan?.price.toString() ?? '0',
    );
    _billingPeriod = widget.plan?.billingPeriod ?? 'monthly';
    _proposalLimitController = TextEditingController(
      text: widget.plan?.proposalLimit?.toString() ?? '',
    );
    _activeProjectLimitController = TextEditingController(
      text: widget.plan?.activeProjectLimit?.toString() ?? '',
    );
    _aiInsights = widget.plan?.aiInsights ?? false;
    _prioritySupport = widget.plan?.prioritySupport ?? false;
    _apiAccess = widget.plan?.apiAccess ?? false;
    _customBranding = widget.plan?.customBranding ?? false;
    _trialDaysController = TextEditingController(
      text: widget.plan?.trialDays.toString() ?? '14',
    );
    _sortOrderController = TextEditingController(
      text: widget.plan?.sortOrder.toString() ?? '0',
    );
    _isRecommended = widget.plan?.isRecommended ?? false;
    _features = List<String>.from(widget.plan?.features ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _proposalLimitController.dispose();
    _activeProjectLimitController.dispose();
    _trialDaysController.dispose();
    _sortOrderController.dispose();
    _featureInputController.dispose();
    super.dispose();
  }

  void _addFeature() {
    final feature = _featureInputController.text.trim();
    if (feature.isNotEmpty) {
      setState(() {
        _features.add(feature);
        _featureInputController.clear();
      });
    }
  }

  void _removeFeature(int index) {
    setState(() {
      _features.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'slug': _slugController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'price': double.parse(_priceController.text),
      'billing_period': _billingPeriod,
      'features': _features,
      'proposal_limit': _proposalLimitController.text.trim().isEmpty
          ? null
          : int.parse(_proposalLimitController.text),
      'active_project_limit': _activeProjectLimitController.text.trim().isEmpty
          ? null
          : int.parse(_activeProjectLimitController.text),
      'ai_insights': _aiInsights,
      'priority_support': _prioritySupport,
      'api_access': _apiAccess,
      'custom_branding': _customBranding,
      'trial_days': int.parse(_trialDaysController.text),
      'sort_order': int.parse(_sortOrderController.text),
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
      title: Text(widget.plan != null ? 'Edit Plan' : 'New Plan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Slug * (e.g., pro, business)',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price *'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null
                    ? 'Invalid number'
                    : null,
              ),
              DropdownButtonFormField<String>(
                value: _billingPeriod,
                decoration: const InputDecoration(labelText: 'Billing Period'),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (v) => setState(() => _billingPeriod = v!),
              ),
              TextFormField(
                controller: _proposalLimitController,
                decoration: const InputDecoration(
                  labelText: 'Proposal Limit (leave empty for unlimited)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _activeProjectLimitController,
                decoration: const InputDecoration(
                  labelText: 'Active Project Limit (empty = unlimited)',
                ),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: const Text('AI Insights'),
                value: _aiInsights,
                onChanged: (v) => setState(() => _aiInsights = v),
              ),
              SwitchListTile(
                title: const Text('Priority Support'),
                value: _prioritySupport,
                onChanged: (v) => setState(() => _prioritySupport = v),
              ),
              SwitchListTile(
                title: const Text('API Access'),
                value: _apiAccess,
                onChanged: (v) => setState(() => _apiAccess = v),
              ),
              SwitchListTile(
                title: const Text('Custom Branding'),
                value: _customBranding,
                onChanged: (v) => setState(() => _customBranding = v),
              ),
              TextFormField(
                controller: _trialDaysController,
                decoration: const InputDecoration(labelText: 'Trial Days'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _sortOrderController,
                decoration: const InputDecoration(labelText: 'Sort Order'),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: const Text('Recommended'),
                value: _isRecommended,
                onChanged: (v) => setState(() => _isRecommended = v),
              ),
              const Divider(),
              const Text(
                'Features',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _featureInputController,
                      decoration: const InputDecoration(
                        hintText: 'Add feature',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addFeature,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _features.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final feature = entry.value;
                  return Chip(
                    label: Text(feature),
                    onDeleted: () => _removeFeature(idx),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
