// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../models/notification_model.dart';

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
      Fluttertoast.showToast(msg: 'Error loading notifications');
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
    await ApiService.markAllNotificationsAsRead();
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true; 
      }
      unreadCount = 0;
    });
    Fluttertoast.showToast(msg: 'All notifications marked as read');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadNotifications(refresh: true),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you receive notifications, they will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = !notification.isRead;
    
    return GestureDetector(
      onTap: () => _markAsRead(notification),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? Colors.blue.shade200 : Colors.grey.shade200,
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
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xff14A800),
                  shape: BoxShape.circle,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
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
    IconData icon;
    Color color;

    switch (type) {
      case 'proposal_received':
      case 'proposal_accepted':
      case 'proposal_rejected':
        icon = Icons.assignment;
        color = Colors.blue;
        break;
      case 'contract_signed':
      case 'contract_created':
        icon = Icons.description;
        color = Colors.green;
        break;
      case 'milestone_due':
      case 'milestone_completed':
        icon = Icons.flag;
        color = Colors.orange;
        break;
      case 'payment_received':
      case 'payment_released':
        icon = Icons.attach_money;
        color = Colors.green;
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
        color = Colors.red;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
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
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}