// screens/freelancer/projects_tab.dart
import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import 'project_details_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  List<Project> projects = [];
  List<Project> filteredProjects = [];
  bool loading = true;
  String selectedCategory = 'All';
  final searchController = TextEditingController();

  final List<String> categories = [
    'All',
    'Flutter',
    'React',
    'Node.js',
    'Python',
    'UI/UX',
    'Mobile',
    'Web',
  ];


  @override
  void initState() {
    super.initState();
    print('🚀 ProjectsTab initialized');
    fetchProjects();
  }


  Future<void> fetchProjects() async {
    if (!mounted) return; 

    setState(() => loading = true);

    try {
      print('📡 Calling ApiService.getAllProjects()...');
      final data = await ApiService.getAllProjects();
      print('📊 Raw data received: $data');

      if (!mounted) return;

      setState(() {
        projects = data.map((json) {
          print('🔄 Parsing project: $json');
          return Project.fromJson(json);
        }).toList();

        filteredProjects = projects;
        loading = false;

        print('✅ Projects fetched: ${projects.length}');
      });
    } catch (e) {
      print('❌ Error in fetchProjects: $e');
      if (!mounted) return;
      setState(() => loading = false);
      Fluttertoast.showToast(msg: "Error loading projects: $e");
    }
  }

  void filterProjects(String query) {
    setState(() {
      if (query.isEmpty && selectedCategory == 'All') {
        filteredProjects = projects;
      } else {
        filteredProjects = projects.where((project) {
          final titleMatch =
              project.title?.toLowerCase().contains(query.toLowerCase()) ??
              false;
          final descMatch =
              project.description?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
          final categoryMatch =
              selectedCategory == 'All' ||
              (project.category?.toLowerCase() ==
                  selectedCategory.toLowerCase()) ||
              (project.skills?.any(
                    (skill) => skill.toLowerCase().contains(
                      selectedCategory.toLowerCase(),
                    ),
                  ) ??
                  false);

          return (titleMatch || descMatch) && categoryMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search projects...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  filterProjects('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: filterProjects,
          ),
        ),

        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selectedCategory;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = category;
                      filterProjects(searchController.text);
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: const Color(0xff14A800).withOpacity(0.2),
                  checkmarkColor: const Color(0xff14A800),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xff14A800)
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredProjects.length} projects found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              TextButton.icon(
                onPressed: () {
                  _showSortOptions();
                },
                icon: const Icon(Icons.sort, size: 18),
                label: const Text("Sort"),
              ),
            ],
          ),
        ),

        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filteredProjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No projects found",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchProjects,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
                      return _buildProjectCard(project);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showSortOptions() {
  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.access_time),
          title: const Text('Newest First'),
          onTap: () {
            setState(() {
              filteredProjects.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
            });
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.attach_money),
          title: const Text('Budget: Low to High'),
          onTap: () {
            setState(() {
              filteredProjects.sort((a, b) => (a.budget ?? 0).compareTo(b.budget ?? 0));
            });
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.attach_money),
          title: const Text('Budget: High to Low'),
          onTap: () {
            setState(() {
              filteredProjects.sort((a, b) => (b.budget ?? 0).compareTo(a.budget ?? 0));
            });
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.timer),
          title: const Text('Duration: Shortest First'),
          onTap: () {
            setState(() {
              filteredProjects.sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0));
            });
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

  Widget _buildProjectCard(Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailsScreen(projectId: project.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.title ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$${project.budget?.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: project.client?.avatar != null
                        ? NetworkImage(project.client!.avatar!)
                        : null,
                    child: project.client?.avatar == null
                        ? Text(
                            project.client?.name?[0].toUpperCase() ?? 'C',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      project.client?.name ?? 'Unknown Client',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(project.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                project.description ?? 'No description',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              if (project.skills != null && project.skills!.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: project.skills!.take(3).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${project.duration} days',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Remote',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProjectDetailsScreen(projectId: project.id!),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff14A800),
                      minimumSize: const Size(80, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Apply", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
