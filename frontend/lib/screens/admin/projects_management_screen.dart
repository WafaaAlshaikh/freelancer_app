import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

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
        title: const Text('Delete Project'),
        content: const Text('This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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
    } else {
      Fluttertoast.showToast(
        msg: res['message']?.toString() ?? 'Delete failed',
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
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    _search = v;
                    _currentPage = 1;
                    _loadProjects();
                  },
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
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
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _projects.isEmpty
              ? const Center(child: Text('No projects found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final p = _projects[index];
                    final client = Map<String, dynamic>.from(p['client'] ?? {});
                    return Card(
                      child: ListTile(
                        title: Text(p['title']?.toString() ?? 'Untitled'),
                        subtitle: Text(
                          'Client: ${client['name'] ?? 'N/A'} · Status: ${p['status'] ?? '-'} · Budget: \$${p['budget'] ?? 0}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              final id = p['id'] as int?;
                              if (id != null) _deleteProject(id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                          _loadProjects();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page $_currentPage / $_totalPages'),
                IconButton(
                  onPressed: _currentPage < _totalPages
                      ? () {
                          setState(() => _currentPage++);
                          _loadProjects();
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
