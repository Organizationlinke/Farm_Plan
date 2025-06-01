
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class MessageUsersListPage extends StatefulWidget {
  final int currentUserId;
  final String currentUserUUID;

  const MessageUsersListPage({required this.currentUserId, required this.currentUserUUID, Key? key}) : super(key: key);

  @override
  _MessageUsersListPageState createState() => _MessageUsersListPageState();
}

class _MessageUsersListPageState extends State<MessageUsersListPage> {
  List<dynamic> usersList = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await Supabase.instance.client
        .from('message_list')
        .select()
        .ilike('code', '%${widget.currentUserUUID}%')
        .ilike('user_name', '%$searchText%');

    setState(() {
      usersList = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات')),
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
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['photo_url'] ?? ''),
                  ),
                  title: Text(user['user_name']),
                  subtitle: Text(user['farm_code'] ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          code: user['code'],
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
