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
    await NotificationStore.markAllRead();
    final data = await NotificationStore.getAll();
    if (mounted) setState(() => items = data);
  }

  Future<void> _delete(String time) async {
    items.removeWhere((n) => n['time'] == time);
    await NotificationStore.replace(items);
    if (mounted) setState(() {});
  }

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
      return const Scaffold(
        body: Center(child: Text('No notifications 🔕')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          _group('Today', _isToday),
          _group('Yesterday', _isYesterday),
          _group('Earlier', (d) => !_isToday(d) && !_isYesterday(d)),
        ],
      ),
    );
  }

  Widget _group(String title, bool Function(DateTime) match) {
    final g = items.where((n) => match(DateTime.parse(n['time']))).toList();
    if (g.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey)),
        ),
        ...g.map((n) => Dismissible(
              key: ValueKey(n['time']),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _delete(n['time']),
              child: ListTile(
                title: Text(n['title']),
                subtitle: Text(n['body']),
                trailing:
                    Text(_formatTime(DateTime.parse(n['time']))),
              ),
            )),
      ],
    );
  }
}
