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
  List<Map<String, dynamic>> today = [];
  List<Map<String, dynamic>> earlier = [];

  bool _loading = true;

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

  /* ================= LOAD & GROUP ================= */

  Future<void> _load() async {
    final data = await NotificationStore.getAll();
    final now = DateTime.now();

    final t = <Map<String, dynamic>>[];
    final e = <Map<String, dynamic>>[];

    for (final n in data) {
      final time = DateTime.tryParse(n['time'] ?? '');
      if (time == null) continue;

      final isToday =
          time.year == now.year &&
          time.month == now.month &&
          time.day == now.day;

      isToday ? t.add(n) : e.add(n);
    }

    if (!mounted) return;
    setState(() {
      today = t;
      earlier = e;
      _loading = false;
    });
  }

  /* ================= TAP ================= */

  Future<void> _open(Map<String, dynamic> n) async {
    if (n['read'] != true) {
      n['read'] = true;

      // 🔒 Always resync full list
      final all = await NotificationStore.getAll();
      await NotificationStore.replace(all);
    }

    final route = n['route'];
    if (route != null && mounted) {
      Navigator.pushNamed(context, route);
    }
  }

  /* ================= UI HELPERS ================= */

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );

  Widget _item(Map<String, dynamic> n) {
    final unread = n['read'] == false;

    return ListTile(
      leading: Icon(
        unread
            ? Icons.notifications_active
            : Icons.notifications_none,
        color: unread
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
      ),
      title: Text(
        n['title'],
        style: TextStyle(
          fontWeight:
              unread ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        n['body'],
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _open(n),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (today.isEmpty && earlier.isEmpty) {
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
          TextButton(
            onPressed: () async {
              await NotificationStore.markAllRead();
              await _load();
            },
            child: const Text('Mark all read'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await NotificationStore.clear();
              await _load();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (today.isNotEmpty) _section('Today'),
          ...today.map(_item),
          if (earlier.isNotEmpty) _section('Earlier'),
          ...earlier.map(_item),
        ],
      ),
    );
  }
}
