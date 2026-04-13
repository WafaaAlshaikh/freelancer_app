import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class ContractsManagementScreen extends StatefulWidget {
  const ContractsManagementScreen({super.key});

  @override
  State<ContractsManagementScreen> createState() =>
      _ContractsManagementScreenState();
}

class _ContractsManagementScreenState extends State<ContractsManagementScreen> {
  List<Map<String, dynamic>> _contracts = [];
  bool _loading = true;
  String _status = 'all';
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getAdminContracts(
        status: _status,
        page: _currentPage,
      );
      setState(() {
        _contracts = List<Map<String, dynamic>>.from(
          response['contracts'] as List? ?? [],
        );
        _totalPages = response['totalPages'] ?? 1;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Failed to load contracts');
    }
  }

  Future<void> _resolveDispute(int contractId) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Dispute'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write dispute resolution notes...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;

    final res = await ApiService.resolveAdminDispute(
      contractId: contractId,
      resolution: ctrl.text.trim(),
    );
    if (res['success'] == true) {
      Fluttertoast.showToast(msg: 'Dispute resolved');
      _loadContracts();
    } else {
      Fluttertoast.showToast(
        msg: res['message']?.toString() ?? 'Action failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text(
                'Filter status:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(
                    value: 'pending_client',
                    child: Text('Pending Client'),
                  ),
                  DropdownMenuItem(
                    value: 'pending_freelancer',
                    child: Text('Pending Freelancer'),
                  ),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                  DropdownMenuItem(value: 'disputed', child: Text('Disputed')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _status = v;
                    _currentPage = 1;
                  });
                  _loadContracts();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _contracts.isEmpty
              ? const Center(child: Text('No contracts found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _contracts.length,
                  itemBuilder: (context, index) {
                    final c = _contracts[index];
                    final project = Map<String, dynamic>.from(
                      c['Project'] ?? {},
                    );
                    final client = Map<String, dynamic>.from(c['client'] ?? {});
                    final freelancer = Map<String, dynamic>.from(
                      c['freelancer'] ?? {},
                    );
                    final status = c['status']?.toString() ?? '-';
                    final id = c['id'] as int?;

                    return Card(
                      child: ListTile(
                        title: Text(
                          project['title']?.toString() ??
                              'Contract #${c['id']}',
                        ),
                        subtitle: Text(
                          'Client: ${client['name'] ?? 'N/A'} · Freelancer: ${freelancer['name'] ?? 'N/A'}\nStatus: $status · Amount: \$${c['agreed_amount'] ?? 0}',
                        ),
                        isThreeLine: true,
                        trailing: status == 'disputed' && id != null
                            ? ElevatedButton(
                                onPressed: () => _resolveDispute(id),
                                child: const Text('Resolve'),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _loadContracts();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page $_currentPage / $_totalPages'),
                IconButton(
                  onPressed: _currentPage < _totalPages
                      ? () {
                          setState(() => _currentPage++);
                          _loadContracts();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
