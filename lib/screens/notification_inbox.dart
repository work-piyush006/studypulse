import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    // 👁 Inbox opened → mark all as READ
    await NotificationStore.markAllRead();

    // 🔄 Reload fresh data
    final data = await NotificationStore.getAll();
    setState(() => items = data);
  }

  /// 🗑️ Delete single notification (swipe left)
  Future<void> _delete(String time, String title) async {
    items.removeWhere(
      (n) => n['time'] == time && n['title'] == title,
    );
    await NotificationStore.replace(items);
    setState(() {});
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
              setState(() => items.clear());
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
            final time =
                DateFormat('hh:mm a').format(timeObj);

            return Dismissible(
              key: ValueKey(n['time'] + n['title']), // 🔥 SAFE KEY
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) =>
                  _delete(n['time'], n['title']),
              child: ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(n['title']),
                subtitle: Text(n['body']),
                trailing: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
