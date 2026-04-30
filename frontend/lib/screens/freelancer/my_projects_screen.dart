// screens/freelancer/my_projects_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/project_model.dart';
import '../../services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../theme/app_theme.dart';
import 'project_details_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        fetchMyProjects(context);
      }
    });
  }

  Future<void> fetchMyProjects(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final data = await ApiService.getMyProjects();

      if (!mounted) return;

      setState(() {
        projects = data.map((json) => Project.fromJson(json)).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      Fluttertoast.showToast(msg: t.errorLoadingProjects);
    }
  }

  String _getStatusText(String? status, AppLocalizations t) {
    switch (status) {
      case 'in_progress':
        return t.inProgress;
      case 'completed':
        return t.completed;
      case 'pending':
        return t.pending;
      default:
        return status ?? t.unknown;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  int _calculateProgress(Project project) {
    if (project.status == 'completed') return 100;
    if (project.status == 'in_progress') return 50;
    return 0;
  }

  void _showSubmitWorkDialog(Project project) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.check_circle, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Text(
              t.submitWork,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          t.submitWorkConfirmation,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t.cancel,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: t.workSubmittedSuccess,
                backgroundColor: AppColors.secondary,
                textColor: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(t.submit),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(Project project) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.chat,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${t.message} ${project.client?.name ?? t.client}',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        content: TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: t.typeYourMessage,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t.cancel,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(msg: t.messageSent);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(t.send),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = _calculateProgress(project);
    final statusColor = _getStatusColor(project.status);
    final statusText = _getStatusText(project.status, t);
    final hasContract = project.contractId != null && project.contractId! > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (hasContract) {
              Navigator.pushNamed(
                context,
                '/contract',
                arguments: {
                  'contractId': project.contractId,
                  'userRole': 'freelancer',
                },
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectDetailsScreen(projectId: project.id!),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (project.budget != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                            Text(
                              project.budget!.toStringAsFixed(0),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  project.title ?? t.untitledProject,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.transparent,
                        backgroundImage:
                            project.client?.avatar != null &&
                                project.client!.avatar!.isNotEmpty
                            ? NetworkImage(project.client!.avatar!)
                            : null,
                        child:
                            project.client?.avatar == null ||
                                project.client!.avatar!.isEmpty
                            ? Text(
                                project.client?.name?[0].toUpperCase() ??
                                    t.client[0],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.client?.name ?? t.unknownClient,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.business_center,
                                size: 12,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t.client,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${project.duration} ${t.days}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.projectProgress,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '$progress%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: progress == 100
                                ? AppColors.secondary
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 100
                              ? AppColors.secondary
                              : theme.colorScheme.primary,
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
                        onPressed: () => _showMessageDialog(project),
                        icon: Icon(
                          Icons.chat_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          t.message,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (hasContract) {
                            final route =
                                (project.contractStatus == 'active' ||
                                    project.status == 'in_progress')
                                ? '/contract/progress'
                                : '/contract';
                            Navigator.pushNamed(
                              context,
                              route,
                              arguments: {
                                'contractId': project.contractId,
                                'userRole': 'freelancer',
                              },
                            );
                            return;
                          }
                          if (project.status == 'completed') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProjectDetailsScreen(
                                  projectId: project.id!,
                                ),
                              ),
                            );
                          } else {
                            _showSubmitWorkDialog(project);
                          }
                        },
                        icon: Icon(
                          hasContract
                              ? Icons.open_in_new
                              : project.status == 'completed'
                              ? Icons.visibility
                              : Icons.check_circle,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          hasContract
                              ? ((project.contractStatus == 'active' ||
                                        project.status == 'in_progress')
                                    ? t.openWorkspace
                                    : t.openContract)
                              : project.status == 'completed'
                              ? t.viewDetails
                              : t.submitWork,
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasContract
                              ? theme.colorScheme.primary
                              : project.status == 'completed'
                              ? theme.colorScheme.primary
                              : AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.myProjects,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => fetchMyProjects(context),
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              tooltip: t.refresh,
            ),
          ),
        ],
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.loadingProjects,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : projects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_open_outlined,
                      size: 50,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.noProjectsYet,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.acceptedProposalsWillAppear,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/freelancer/my-proposals');
                    },
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: Text(t.viewMyProposals),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => fetchMyProjects(context),
              color: theme.colorScheme.primary,
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
}
