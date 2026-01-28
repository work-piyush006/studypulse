import 'package:flutter/material.dart';
import '../services/notification_store.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends State<NotificationInboxScreen> {
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _load();

    // 🔥 REALTIME refresh when new notification arrives
    NotificationStore.unreadNotifier.addListener(_load);
  }

  @override
  void dispose() {
    NotificationStore.unreadNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    // 👁 Inbox opened → mark all as READ first
    await NotificationStore.markAllRead();

    final data = await NotificationStore.getAll();
    if (mounted) {
      setState(() => items = data);
    }
  }

  /// 🗑️ Delete single notification
  Future<void> _delete(String time) async {
    items.removeWhere((n) => n['time'] == time);
    await NotificationStore.replace(items);

    if (mounted) setState(() {});
  }

  /// ⏰ Manual time formatter (NO intl)
  String _formatTime(DateTime t) {
    int hour = t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$hour:$minute $suffix';
  }

  /// 📅 Date helpers
  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year &&
        d.month == now.month &&
        d.day == now.day;
  }

  bool _isYesterday(DateTime d) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return d.year == y.year &&
        d.month == y.month &&
        d.day == y.day;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text(
            'No notifications yet 🔕',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await NotificationStore.clear();
              if (mounted) setState(() => items.clear());
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildGroup('Today', _isToday),
          _buildGroup('Yesterday', _isYesterday),
          _buildGroup(
            'Earlier',
            (d) => !_isToday(d) && !_isYesterday(d),
          ),
        ],
      ),
    );
  }

  /// 🔹 Group builder
  Widget _buildGroup(
    String title,
    bool Function(DateTime) matcher,
  ) {
    final group = items
        .where((n) => matcher(DateTime.parse(n['time'])))
        .toList();

    if (group.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ...group.map((n) {
            final timeObj = DateTime.parse(n['time']);
            final time = _formatTime(timeObj);

            return Dismissible(
              key: ValueKey(n['time']),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                _delete(n['time']);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification deleted'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(n['title']),
                subtitle: Text(n['body']),
                trailing: Text(
                  time,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
