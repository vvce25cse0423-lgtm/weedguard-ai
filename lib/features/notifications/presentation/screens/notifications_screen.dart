import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<InAppNotificationItem> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final list = await NotificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllAsRead();
    await _loadNotifications();
  }

  Future<void> _sendTestAlert() async {
    await NotificationService.showNotification(
      title: '🌦️ Field Alert: Spray Window Open',
      body:
          'Wind speed: 6 km/h. Temperature: 27°C. Perfect weather conditions for targeted herbicide application.',
      category: 'spray_window',
    );
    await _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent to your phone!'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'all') return true;
      return n.category == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications & Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllRead,
          ),
          IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Send Test Alert to Phone',
            onPressed: _sendTestAlert,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All Alerts', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Spray Windows', 'spray_window'),
                const SizedBox(width: 8),
                _buildFilterChip('Weather Warnings', 'weather'),
                const SizedBox(width: 8),
                _buildFilterChip('Reminders', 'reminder'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notification List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No notifications found',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _sendTestAlert,
                              icon: const Icon(Icons.notifications_active),
                              label: const Text('Send Test Alert to Phone'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildNotificationCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String category) {
    final isSelected = _selectedFilter == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = category);
      },
      selectedColor: const Color(0xFF1B5E20),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildNotificationCard(InAppNotificationItem item) {
    IconData icon;
    Color iconColor;

    switch (item.category) {
      case 'spray_window':
        icon = Icons.wb_sunny_outlined;
        iconColor = Colors.orange.shade700;
        break;
      case 'weather':
        icon = Icons.cloud_outlined;
        iconColor = Colors.blue.shade700;
        break;
      default:
        icon = Icons.eco_outlined;
        iconColor = const Color(0xFF2E7D32);
    }

    return Container(
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRead ? Colors.grey.shade200 : const Color(0xFFA5D6A7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.body,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('dd MMM, hh:mm a').format(item.timestamp),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
