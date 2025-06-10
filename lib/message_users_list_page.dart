
import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class MessageUsersListPage extends StatefulWidget {
  final int currentUserId;
  final String currentUserUUID;

  const MessageUsersListPage({
    required this.currentUserId,
    required this.currentUserUUID,
    Key? key,
  }) : super(key: key);

  @override
  _MessageUsersListPageState createState() => _MessageUsersListPageState();
}

class _MessageUsersListPageState extends State<MessageUsersListPage> {
  List<dynamic> usersList = [];
  String searchText = '';

  late RealtimeChannel _channel; // القناة

  @override
  void initState() {
    super.initState();
    fetchUsers();
    subscribeToMessages();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_channel);
    super.dispose();
  }

  Future<void> fetchUsers() async {
    final uuid = widget.currentUserUUID;

    final response = await Supabase.instance.client
        .rpc('get_users_with_last_message_and_unread_count', params: {
      'current_uuid': uuid,
    });

    if (!mounted) return;

    setState(() {
      usersList = List.from(response).where((user) {
        return user['user_name']
            .toString()
            .toLowerCase()
            .contains(searchText.toLowerCase());
      }).toList();
    });
  }
void subscribeToMessages() {
  _channel = Supabase.instance.client.channel('public:messages')
    ..onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        // print('New message received: $payload');
        fetchUsers();
      },
    )
    ..onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        // print('Message updated: $payload');
        fetchUsers();
      },
    )
    ..subscribe();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        backgroundColor: colorbar,
        foregroundColor: Colorapp,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                searchText = value;
                fetchUsers();
              },
              decoration: const InputDecoration(
                hintText: 'ابحث عن مستخدم...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: usersList.length,
              itemBuilder: (context, index) {
                final user = usersList[index];
                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(user['photo_url'] ?? ''),
                      ),
                      if (user['unread_count'] != null &&
                          user['unread_count'] > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${user['unread_count']}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(user['user_name']),
                  subtitle: Text(user['farm_code'] ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          code:
                              user['uuid'].compareTo(widget.currentUserUUID) < 0
                                  ? user['uuid'] + widget.currentUserUUID
                                  : widget.currentUserUUID + user['uuid'],
                          receiverName: user['user_name'],
                          receiverImage: user['photo_url'],
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
