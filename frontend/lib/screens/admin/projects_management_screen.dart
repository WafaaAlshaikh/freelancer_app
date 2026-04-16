// screens/admin/projects_management_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

const _kAccent = Color(0xFF5B58E2);
const _kAccentLight = Color(0xFF8B88FF);
const _kPageBg = Color(0xFFF0F2F8);

const _statusColors = {
  'open': [Color(0xFF14A800), Color(0xFF0A6E00)],
  'in_progress': [Color(0xFF0EA5E9), Color(0xFF0369A1)],
  'completed': [Color(0xFF10B981), Color(0xFF047857)],
  'cancelled': [Color(0xFFEF4444), Color(0xFFB91C1C)],
};

const _statusLabels = {
  'open': 'Open',
  'in_progress': 'In Progress',
  'completed': 'Completed',
  'cancelled': 'Cancelled',
};

class ProjectsManagementScreen extends StatefulWidget {
  const ProjectsManagementScreen({super.key});
  @override
  State<ProjectsManagementScreen> createState() =>
      _ProjectsManagementScreenState();
}

class _ProjectsManagementScreenState extends State<ProjectsManagementScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;
  String _status = 'all';
  String _search = '';
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getAdminProjects(
        status: _status,
        search: _search,
        page: _currentPage,
      );
      setState(() {
        _projects = List<Map<String, dynamic>>.from(
          response['projects'] as List? ?? [],
        );
        _totalPages = response['totalPages'] ?? 1;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Failed to load projects');
    }
  }

  Future<void> _deleteProject(int projectId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Project',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this project?',
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
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await ApiService.deleteAdminProject(projectId);
    if (res['success'] == true) {
      Fluttertoast.showToast(msg: 'Project deleted');
      _loadProjects();
    } else
      Fluttertoast.showToast(
        msg: res['message']?.toString() ?? 'Delete failed',
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
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kPageBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search projects...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFAAAAAA),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: Color(0xFFAAAAAA),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) {
                      _search = v;
                      _currentPage = 1;
                      _loadProjects();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusDropdown(),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: _kPageBg,
          child: Row(
            children: [
              Text(
                '${_projects.length} projects',
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
          child: _loading && _projects.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kAccent))
              : _projects.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _projects.length,
                  itemBuilder: (_, i) => _buildProjectCard(_projects[i]),
                ),
        ),

        if (_totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withOpacity(0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: _kAccent,
            size: 18,
          ),
          style: const TextStyle(
            color: _kAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'open', child: Text('Open')),
            DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _status = v;
              _currentPage = 1;
            });
            _loadProjects();
          },
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> p) {
    final client = Map<String, dynamic>.from(p['client'] ?? {});
    final status = p['status']?.toString() ?? 'open';
    final colors = _statusColors[status] ?? [Colors.grey, Colors.grey.shade700];
    final label = _statusLabels[status] ?? status;
    final budget = p['budget'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
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
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.folder_rounded,
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
                      Expanded(
                        child: Text(
                          p['title']?.toString() ?? 'Untitled Project',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A1B3E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusChip(label, colors),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${client['name'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.attach_money,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      Text(
                        '$budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Color(0xFF888888),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  final id = p['id'] as int?;
                  if (id != null) _deleteProject(id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withOpacity(0.12)).toList(),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.first.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.first,
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
              Icons.work_outline,
              size: 40,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No projects found',
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
                    _loadProjects();
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
                    _loadProjects();
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
