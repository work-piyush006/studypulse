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
  }

  Future<void> _load() async {
    final data = await NotificationStore.getAll();

    // 🔥 Mark all as read when inbox opens
    await NotificationStore.markAllRead();

    setState(() => items = data);
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear notifications?'),
        content: const Text(
          'This will permanently delete all notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotificationStore.clear();
      setState(() => items.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet 🔕',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) {
                final n = items[i];
                final bool unread = n['read'] == false;

                return ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: unread
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  title: Text(
                    n['title'],
                    style: TextStyle(
                      fontWeight:
                          unread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n['body']),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(n['time']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
