import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/coupon_model.dart';

class CouponsManagementTab extends StatefulWidget {
  const CouponsManagementTab({super.key});

  @override
  State<CouponsManagementTab> createState() => _CouponsManagementTabState();
}

class _CouponsManagementTabState extends State<CouponsManagementTab> {
  List<Coupon> _coupons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final coupons = await ApiService.getAdminCoupons();
      setState(() {
        _coupons = coupons;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load coupons: $e';
        _loading = false;
      });
    }
  }

  Future<void> _deleteCoupon(Coupon coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text('Are you sure you want to delete "${coupon.code}"?'),
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

    final success = await ApiService.deleteCoupon(coupon.id);
    if (success) {
      _loadCoupons();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete coupon'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCouponDialog({Coupon? coupon}) {
    showDialog(
      context: context,
      builder: (context) =>
          CouponFormDialog(coupon: coupon, onSaved: () => _loadCoupons()),
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
              onPressed: _loadCoupons,
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
              onPressed: () => _showCouponDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Coupon'),
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
            itemCount: _coupons.length,
            itemBuilder: (context, index) {
              final coupon = _coupons[index];
              return _buildCouponCard(coupon);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    final isExpired = coupon.validUntil.isBefore(DateTime.now());
    final isActive = coupon.isActive && !isExpired;
    final usage = coupon.maxUses != null
        ? '${coupon.usedCount}/${coupon.maxUses}'
        : '${coupon.usedCount} uses';

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
        border: isActive
            ? Border.all(color: const Color(0xff14A800), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xff14A800) : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  coupon.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  coupon.formattedDiscount,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showCouponDialog(coupon: coupon),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deleteCoupon(coupon),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Valid: ${_formatDate(coupon.validFrom)} - ${_formatDate(coupon.validUntil)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.people, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                usage,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (coupon.applicablePlans != null &&
              coupon.applicablePlans!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: coupon.applicablePlans!.map((plan) {
                return Chip(
                  label: Text(plan, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
          if (!isActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                isExpired ? 'Expired' : 'Inactive',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CouponFormDialog extends StatefulWidget {
  final Coupon? coupon;
  final VoidCallback onSaved;

  const CouponFormDialog({super.key, this.coupon, required this.onSaved});

  @override
  State<CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<CouponFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late String _discountType;
  late TextEditingController _discountValueController;
  late DateTime _validFrom;
  late DateTime _validUntil;
  late TextEditingController _maxUsesController;
  late List<String> _applicablePlans;
  late bool _isActive;
  final TextEditingController _planInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.coupon?.code ?? '');
    _discountType = widget.coupon?.discountType ?? 'percentage';
    _discountValueController = TextEditingController(
      text: widget.coupon?.discountValue.toString() ?? '',
    );
    _validFrom = widget.coupon?.validFrom ?? DateTime.now();
    _validUntil =
        widget.coupon?.validUntil ??
        DateTime.now().add(const Duration(days: 30));
    _maxUsesController = TextEditingController(
      text: widget.coupon?.maxUses?.toString() ?? '',
    );
    _applicablePlans = List<String>.from(widget.coupon?.applicablePlans ?? []);
    _isActive = widget.coupon?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _maxUsesController.dispose();
    _planInputController.dispose();
    super.dispose();
  }

  void _addPlan() {
    final plan = _planInputController.text.trim();
    if (plan.isNotEmpty && !_applicablePlans.contains(plan)) {
      setState(() {
        _applicablePlans.add(plan);
        _planInputController.clear();
      });
    }
  }

  void _removePlan(String plan) {
    setState(() {
      _applicablePlans.remove(plan);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _validFrom : _validUntil,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _validFrom = picked;
          if (_validUntil.isBefore(_validFrom)) {
            _validUntil = _validFrom.add(const Duration(days: 30));
          }
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'code': _codeController.text.trim().toUpperCase(),
      'discount_type': _discountType,
      'discount_value': double.parse(_discountValueController.text),
      'valid_from': _validFrom.toIso8601String().split('T')[0],
      'valid_until': _validUntil.toIso8601String().split('T')[0],
      'max_uses': _maxUsesController.text.trim().isEmpty
          ? null
          : int.parse(_maxUsesController.text),
      'applicable_plans': _applicablePlans.isEmpty ? null : _applicablePlans,
      'is_active': _isActive,
    };

    Coupon? result;
    if (widget.coupon != null) {
      result = await ApiService.updateCoupon(widget.coupon!.id, data);
    } else {
      result = await ApiService.createCoupon(data);
    }

    if (result != null) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon ${widget.coupon != null ? 'updated' : 'created'} successfully',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save coupon'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.coupon != null ? 'Edit Coupon' : 'New Coupon'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Coupon Code *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _discountType,
                decoration: const InputDecoration(labelText: 'Discount Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Percentage (%)'),
                  ),
                  DropdownMenuItem(
                    value: 'fixed',
                    child: Text('Fixed Amount (\$)'),
                  ),
                ],
                onChanged: (v) => setState(() => _discountType = v!),
              ),
              TextFormField(
                controller: _discountValueController,
                decoration: InputDecoration(
                  labelText: _discountType == 'percentage'
                      ? 'Discount %'
                      : 'Discount Amount',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null
                    ? 'Invalid number'
                    : null,
              ),
              ListTile(
                title: const Text('Valid From'),
                subtitle: Text(_formatDate(_validFrom)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),
              ListTile(
                title: const Text('Valid Until'),
                subtitle: Text(_formatDate(_validUntil)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
              ),
              TextFormField(
                controller: _maxUsesController,
                decoration: const InputDecoration(
                  labelText: 'Max Uses (leave empty for unlimited)',
                ),
                keyboardType: TextInputType.number,
              ),
              const Divider(),
              const Text(
                'Applicable Plans (optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _planInputController,
                      decoration: const InputDecoration(
                        hintText: 'Plan slug (e.g., pro)',
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add), onPressed: _addPlan),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _applicablePlans.map((plan) {
                  return Chip(
                    label: Text(plan),
                    onDeleted: () => _removePlan(plan),
                  );
                }).toList(),
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
