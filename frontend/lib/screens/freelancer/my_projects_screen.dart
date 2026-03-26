// screens/freelancer/my_projects_screen.dart
import 'package:flutter/material.dart';
import 'package:freelancer_platform/screens/client/project_details_screen.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  List<Project> projects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMyProjects();
  }

  Future<void> fetchMyProjects() async {
    setState(() => loading = true);

    try {
      final data = await ApiService.getMyProjects();

      setState(() {
        projects = data.map((json) => Project.fromJson(json)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      Fluttertoast.showToast(msg: "Error loading projects");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Projects"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No projects yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your accepted proposals will appear here",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/freelancer/proposals');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff14A800),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("View My Proposals"),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchMyProjects,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return _buildProjectCard(project);
                },
              ),
            ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final progress = _calculateProgress(project);

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
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: project.status == 'in_progress'
                          ? Colors.green
                          : project.status == 'completed'
                          ? Colors.blue
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    project.statusText,
                    style: TextStyle(
                      color: project.status == 'in_progress'
                          ? Colors.green
                          : project.status == 'completed'
                          ? Colors.blue
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                project.title ?? 'Untitled Project',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: project.client?.avatar != null
                        ? NetworkImage(project.client!.avatar!)
                        : null,
                    child: project.client?.avatar == null
                        ? Text(
                            project.client?.name?[0].toUpperCase() ?? 'C',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.client?.name ?? 'Unknown Client',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Client',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '\$${project.budget?.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${project.duration} days',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${progress}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 100 ? Colors.green : Colors.blue,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Open chat
                      },
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text("Message"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showSubmitWorkDialog(project);
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(
                        project.status == 'completed' ? "View" : "Submit Work",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff14A800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitWorkDialog(Project project) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Submit Work'),
      content: const Text('Are you sure you want to submit this work?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // TODO: Call API to submit work
            Navigator.pop(context);
            Fluttertoast.showToast(msg: 'Work submitted successfully!');
          },
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}

  int _calculateProgress(Project project) {
    if (project.status == 'completed') return 100;
    if (project.status == 'in_progress') return 50;
    return 0;
  }
}
