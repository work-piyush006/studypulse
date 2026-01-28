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
    NotificationStore.unreadNotifier.addListener(_load);
  }

  @override
  void dispose() {
    NotificationStore.unreadNotifier.removeListener(_load);
    super.dispose();
  }

  /* ================= LOAD ================= */

  Future<void> _load() async {
    final data = await NotificationStore.getAll();
    if (mounted) setState(() => items = data);
  }

  /* ================= MARK READ ================= */

  Future<void> _markRead(int index) async {
    if (items[index]['read'] == true) return;

    items[index]['read'] = true;
    await NotificationStore.replace(items);
    setState(() {});
  }

  /* ================= MARK ALL READ ================= */

  Future<void> _markAllRead() async {
    await NotificationStore.markAllRead();
    await _load();
  }

  /* ================= CONFIRM CLEAR ================= */

  Future<void> _confirmClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all notifications?'),
        content: const Text(
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      await NotificationStore.clear();
      await _load();
    }
  }

  /* ================= UI ================= */

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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final n = items[i];
          final unread = n['read'] == false;

          final bgColor = unread
              ? isDark
                  ? Colors.yellow.withOpacity(0.18)
                  : Colors.blue.withOpacity(0.14)
              : Theme.of(context).cardColor;

          return Dismissible(
            key: ValueKey(n['time']),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            onDismissed: (_) async {
              await NotificationStore.deleteAt(i);
              await _load();
            },
            child: GestureDetector(
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
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                            style: const TextStyle(
                                color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
