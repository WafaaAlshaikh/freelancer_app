// screens/workspace/project_workspace_screen.dart
import 'package:flutter/material.dart';
import '../contract/contract_screen.dart';

class ProjectWorkspaceScreen extends StatelessWidget {
  final int contractId;
  final String userRole;

  const ProjectWorkspaceScreen({
    super.key,
    required this.contractId,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Project Workspace'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.flag), text: 'Milestones'),
              Tab(icon: Icon(Icons.folder), text: 'Files'),
              Tab(icon: Icon(Icons.chat), text: 'Chat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ContractScreen(
              contractId: contractId,
              userRole: userRole,
            ),
            _buildFilesTab(),
            _buildChatTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesTab() {
    return const Center(
      child: Text('Files section coming soon...'),
    );
  }

  Widget _buildChatTab() {
    // TODO: إضافة شاشة المحادثة المخصصة للمشروع
    return const Center(
      child: Text('Chat section coming soon...'),
    );
  }
}