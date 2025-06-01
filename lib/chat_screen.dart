
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String code;
  final String receiverName;
  final String receiverImage;
  final int currentUserId;

  const ChatScreen({
    required this.code,
    required this.receiverName,
    required this.receiverImage,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> messages = [];

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    final response = await Supabase.instance.client
        .from('messages')
        .select()
        .eq('code', widget.code)
        .order('created_at', ascending: true);

    setState(() {
      messages = response;
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await Supabase.instance.client.from('messages').insert({
      'message': text,
      'user_id': widget.currentUserId,
      'code': widget.code,
      'url': null,
    });

    _controller.clear();
    await loadMessages();
  }

  Widget buildMessageTile(dynamic msg) {
    bool isMe = msg['user_id'] == widget.currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: msg['url'] != null
            ? (msg['url'].toString().endsWith('.mp3') || msg['url'].toString().endsWith('.wav')
                ? const Icon(Icons.audiotrack)
                : Image.network(msg['url']))
            : Text(msg['message'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: messages.map(buildMessageTile).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: _controller),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sendMessage(_controller.text),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
