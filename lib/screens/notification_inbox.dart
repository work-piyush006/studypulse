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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification saved'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  Future<void> _load() async {
    final data = await NotificationStore.getAll();
    if (mounted) setState(() => items = data);
  }

  Future<void> _markRead(int i) async {
    if (items[i]['read'] == true) return;
    items[i]['read'] = true;
    await NotificationStore.replace(items);
    setState(() {});
  }

  Future<void> _markAllRead() async {
    await NotificationStore.markAllRead();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: const Center(
          child: Text('No notifications 🔕'),
        ),
      );
    }

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

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

          final color = unread
              ? isDark
                  ? Colors.yellow.withOpacity(0.18)
                  : Colors.blue.withOpacity(0.15)
              : Theme.of(context).cardColor;

          return GestureDetector(
            onTap: () => _markRead(i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['title'],
                    style: TextStyle(
                      fontWeight:
                          unread ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n['body'],
                    style: const TextStyle(color: Colors.grey),
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
