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

    // 🔔 Realtime refresh when new notification saved
    NotificationStore.unreadNotifier.addListener(_load);
  }

  @override
  void dispose() {
    NotificationStore.unreadNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final data = await NotificationStore.getAll();
    if (mounted) setState(() => items = data);
  }

  /// 👁️ Mark single as read
  Future<void> _markRead(int index) async {
    if (items[index]['read'] == true) return;

    items[index]['read'] = true;
    await NotificationStore.replace(items);
    setState(() {});
  }

  /// ✅ Mark all as read
  Future<void> _markAllRead() async {
    await NotificationStore.markAllRead();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text(
            'No notifications 🔕',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final n = items[i];
          final unread = n['read'] == false;

          // 🎨 Unread highlight logic
          final bgColor = unread
              ? isDark
                  ? Colors.yellow.withOpacity(0.18)
                  : Colors.blue.withOpacity(0.14)
              : Theme.of(context).cardColor;

          return GestureDetector(
            onTap: () => _markRead(i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notifications,
                    color: unread
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n['title'],
                          style: TextStyle(
                            fontWeight: unread
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n['body'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
