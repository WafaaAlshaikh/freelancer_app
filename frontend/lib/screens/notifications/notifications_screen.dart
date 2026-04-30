// lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/notification_model.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  int unreadCount = 0;
  bool loading = true;
  bool isLoadingMore = false;
  int currentPage = 0;
  bool hasMore = true;
  final int pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      currentPage = 0;
      hasMore = true;
      notifications.clear();
    }

    if (!hasMore) return;

    setState(() => loading = refresh ? true : isLoadingMore = true);

    try {
      final offset = currentPage * pageSize;
      final result = await ApiService.getNotifications(
        limit: pageSize,
        offset: offset,
      );

      final newNotifications = (result['notifications'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      setState(() {
        notifications.addAll(newNotifications);
        unreadCount = result['unreadCount'] ?? 0;
        hasMore = newNotifications.length == pageSize;
        currentPage++;
        loading = false;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        isLoadingMore = false;
      });
      final t = AppLocalizations.of(context)!;
      Fluttertoast.showToast(msg: t.errorLoadingNotifications);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final result = await ApiService.getUnreadCount();
      setState(() {
        unreadCount = result['unreadCount'] ?? 0;
      });
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final t = AppLocalizations.of(context)!;
    await ApiService.markAllNotificationsAsRead();
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
      unreadCount = 0;
    });
    Fluttertoast.showToast(msg: t.allNotificationsMarkedAsRead);
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await ApiService.markNotificationAsRead(notification.id);
      setState(() {
        notification.isRead = true;
        unreadCount--;
      });
    }
    _handleNotificationTap(notification);
  }

  void _handleNotificationTap(NotificationModel notification) {
    final data = notification.data;
    final screen = data['screen'];

    switch (screen) {
      case 'contract':
        Navigator.pushNamed(
          context,
          '/contract',
          arguments: {
            'contractId': data['contractId'],
            'userRole': 'freelancer',
          },
        );
        break;
      case 'project_proposals':
        Navigator.pushNamed(
          context,
          '/client/project-proposals',
          arguments: data['projectId'],
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.notifications),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                t.markAllAsRead,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () => _loadNotifications(refresh: true),
              color: theme.colorScheme.primary,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: notifications.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == notifications.length) {
                    return _buildLoadingMore();
                  }
                  return _buildNotificationCard(notifications[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            t.noNotificationsYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.notificationsWillAppearHere,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: () => _markAsRead(notification),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark ? AppColors.infoBg.withOpacity(0.2) : AppColors.infoBg)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? (isDark
                      ? AppColors.info.withOpacity(0.3)
                      : AppColors.info.withOpacity(0.2))
                : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            _buildNotificationIcon(notification.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: isUnread
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: theme.iconTheme.color),
              onPressed: () async {
                await ApiService.deleteNotification(notification.id);
                setState(() {
                  notifications.remove(notification);
                  if (isUnread) unreadCount--;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;

    switch (type) {
      case 'proposal_received':
      case 'proposal_accepted':
      case 'proposal_rejected':
        icon = Icons.assignment;
        color = AppColors.info;
        break;
      case 'contract_signed':
      case 'contract_created':
        icon = Icons.description;
        color = theme.colorScheme.secondary;
        break;
      case 'milestone_due':
      case 'milestone_completed':
        icon = Icons.flag;
        color = AppColors.warning;
        break;
      case 'payment_received':
      case 'payment_released':
        icon = Icons.attach_money;
        color = theme.colorScheme.secondary;
        break;
      case 'message':
        icon = Icons.message;
        color = Colors.purple;
        break;
      case 'new_review':
        icon = Icons.star;
        color = Colors.amber;
        break;
      case 'reminder':
        icon = Icons.alarm;
        color = AppColors.danger;
        break;
      default:
        icon = Icons.notifications;
        color = AppColors.gray;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatDate(DateTime date) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${t?.daysAgo ?? 'd ago'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${t?.hoursAgo ?? 'h ago'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${t?.minutesAgo ?? 'm ago'}';
    } else {
      return t?.justNow ?? 'Just now';
    }
  }

  Widget _buildLoadingMore() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
