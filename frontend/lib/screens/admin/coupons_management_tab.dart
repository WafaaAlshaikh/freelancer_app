// screens/admin/coupons_management_tab.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/coupon_model.dart';

const _kAccent = Color(0xFF5B58E2);
const _kGreen = Color(0xFF14A800);
const _kAmber = Color(0xFFF59E0B);
const _kPageBg = Color(0xFFF0F2F8);

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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Coupon',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete coupon "${coupon.code}"?',
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
    final success = await ApiService.deleteCoupon(coupon.id);
    if (success) {
      _loadCoupons();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon deleted'),
          backgroundColor: Colors.black87,
        ),
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
      builder: (ctx) => CouponFormDialog(coupon: coupon, onSaved: _loadCoupons),
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
              onPressed: _loadCoupons,
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
                '${_coupons.length} coupons',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF888888),
                ),
              ),
              const Spacer(),
              _buildAddButton('New Coupon', () => _showCouponDialog()),
            ],
          ),
        ),
        Expanded(
          child: _coupons.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: _coupons.length,
                  itemBuilder: (_, i) => _buildCouponCard(_coupons[i]),
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
            colors: [_kAmber, Color(0xFFB45309)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kAmber.withOpacity(0.35),
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

  Widget _buildCouponCard(Coupon coupon) {
    final isExpired = coupon.validUntil.isBefore(DateTime.now());
    final isActive = coupon.isActive && !isExpired;
    final usage = coupon.maxUses != null
        ? '${coupon.usedCount}/${coupon.maxUses} used'
        : '${coupon.usedCount} used';
    final isPercentage = coupon.discountType == 'percentage';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? _kAmber.withOpacity(0.3) : Colors.grey.shade100,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        _kAmber.withOpacity(0.1),
                        _kAmber.withOpacity(0.02),
                      ],
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade50, Colors.grey.shade50],
                    ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade100,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [_kAmber, Color(0xFFB45309)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isActive ? null : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _kAmber.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        coupon.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.formattedDiscount,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? const Color(0xFF1A1B3E)
                              : Colors.grey.shade400,
                        ),
                      ),
                      Text(
                        isPercentage
                            ? 'Percentage discount'
                            : 'Fixed amount off',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isExpired ? 'Expired' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                _iconBtn(
                  Icons.edit_outlined,
                  _kAccent,
                  () => _showCouponDialog(coupon: coupon),
                ),
                const SizedBox(width: 6),
                _iconBtn(
                  Icons.delete_outline,
                  Colors.red.shade400,
                  () => _deleteCoupon(coupon),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _infoItem(
                  Icons.calendar_today_outlined,
                  '${_fmtDate(coupon.validFrom)} – ${_fmtDate(coupon.validUntil)}',
                ),
                const SizedBox(width: 16),
                _infoItem(Icons.people_outline_rounded, usage),
                const SizedBox(width: 16),
                _infoItem(
                  Icons.category_outlined,
                  _scopeLabel(coupon.applicationScope),
                ),
                if (coupon.applicablePlans != null &&
                    coupon.applicablePlans!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  ...coupon.applicablePlans!
                      .map(
                        (plan) => Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _kAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _kAccent.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            plan,
                            style: const TextStyle(
                              fontSize: 10,
                              color: _kAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _scopeLabel(String scope) {
    switch (scope) {
      case 'contract':
        return 'Contracts';
      case 'both':
        return 'All';
      default:
        return 'Subscriptions';
    }
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
              Icons.local_offer_outlined,
              size: 40,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No coupons yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _buildAddButton('Create First Coupon', () => _showCouponDialog()),
        ],
      ),
    );
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
  late TextEditingController _codeCtrl, _discountCtrl, _maxUsesCtrl;
  late String _discountType, _applicationScope;
  late DateTime _validFrom, _validUntil;
  late List<String> _applicablePlans;
  late bool _isActive;
  final _planInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.coupon?.code ?? '');
    _discountType = widget.coupon?.discountType ?? 'percentage';
    _discountCtrl = TextEditingController(
      text: widget.coupon?.discountValue.toString() ?? '',
    );
    _validFrom = widget.coupon?.validFrom ?? DateTime.now();
    _validUntil =
        widget.coupon?.validUntil ??
        DateTime.now().add(const Duration(days: 30));
    _maxUsesCtrl = TextEditingController(
      text: widget.coupon?.maxUses?.toString() ?? '',
    );
    _applicablePlans = List<String>.from(widget.coupon?.applicablePlans ?? []);
    _isActive = widget.coupon?.isActive ?? true;
    _applicationScope = widget.coupon?.applicationScope ?? 'subscription';
  }

  @override
  void dispose() {
    for (final c in [_codeCtrl, _discountCtrl, _maxUsesCtrl, _planInputCtrl])
      c.dispose();
    super.dispose();
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
          if (_validUntil.isBefore(_validFrom))
            _validUntil = _validFrom.add(const Duration(days: 30));
        } else
          _validUntil = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'code': _codeCtrl.text.trim().toUpperCase(),
      'discount_type': _discountType,
      'discount_value': double.parse(_discountCtrl.text),
      'valid_from': _validFrom.toIso8601String().split('T')[0],
      'valid_until': _validUntil.toIso8601String().split('T')[0],
      'max_uses': _maxUsesCtrl.text.trim().isEmpty
          ? null
          : int.parse(_maxUsesCtrl.text),
      'applicable_plans': _applicablePlans.isEmpty ? null : _applicablePlans,
      'is_active': _isActive,
      'application_scope': _applicationScope,
    };

    Coupon? result;
    if (widget.coupon != null)
      result = await ApiService.updateCoupon(widget.coupon!.id, data);
    else
      result = await ApiService.createCoupon(data);

    if (result != null) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon ${widget.coupon != null ? 'updated' : 'created'} successfully',
          ),
          backgroundColor: Colors.black87,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kAmber, Color(0xFFB45309)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.coupon != null ? 'Edit Coupon' : 'New Coupon',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(_codeCtrl, 'Coupon Code *', required: true),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        'Discount Type',
                        _discountType,
                        {
                          'percentage': 'Percentage (%)',
                          'fixed': 'Fixed Amount (\$)',
                        },
                        (v) => setState(() => _discountType = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        _discountCtrl,
                        'Value *',
                        keyboardType: TextInputType.number,
                        required: true,
                        validator: (v) =>
                            double.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                _dropdown(
                  'Applies To',
                  _applicationScope,
                  {
                    'subscription': 'Subscription only',
                    'contract': 'Contract escrow',
                    'both': 'Both',
                  },
                  (v) => setState(() => _applicationScope = v!),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _datePicker(
                        'Valid From',
                        _validFrom,
                        () => _selectDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _datePicker(
                        'Valid Until',
                        _validUntil,
                        () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
                _field(
                  _maxUsesCtrl,
                  'Max Uses (empty = unlimited)',
                  keyboardType: TextInputType.number,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Switch.adaptive(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeColor: _kGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Applicable Plans (optional)',
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
                      child: _field(_planInputCtrl, 'Plan slug (e.g. pro)'),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final p = _planInputCtrl.text.trim();
                        if (p.isNotEmpty && !_applicablePlans.contains(p))
                          setState(() {
                            _applicablePlans.add(p);
                            _planInputCtrl.clear();
                          });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _kAmber,
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
                if (_applicablePlans.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _applicablePlans
                        .map(
                          (p) => Chip(
                            label: Text(
                              p,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onDeleted: () =>
                                setState(() => _applicablePlans.remove(p)),
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
            backgroundColor: _kAmber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Save Coupon',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    bool required = false,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
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
            borderSide: const BorderSide(color: _kAmber),
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
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            borderSide: const BorderSide(color: _kAmber),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          isDense: true,
        ),
        items: options.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _datePicker(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
