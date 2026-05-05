import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class CreateAdCampaignScreen extends StatefulWidget {
  const CreateAdCampaignScreen({super.key});

  @override
  State<CreateAdCampaignScreen> createState() => _CreateAdCampaignScreenState();
}

class _CreateAdCampaignScreenState extends State<CreateAdCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _targetUrlController = TextEditingController();
  final _ctaTextController = TextEditingController(text: 'Learn More');
  final _budgetController = TextEditingController();

  String _adType = 'banner';
  String _pricingModel = 'cpc';
  String _placement = 'home_top';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  double _cpc = 0.10;
  double _cpm = 1.00;
  bool _isLoading = false;

  final List<String> _adTypes = ['banner', 'sidebar', 'popup', 'native'];
  final List<String> _pricingModels = ['cpc', 'cpm', 'flat'];
  final List<String> _placements = [
    'home_top',
    'home_bottom',
    'sidebar_top',
    'sidebar_bottom',
    'search_results',
    'project_page',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _targetUrlController.dispose();
    _ctaTextController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'ad_type': _adType,
      'placement': _placement,
      'title': _nameController.text.trim(),
      'description_text': _descriptionController.text.trim(),
      'image_url': _imageUrlController.text.trim(),
      'target_url': _targetUrlController.text.trim(),
      'cta_text': _ctaTextController.text.trim(),
      'pricing_model': _pricingModel,
      'cost_per_click': _cpc,
      'cost_per_impression': _cpm,
      'total_budget': double.parse(_budgetController.text),
      'start_date': _startDate.toIso8601String().split('T')[0],
      'end_date': _endDate.toIso8601String().split('T')[0],
    };

    try {
      final response = await ApiService.createAdCampaign(data);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign created! Go to payment to activate'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to create'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Create Ad Campaign'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Campaign Info', [
                _buildTextField(
                  _nameController,
                  'Campaign Name *',
                  required: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _descriptionController,
                  'Description',
                  maxLines: 3,
                ),
              ]),
              const SizedBox(height: 16),

              _buildSection('Ad Content', [
                _buildTextField(
                  _imageUrlController,
                  'Image URL',
                  hint: 'https://...',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _targetUrlController,
                  'Target URL',
                  hint: 'https://...',
                ),
                const SizedBox(height: 12),
                _buildTextField(_ctaTextController, 'Button Text'),
              ]),
              const SizedBox(height: 16),

              _buildSection('Ad Settings', [
                _buildDropdown(
                  'Ad Type',
                  _adType,
                  _adTypes,
                  (v) => setState(() => _adType = v!),
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  'Placement',
                  _placement,
                  _placements,
                  (v) => setState(() => _placement = v!),
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  'Pricing Model',
                  _pricingModel,
                  _pricingModels,
                  (v) => setState(() => _pricingModel = v!),
                ),
              ]),
              const SizedBox(height: 16),

              if (_pricingModel == 'cpc')
                _buildSection('CPC Settings', [
                  _buildSlider(
                    'Cost per Click (\$)',
                    _cpc,
                    0.05,
                    2.0,
                    (v) => setState(() => _cpc = v),
                  ),
                ]),
              if (_pricingModel == 'cpm')
                _buildSection('CPM Settings', [
                  _buildSlider(
                    'Cost per 1000 Impressions (\$)',
                    _cpm,
                    0.50,
                    20.0,
                    (v) => setState(() => _cpm = v),
                  ),
                ]),
              const SizedBox(height: 16),

              _buildSection('Budget & Dates', [
                _buildTextField(
                  _budgetController,
                  'Total Budget *',
                  keyboardType: TextInputType.number,
                  required: true,
                  prefix: '\$',
                ),
                const SizedBox(height: 12),
                _buildDatePicker(
                  'Start Date',
                  _startDate,
                  () => _selectDate(context, true),
                ),
                const SizedBox(height: 12),
                _buildDatePicker(
                  'End Date',
                  _endDate,
                  () => _selectDate(context, false),
                ),
              ]),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Campaign',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'After creating the campaign, you will need to complete payment to activate it.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
    String? prefix,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: \$${value.toStringAsFixed(3)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            const SizedBox(width: 12),
            Text(DateFormat('MMM d, yyyy').format(date)),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
