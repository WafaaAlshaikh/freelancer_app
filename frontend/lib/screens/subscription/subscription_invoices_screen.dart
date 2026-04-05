import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class SubscriptionInvoicesScreen extends StatefulWidget {
  const SubscriptionInvoicesScreen({super.key});

  @override
  State<SubscriptionInvoicesScreen> createState() =>
      _SubscriptionInvoicesScreenState();
}

class _SubscriptionInvoicesScreenState
    extends State<SubscriptionInvoicesScreen> {
  List<Invoice> _invoices = [];
  bool _loading = true;
  String? _error;
  int _total = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;
    if (loadMore)
      _currentPage++;
    else
      _currentPage = 1;

    setState(() {
      _loading = !loadMore;
      _error = null;
    });

    try {
      final response = await ApiService.getInvoices(page: _currentPage);
      print('📡 Invoices response: $response');

      if (response['success'] == true) {
        final List<dynamic> invoicesJson = response['invoices'] ?? [];
        final newInvoices = invoicesJson
            .map((json) => Invoice.fromJson(json))
            .toList();

        setState(() {
          if (loadMore) {
            _invoices.addAll(newInvoices);
          } else {
            _invoices = newInvoices;
          }
          _total = response['total'] ?? 0;
          _totalPages = response['totalPages'] ?? 1;
          _hasMore = _currentPage < _totalPages;
          _loading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load invoices';
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading invoices: $e');
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  String _formatCurrency(dynamic amount) {
    final value = _parseDouble(amount);
    return '\$${value.toStringAsFixed(2)}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadInvoices(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading && _invoices.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading invoices...'),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadInvoices(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _invoices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No invoices yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you purchase a subscription, invoices will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/subscription/plans');
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('View Plans'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff14A800),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = _invoices[index];
                      return _buildInvoiceCard(invoice);
                    },
                  ),
                ),
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: () => _loadInvoices(loadMore: true),
                      child: const Text('Load More'),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice.invoiceNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  invoice.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(invoice.status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${_formatDate(invoice.createdAt)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Text(
                _formatCurrency(invoice.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff14A800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount: ${_formatCurrency(invoice.amount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Tax: ${_formatCurrency(invoice.tax)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (invoice.discount > 0)
                      Text(
                        'Discount: ${_formatCurrency(invoice.discount)}',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                  ],
                ),
              ),
              if (invoice.pdfUrl != null && invoice.pdfUrl!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    Fluttertoast.showToast(
                      msg: 'PDF download will be available soon',
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class Invoice {
  final int id;
  final String invoiceNumber;
  final double amount;
  final double discount;
  final double tax;
  final double total;
  final String status;
  final String? pdfUrl;
  final String createdAt;
  final String? paidAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.discount,
    required this.tax,
    required this.total,
    required this.status,
    this.pdfUrl,
    required this.createdAt,
    this.paidAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    return Invoice(
      id: json['id'] ?? 0,
      invoiceNumber: json['invoice_number'] ?? 'INV-${json['id']}',
      amount: parseDouble(json['amount']),
      discount: parseDouble(json['discount']),
      tax: parseDouble(json['tax']),
      total: parseDouble(json['total']),
      status: json['status'] ?? 'pending',
      pdfUrl: json['pdf_url'],
      createdAt:
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      paidAt: json['paid_at']?.toString(),
    );
  }
}
