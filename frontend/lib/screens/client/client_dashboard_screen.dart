// screens/client/client_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/project_model.dart';
import 'create_project_screen.dart';
import 'project_proposals_screen.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  List<Project> myProjects = [];
  bool loading = true;

  List<Map<String, dynamic>> aiSuggestions = [];
  bool loadingSuggestions = true;

  Future<void> fetchAISuggestions() async {
    try {
      final openProject = myProjects.firstWhere(
        (p) => p.status == 'open',
        orElse: () => Project(),
      );

      if (openProject.id != null) {
        final result = await ApiService.getSuggestedFreelancers(
          openProject.id!,
        );
        setState(() {
          if (result['success'] == true) {
            aiSuggestions = List<Map<String, dynamic>>.from(
              result['suggestions'],
            );
          }
          loadingSuggestions = false;
        });
      } else {
        setState(() => loadingSuggestions = false);
      }
    } catch (e) {
      print('Error fetching AI suggestions: $e');
      setState(() => loadingSuggestions = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMyProjects().then((_) => fetchAISuggestions());
  }

  Future<void> fetchMyProjects() async {
    setState(() => loading = true);

    try {
      final data = await ApiService.getMyProjects2();

      setState(() {
        myProjects = data
            .map((json) {
              try {
                return Project.fromJson(json);
              } catch (e) {
                print('Error parsing project: $e');
                return null;
              }
            })
            .whereType<Project>()
            .toList();
              loading = false;
      });

      await fetchAISuggestions();
    } catch (e) {
      print('Error fetching projects: $e');
      setState(() {
        myProjects = [];
        loading = false;
      });
    }
  }

  int getProjectStats(String status) {
    return myProjects.where((p) => p.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Client Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xff14A800),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
              ).then((_) => fetchMyProjects());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await ApiService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchMyProjects,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                          "Open Projects",
                          getProjectStats('open').toString(),
                          Icons.folder_open,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          "In Progress",
                          getProjectStats('in_progress').toString(),
                          Icons.engineering,
                          Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          "Completed",
                          getProjectStats('completed').toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (!loadingSuggestions && aiSuggestions.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.amber.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "AI Recommended Freelancers 🤖",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: aiSuggestions.length,
                          itemBuilder: (context, index) {
                            final freelancer = aiSuggestions[index];
                            return _buildAIFreelancerCard(freelancer);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            "Post New Project",
                            Icons.add_circle,
                            Color(0xff14A800),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateProjectScreen(),
                                ),
                              ).then((_) => fetchMyProjects());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            "Find Freelancers",
                            Icons.search,
                            Colors.blue,
                            () {
                              Navigator.pushNamed(context, '/projects');
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "My Projects",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text("View All"),
                        ),
                      ],
                    ),

               
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            "My Contracts",
                            Icons.description,
                            Colors.purple,
                            () {
                              Navigator.pushNamed(
                                context,
                                '/my-contracts',
                                arguments: 'client', 
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (myProjects.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No projects yet",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreateProjectScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff14A800),
                              ),
                              child: const Text("Create Your First Project"),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myProjects.length > 3
                            ? 3
                            : myProjects.length,
                        itemBuilder: (context, index) {
                          final project = myProjects[index];
                          return _buildProjectCard(project);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAIFreelancerCard(Map<String, dynamic> freelancer) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueGrey.shade300,
                backgroundImage: freelancer['avatar'] != null
                    ? NetworkImage(
                        'http://localhost:5000${freelancer['avatar']}',
                      )
                    : null,
                child: freelancer['avatar'] == null
                    ? Text(
                        freelancer['name']?[0].toUpperCase() ?? 'F',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      freelancer['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      freelancer['title'] ?? 'Freelancer',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMatchColor(
                    freelancer['matchScore'],
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${freelancer['matchScore']}%',
                  style: TextStyle(
                    color: _getMatchColor(freelancer['matchScore']),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (freelancer['skills'] as List).take(3).map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  skill,
                  style: TextStyle(fontSize: 9, color: Colors.blue.shade700),
                ),
              );
            }).toList(),
          ),
          const Spacer(),

          Row(
            children: [
              Icon(Icons.star, size: 14, color: Colors.amber.shade600),
              const SizedBox(width: 2),
              Text(
                freelancer['rating']?.toStringAsFixed(1) ?? '0.0',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(width: 8),
              Icon(Icons.work, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 2),
              Text(
                '${freelancer['experience']} yrs',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: View freelancer profile
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff14A800),
                side: const BorderSide(color: Color(0xff14A800)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text("View Profile", style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMatchColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.blue;
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    Color statusColor;
    String statusText;

    switch (project.status) {
      case 'open':
        statusColor = Colors.blue;
        statusText = 'Open';
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.grey;
        statusText = project.status ?? 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.description ?? 'No description',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
              Text(
                '\$${project.budget?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              Text(
                '${project.duration ?? 0} days',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProjectProposalsScreen(projectId: project.id!),
                    ),
                  );
                },
                child: const Text("View Proposals"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
