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

  Future<void> _load() async {
    final data = await NotificationStore.getAll();
    if (mounted) setState(() => items = data);
  }

  /// 👁️ Mark single as read
  Future<void> _markRead(String time) async {
    final index = items.indexWhere((n) => n['time'] == time);
    if (index == -1) return;

    if (items[index]['read'] == false) {
      items[index]['read'] = true;
      await NotificationStore.replace(items);
      setState(() {});
    }
  }

  /// ✅ Mark all as read
  Future<void> _markAllRead() async {
    await NotificationStore.markAllRead();
    await _load();
  }

  /// 🗑 Delete
  Future<void> _delete(String time) async {
    items.removeWhere((n) => n['time'] == time);
    await NotificationStore.replace(items);
    if (mounted) setState(() {});
  }

  /// ⏰ Manual formatter
  String _formatTime(DateTime t) {
    int h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final s = h >= 12 ? 'PM' : 'AM';
    h = h % 12 == 0 ? 12 : h % 12;
    return '$h:$m $s';
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  bool _isYesterday(DateTime d) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return d.year == y.year && d.month == y.month && d.day == y.day;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text('No notifications 🔕'),
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            _group('Today', _isToday),
            _group('Yesterday', _isYesterday),
            _group('Earlier', (d) => !_isToday(d) && !_isYesterday(d)),
          ],
        ),
      ),
    );
  }

  /// 🔹 Group builder
  Widget _group(String title, bool Function(DateTime) match) {
    final group =
        items.where((n) => match(DateTime.parse(n['time']))).toList();
    if (group.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        ...group.map((n) {
          final time = DateTime.parse(n['time']);
          final unread = n['read'] == false;
          final isDark =
              Theme.of(context).brightness == Brightness.dark;

          /// 🎨 TILE COLOR LOGIC
          final tileColor = unread
              ? isDark
                  ? Colors.yellow.withOpacity(0.15)
                  : Colors.blue.withOpacity(0.12)
              : Theme.of(context).cardColor;

          return Dismissible(
            key: ValueKey(n['time']),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _delete(n['time']),
            child: GestureDetector(
              onTap: () => _markRead(n['time']),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications,
                        color: unread
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey),
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
                    Text(
                      _formatTime(time),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
