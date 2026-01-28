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
    final data = await NotificationStore.getAll();
    setState(() => items = data);
  }

  /// 🗑️ Delete single notification
  Future<void> _delete(int index) async {
    items.removeAt(index);
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
          _buildGroup('Today', (d) => _isToday(d)),
          _buildGroup('Yesterday', (d) => _isYesterday(d)),
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
          ...group.asMap().entries.map((entry) {
            final index = items.indexOf(entry.value);
            final n = entry.value;
            final time =
                DateFormat('hh:mm a').format(DateTime.parse(n['time']));

            return Dismissible(
              key: ValueKey(n['time']),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _delete(index),
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
