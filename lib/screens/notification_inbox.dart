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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: items.isEmpty
            ? const ListView(
                children: [
                  SizedBox(height: 200),
                  Center(child: Text('No notifications 🔕')),
                ],
              )
            : ListView(
                children: [
                  _group('Today', _isToday),
                  _group('Yesterday', _isYesterday),
                  _group('Earlier',
                      (d) => !_isToday(d) && !_isYesterday(d)),
                ],
              ),
      ),
    );
  }

  Widget _group(String title, bool Function(DateTime) match) {
    final g = items.where((n) => match(DateTime.parse(n['time']))).toList();
    if (g.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: g.map((n) => ListTile(
        title: Text(n['title']),
        subtitle: Text(n['body']),
      )).toList(),
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  bool _isYesterday(DateTime d) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return d.year == y.year && d.month == y.month && d.day == y.day;
  }
}
