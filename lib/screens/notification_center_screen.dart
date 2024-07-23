import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/widgets/advanced_widgets.dart';
import 'package:selfcheckoutapp/widgets/responsive_widgets.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';
import 'package:selfcheckoutapp/constants.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  _NotificationCenterScreenState createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<AppNotification> _allNotifications = [];
  List<AppNotification> _unreadNotifications = [];
  List<AppNotification> _readNotifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading notifications
    await Future.delayed(Duration(milliseconds: 1000));

    final notifications = [
      AppNotification(
        id: '1',
        title: 'Welcome to ScanGo!',
        body: 'Get started with our quick guide to make the most of your shopping experience.',
        type: NotificationType.info,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        isRead: false,
        priority: NotificationPriority.high,
        action: 'View Guide',
      ),
      AppNotification(
        id: '2',
        title: 'New Feature Available',
        body: 'Try our improved barcode scanner with faster recognition and better accuracy.',
        type: NotificationType.feature,
        timestamp: DateTime.now().subtract(Duration(hours: 5)),
        isRead: false,
        priority: NotificationPriority.medium,
        action: 'Try Now',
      ),
      AppNotification(
        id: '3',
        title: 'Special Offer - 20% Off',
        body: 'Get 20% off on all dairy products this weekend. Don\'t miss out!',
        type: NotificationType.promotion,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        isRead: true,
        priority: NotificationPriority.high,
        action: 'View Offer',
      ),
      AppNotification(
        id: '4',
        title: 'Payment Successful',
        body: 'Your payment of Rs 1,250.50 has been processed successfully.',
        type: NotificationType.payment,
        timestamp: DateTime.now().subtract(Duration(days: 2)),
        isRead: true,
        priority: NotificationPriority.normal,
        action: 'View Receipt',
      ),
      AppNotification(
        id: '5',
        title: 'Shopping List Reminder',
        body: 'You have 5 items in your shopping list. Don\'t forget to complete your shopping!',
        type: NotificationType.reminder,
        timestamp: DateTime.now().subtract(Duration(days: 3)),
        isRead: true,
        priority: NotificationPriority.low,
        action: 'View List',
      ),
      AppNotification(
        id: '6',
        title: 'App Update Available',
        body: 'Version 1.1.0 is now available with bug fixes and performance improvements.',
        type: NotificationType.system,
        timestamp: DateTime.now().subtract(Duration(days: 4)),
        isRead: true,
        priority: NotificationPriority.medium,
        action: 'Update Now',
      ),
    ];

    setState(() {
      _allNotifications = notifications;
      _unreadNotifications = notifications.where((n) => !n.isRead).toList();
      _readNotifications = notifications.where((n) => n.isRead).toList();
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(String notificationId) async {
    setState(() {
      final notification = _allNotifications.firstWhere((n) => n.id == notificationId);
      notification.isRead = true;
      
      _unreadNotifications.removeWhere((n) => n.id == notificationId);
      if (!_readNotifications.any((n) => n.id == notificationId)) {
        _readNotifications.add(notification);
      }
    });
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final notification in _allNotifications) {
        notification.isRead = true;
      }
      _unreadNotifications.clear();
      _readNotifications = List.from(_allNotifications);
    });
  }

  Future<void> _deleteNotification(String notificationId) async {
    setState(() {
      _allNotifications.removeWhere((n) => n.id == notificationId);
      _unreadNotifications.removeWhere((n) => n.id == notificationId);
      _readNotifications.removeWhere((n) => n.id == notificationId);
    });
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      _allNotifications.clear();
      _unreadNotifications.clear();
      _readNotifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          if (_unreadNotifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.mark_email_read),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          if (_allNotifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear all',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${_allNotifications.length})'),
            Tab(text: 'Unread (${_unreadNotifications.length})'),
            Tab(text: 'Read (${_readNotifications.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(_allNotifications),
                _buildNotificationList(_unreadNotifications),
                _buildNotificationList(_readNotifications),
              ],
            ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return EmptyState(
        title: 'No notifications',
        subtitle: 'You\'re all caught up! Check back later for new updates.',
        icon: Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return NotificationTile(
            notification: notifications[index],
            onTap: () => _handleNotificationTap(notifications[index]),
            onDelete: () => _deleteNotification(notifications[index].id),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    // Handle notification action based on type
    switch (notification.type) {
      case NotificationType.promotion:
        _navigateToPromotion(notification);
        break;
      case NotificationType.payment:
        _navigateToPaymentDetails(notification);
        break;
      case NotificationType.reminder:
        _navigateToShoppingList(notification);
        break;
      case NotificationType.feature:
        _showFeatureDetails(notification);
        break;
      case NotificationType.system:
        _showSystemUpdate(notification);
        break;
      case NotificationType.info:
      default:
        _showNotificationDetails(notification);
        break;
    }
  }

  void _navigateToPromotion(AppNotification notification) {
    AppUtils.showSnackBar(context, 'Navigating to promotion...');
  }

  void _navigateToPaymentDetails(AppNotification notification) {
    AppUtils.showSnackBar(context, 'Navigating to payment details...');
  }

  void _navigateToShoppingList(AppNotification notification) {
    AppUtils.showSnackBar(context, 'Navigating to shopping list...');
  }

  void _showFeatureDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            SizedBox(height: 16),
            Text(
              'This feature includes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Faster barcode scanning'),
            Text('• Improved accuracy'),
            Text('• Better low-light performance'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppUtils.showSnackBar(context, 'Opening feature...');
            },
            child: Text('Try Now'),
          ),
        ],
      ),
    );
  }

  void _showSystemUpdate(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            SizedBox(height: 16),
            Text(
              'What\'s new in v1.1.0:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Bug fixes and performance improvements'),
            Text('• Enhanced user interface'),
            Text('• New search filters'),
            Text('• Improved offline support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppUtils.showSnackBar(context, 'Starting update...');
            },
            child: Text('Update Now'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  AppUtils.getRelativeTime(notification.timestamp),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.label, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  notification.type.name.toUpperCase(),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (notification.action != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleNotificationTap(notification);
              },
              child: Text(notification.action!),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Constants.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead 
              ? Border.all(color: Colors.grey[200]!)
              : Border.all(color: Constants.primaryColor.withOpacity(0.3)),
        ),
        child: Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => onDelete(),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getNotificationColor(notification.type).withOpacity(0.1),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      color: notification.isRead ? Colors.black87 : Colors.black,
                    ),
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Constants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  notification.body,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      AppUtils.getRelativeTime(notification.timestamp),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 12),
                    StatusBadge(
                      status: notification.priority.name,
                      color: _getPriorityColor(notification.priority),
                      fontSize: 8,
                    ),
                  ],
                ),
              ],
            ),
            trailing: notification.action != null
                ? OutlinedButton(
                    onPressed: onTap,
                    child: Text(
                      notification.action!,
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.promotion:
        return Colors.orange;
      case NotificationType.payment:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.blue;
      case NotificationType.feature:
        return Colors.purple;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.info:
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.feature:
        return Icons.new_releases;
      case NotificationType.system:
        return Icons.system_update;
      case NotificationType.info:
      default:
        return Icons.info;
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Colors.red;
      case NotificationPriority.medium:
        return Colors.orange;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.low:
      default:
        return Colors.grey;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final NotificationPriority priority;
  final String? action;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    required this.priority,
    this.action,
  });
}

enum NotificationType {
  info,
  promotion,
  payment,
  reminder,
  feature,
  system,
}

enum NotificationPriority {
  high,
  medium,
  normal,
  low,
}
