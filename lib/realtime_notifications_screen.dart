import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows real-time notifications when somebody likes the current user’s post.
/// All data comes from the `public.notifications` table with `type = 'like'`.
/// Each row joins the sender profile so we can display their avatar.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _supabase = Supabase.instance.client;
  late final RealtimeChannel _channel;
  bool _loading = true;
  final List<_LikeNotification> _items = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _subscribeRealtime();
  }

  Future<void> _loadInitial() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final data = await _supabase
        .from('notifications')
        .select(
            'id, created_at, from_user:from_user_id(username, avatar_url)')
        .eq('to_user_id', user.id)
        .eq('type', 'like')
        .order('created_at', ascending: false);
    setState(() {
      _items.addAll((data as List<dynamic>)
          .map((e) => _LikeNotification.fromJson(e))
          .toList());
      _loading = false;
    });
  }

  void _subscribeRealtime() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    _channel = _supabase
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'to_user_id', value: uid),
          callback: (payload) {
            final rec = payload.newRecord;
            if (rec['type'] == 'like') {
              setState(() {
                _items.insert(0, _LikeNotification.fromJson(rec));
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xff14c1e1),
          elevation: 0,
          centerTitle: true,
          title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No notifications yet'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final n = _items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundImage: n.avatarUrl != null && n.avatarUrl!.isNotEmpty
                            ? NetworkImage(n.avatarUrl!)
                            : const AssetImage('graphics/Profile Icon.png')
                                as ImageProvider,
                      ),
                      title: Row(
                        children: [
                          Text(n.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Image.asset('graphics/Verified Icon.png', width: 13, height: 13),
                        ],
                      ),
                      subtitle: const Text('Liked your post!', style: TextStyle(color: Colors.grey)),
                    );
                  },
                ),
    );
  }
}

class _LikeNotification {
  final String id;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;

  _LikeNotification({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.createdAt,
  });

  factory _LikeNotification.fromJson(Map<String, dynamic> json) {
    return _LikeNotification(
      id: json['id'].toString(),
      username: (json['from_user']?['username'] ?? 'Someone').toString(),
      avatarUrl: json['from_user']?['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
