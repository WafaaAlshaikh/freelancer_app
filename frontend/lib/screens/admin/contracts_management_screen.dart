// screens/admin/contracts_management_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

const _kAccent = Color(0xFF5B58E2);
const _kAccentLight = Color(0xFF8B88FF);
const _kGreen = Color(0xFF14A800);
const _kPageBg = Color(0xFFF0F2F8);

const _statusConfig = {
  'draft': {
    'color': Color(0xFF888888),
    'bg': Color(0xFFF1F1F1),
    'icon': Icons.edit_note_rounded,
  },
  'pending_client': {
    'color': Color(0xFFF59E0B),
    'bg': Color(0xFFFEF3C7),
    'icon': Icons.pending_rounded,
  },
  'pending_freelancer': {
    'color': Color(0xFFF97316),
    'bg': Color(0xFFFED7AA),
    'icon': Icons.schedule_rounded,
  },
  'active': {
    'color': Color(0xFF0EA5E9),
    'bg': Color(0xFFE0F2FE),
    'icon': Icons.play_circle_rounded,
  },
  'completed': {
    'color': Color(0xFF14A800),
    'bg': Color(0xFFDCFCE7),
    'icon': Icons.check_circle_rounded,
  },
  'cancelled': {
    'color': Color(0xFFEF4444),
    'bg': Color(0xFFFEE2E2),
    'icon': Icons.cancel_rounded,
  },
  'disputed': {
    'color': Color(0xFFDC2626),
    'bg': Color(0xFFFEE2E2),
    'icon': Icons.warning_rounded,
  },
};

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.gavel_rounded,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Resolve Dispute',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resolution notes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your resolution details here...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kAccent),
                ),
                filled: true,
                fillColor: _kPageBg,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
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
    } else
      Fluttertoast.showToast(
        msg: res['message']?.toString() ?? 'Action failed',
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Text(
                'Filter by status:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B3E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                              'all',
                              'draft',
                              'active',
                              'completed',
                              'disputed',
                              'cancelled',
                              'pending_client',
                              'pending_freelancer',
                            ]
                            .map(
                              (s) => _filterChip(
                                s == 'all' ? 'All' : _formatStatusLabel(s),
                                s,
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: _kPageBg,
          child: Row(
            children: [
              Text(
                '${_contracts.length} contracts',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B3E),
                ),
              ),
              if (_loading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kAccent,
                  ),
                ),
              ],
            ],
          ),
        ),

        Expanded(
          child: _loading && _contracts.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kAccent))
              : _contracts.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _contracts.length,
                  itemBuilder: (_, i) => _buildContractCard(_contracts[i]),
                ),
        ),

        if (_totalPages > 1) _buildPagination(),
      ],
    );
  }

  String _formatStatusLabel(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _filterChip(String label, String value) {
    final selected = _status == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _status = value;
          _currentPage = 1;
        });
        _loadContracts();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_kAccentLight, _kAccent])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade200,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> c) {
    final project = Map<String, dynamic>.from(c['Project'] ?? {});
    final client = Map<String, dynamic>.from(c['client'] ?? {});
    final freelancer = Map<String, dynamic>.from(c['freelancer'] ?? {});
    final status = c['status']?.toString() ?? 'draft';
    final id = c['id'] as int?;
    final amount = c['agreed_amount'] ?? 0;
    final isDisputed = status == 'disputed';

    final cfg =
        _statusConfig[status] ??
        {
          'color': const Color(0xFF888888),
          'bg': const Color(0xFFF1F1F1),
          'icon': Icons.help_outline,
        };
    final color = cfg['color'] as Color;
    final bg = cfg['bg'] as Color;
    final icon = cfg['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDisputed
              ? Colors.red.withOpacity(0.2)
              : Colors.grey.shade100,
          width: isDisputed ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project['title']?.toString() ??
                              'Contract #${c['id']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A1B3E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _statusBadge(status, color, bg),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        client['name'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        ' → ',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                      Icon(
                        Icons.work_outline,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        freelancer['name'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14A800).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '\$$amount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14A800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isDisputed && id != null) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _resolveDispute(id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.gavel_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Resolve',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        _formatStatusLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
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
              Icons.description_outlined,
              size: 40,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No contracts found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(
            Icons.chevron_left,
            _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadContracts();
                  }
                : null,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _kPageBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $_currentPage / $_totalPages',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1B3E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _pageBtn(
            Icons.chevron_right,
            _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadContracts();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? _kAccent.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onTap != null
                ? _kAccent.withOpacity(0.2)
                : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? _kAccent : Colors.grey.shade400,
        ),
      ),
    );
  }
}
