
// // import 'dart:async';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import 'package:record/record.dart';
// // import 'package:path_provider/path_provider.dart';

// // class ChatScreen extends StatefulWidget {
// //   final String code;
// //   final String receiverName;
// //   final String receiverImage;
// //   final int currentUserId;

// //   const ChatScreen({
// //     required this.code,
// //     required this.receiverName,
// //     required this.receiverImage,
// //     required this.currentUserId,
// //     Key? key,
// //   }) : super(key: key);

// //   @override
// //   _ChatScreenState createState() => _ChatScreenState();
// // }

// // class _ChatScreenState extends State<ChatScreen> {
// //   final TextEditingController _controller = TextEditingController();
// //   final ScrollController _scrollController = ScrollController();
// //   late final Stream<List<Map<String, dynamic>>> messageStream;
// //   StreamSubscription? _messageSubscription; // <-- هنا بتحطه
// //   final Record _record = Record();
// //   bool _isRecording = false;


// //   @override
// //   void initState() {
// //     super.initState();

// //     // subscribeToMessages();
// //     messageStream = Supabase.instance.client
// //         .from('messages')
// //         .stream(primaryKey: ['id'])
// //         .eq('code', widget.code)
// //         .order('created_at')
// //         .map((event) => event);
// //     markMessagesAsRead();
// //   }

// //   @override
// //   void dispose() {
// //     _controller.dispose();
// //     _messageSubscription?.cancel();
// //     super.dispose();
// //   }

// //   Future<void> _toggleRecording() async {
// //     if (_isRecording) {
// //       // ⛔ إيقاف التسجيل
// //       final path = await _record.stop();
// //       setState(() {
// //         _isRecording = false;
// //       });

// //       if (path != null) {
// //         await _uploadAndSend(path);
// //       }
// //     } else {
// //       // ✅ بدء التسجيل
// //       final hasPermission = await _record.hasPermission();
// //       if (hasPermission) {
// //         final dir = await getTemporaryDirectory();
// //         final filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

// //         await _record.start(
// //           path: filePath,
// //           encoder: AudioEncoder.aacLc,
// //           bitRate: 128000,
// //           samplingRate: 44100,
// //         );

// //         setState(() {
// //           _isRecording = true;
// //         });
// //       }
// //     }
// //   }
// // Future<void> _uploadAndSend(String path) async {
// //     final file = File(path);
// //     final fileName = path.split('/').last;

// //     try {
// //       final bytes = await file.readAsBytes();

// //       final response = await Supabase.instance.client.storage
// //           .from('message') // اسم الـ bucket
// //           .uploadBinary('voice/$fileName', bytes);

// //       final publicUrl = Supabase.instance.client.storage
// //           .from('message')
// //           .getPublicUrl('voice/$fileName');

// //       await sendMessage(url: publicUrl);

// //       print('تم رفع الصوت وإرساله: $publicUrl');
// //     } catch (e) {
// //       print('خطأ في الرفع: $e');
// //     }
// //   }
// //   markMessagesAsRead() async {
// //     await Supabase.instance.client
// //         .from('messages')
// //         .update({'status': 'read'})
// //         .eq('code', widget.code)
// //         .neq('user_id', widget.currentUserId)
// //         .eq('status', 'delivered'); // فقط الرسائل المستلمة
// //   }

// //   Future<void> sendMessage({String? text, String? url}) async {
// //     if ((text == null || text.trim().isEmpty) && url == null) return;

// //     await Supabase.instance.client.from('messages').insert({
// //       'message': text,
// //       'user_id': widget.currentUserId,
// //       'code': widget.code,
// //       'url': url,
// //       'status': 'sent',
// //     });

// //     _controller.clear();
// //     // _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
// //   }

// //   Future<void> pickAndUploadFile() async {
// //     final result = await FilePicker.platform.pickFiles(type: FileType.any);
// //     if (result != null) {
// //       // final file = File(result.files.single.path!);
// //       // final fileName = result.files.single.name;
// // final pickedFile = result.files.single;
// // final fileName = pickedFile.name;
// // if (pickedFile.bytes != null) {
// //   final response = await Supabase.instance.client.storage
// //       .from('message')
// //       .uploadBinary('uploads/$fileName', pickedFile.bytes!);

// //   if (response.isNotEmpty) {
// //     final publicUrl = Supabase.instance.client.storage
// //         .from('message')
// //         .getPublicUrl('uploads/$fileName');
// //     await sendMessage(url: publicUrl);
// //   }
// // }
// //       // final response = await Supabase.instance.client.storage
// //       //     .from('message')
// //       //     .upload('uploads/$fileName', file);

// //       // if (response.isNotEmpty) {
// //       //   final publicUrl = Supabase.instance.client.storage
// //       //       .from('message')
// //       //       .getPublicUrl('uploads/$fileName');
// //       //   await sendMessage(url: publicUrl);
// //       // }
// //     }
// //   }

// //   Widget buildMessageTile(Map<String, dynamic> msg) {
// //     bool isMe = msg['user_id'] == widget.currentUserId;

// //     // إذا لم تكن الرسالة مني ولم تكن "delivered" أو "read"، نحدّثها
// //     if (!isMe && msg['status'] == 'sent') {
// //       Supabase.instance.client
// //           .from('messages')
// //           .update({'status': 'delivered'}).eq('id', msg['id']);
// //     }

// //     final status = msg['status'] ?? 'sent';
// //     final createdAt = msg['created_at'];
// //     final time = createdAt != null
// //         ? DateFormat.Hm().format(DateTime.parse(createdAt))
// //         : '';

// //     return Align(
// //       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
// //         padding: const EdgeInsets.all(10),
// //         decoration: BoxDecoration(
// //           color: isMe ? Colors.green[100] : Colors.grey[200],
// //           borderRadius: BorderRadius.circular(8),
// //         ),
// //         child: Column(
// //           crossAxisAlignment:
// //               isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
// //           children: [
// //             msg['url'] != null
// //                 ? msg['url'].toString().endsWith('.mp3') ||
// //                         msg['url'].toString().endsWith('.wav')
// //                     ? const Icon(Icons.audiotrack)
// //                     : Image.network(msg['url'], width: 150)
// //                 : Text(msg['message'] ?? ''),
// //             const SizedBox(height: 4),
// //             Text(
// //               "$time - ${status == 'read' ? 'مقروءة' : status == 'delivered' ? 'تم التسليم' : 'تم الإرسال'}",
// //               style: TextStyle(fontSize: 10, color: Colors.grey[600]),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

 

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text(widget.receiverName)),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: StreamBuilder<List<Map<String, dynamic>>>(
// //               stream: messageStream,
// //               builder: (context, snapshot) {
// //                 if (!snapshot.hasData) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }
// //                 final messages = snapshot.data!;
// //                 return ListView.builder(
// //                   controller: _scrollController,
// //                   itemCount: messages.length,
// //                   itemBuilder: (context, index) =>
// //                       buildMessageTile(messages[index]),
// //                 );
// //               },
// //             ),
// //           ),
// //           Padding(
// //             padding: const EdgeInsets.all(8.0),
// //             child: Row(
// //               children: [
// //                 IconButton(
// //                   icon: const Icon(Icons.attach_file),
// //                   onPressed: pickAndUploadFile,
// //                 ),
// //                 Expanded(
// //                   child: TextField(
// //                     controller: _controller,
// //                     decoration:
// //                         const InputDecoration(hintText: 'اكتب رسالة...'),
// //                   ),
// //                 ),
// //                 IconButton(
// //                   icon: const Icon(Icons.send),
// //                   onPressed: () => sendMessage(text: _controller.text),
// //                 ),
// //                 IconButton(
// //       icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.red),
// //       onPressed: _toggleRecording,
// //     )
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// import 'dart:async';
// import 'dart:html' as html;
// import 'dart:typed_data';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ChatScreen extends StatefulWidget {
//   final String code;
//   final String receiverName;
//   final String receiverImage;
//   final int currentUserId;

//   const ChatScreen({
//     required this.code,
//     required this.receiverName,
//     required this.receiverImage,
//     required this.currentUserId,
//     Key? key,
//   }) : super(key: key);

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   late final Stream<List<Map<String, dynamic>>> messageStream;

//   html.MediaRecorder? _mediaRecorder;
//   List<html.Blob> _chunks = [];
//   bool _isRecording = false;

//   @override
//   void initState() {
//     super.initState();
//     messageStream = Supabase.instance.client
//         .from('messages')
//         .stream(primaryKey: ['id'])
//         .eq('code', widget.code)
//         .order('created_at')
//         .map((event) => event);
//     markMessagesAsRead();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> markMessagesAsRead() async {
//     await Supabase.instance.client
//         .from('messages')
//         .update({'status': 'read'})
//         .eq('code', widget.code)
//         .neq('user_id', widget.currentUserId)
//         .eq('status', 'delivered');
//   }

//   Future<void> sendMessage({String? text, String? url}) async {
//     if ((text == null || text.trim().isEmpty) && url == null) return;

//     await Supabase.instance.client.from('messages').insert({
//       'message': text,
//       'user_id': widget.currentUserId,
//       'code': widget.code,
//       'url': url,
//       'status': 'sent',
//     });

//     _controller.clear();
//   }

//   Future<void> pickAndUploadFile() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.any);
//     if (result != null) {
//       final pickedFile = result.files.single;
//       final fileName = pickedFile.name;
//       if (pickedFile.bytes != null) {
//         final response = await Supabase.instance.client.storage
//             .from('message')
//             .uploadBinary('uploads/$fileName', pickedFile.bytes!);

//         if (response.isNotEmpty) {
//           final publicUrl = Supabase.instance.client.storage
//               .from('message')
//               .getPublicUrl('uploads/$fileName');
//           await sendMessage(url: publicUrl);
//         }
//       }
//     }
//   }

//   Widget buildMessageTile(Map<String, dynamic> msg) {
//     bool isMe = msg['user_id'] == widget.currentUserId;

//     if (!isMe && msg['status'] == 'sent') {
//       Supabase.instance.client
//           .from('messages')
//           .update({'status': 'delivered'}).eq('id', msg['id']);
//     }

//     final status = msg['status'] ?? 'sent';
//     final createdAt = msg['created_at'];
//     final time = createdAt != null
//         ? DateFormat.Hm().format(DateTime.parse(createdAt))
//         : '';

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.green[100] : Colors.grey[200],
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           crossAxisAlignment:
//               isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//           children: [
//             msg['url'] != null
//                 ? msg['url'].toString().endsWith('.mp3') ||
//                         msg['url'].toString().endsWith('.webm')
//                     ? Column(
//                         children: [
//                           const Icon(Icons.audiotrack),
//                           const SizedBox(height: 5),
//                           TextButton(
//                             onPressed: () {
//                               html.window.open(msg['url'], '_blank');
//                             },
//                             child: const Text('تشغيل الصوت'),
//                           )
//                         ],
//                       )
//                     : Image.network(msg['url'], width: 150)
//                 : Text(msg['message'] ?? ''),
//             const SizedBox(height: 4),
//             Text(
//               "$time - ${status == 'read' ? 'مقروءة' : status == 'delivered' ? 'تم التسليم' : 'تم الإرسال'}",
//               style: TextStyle(fontSize: 10, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _toggleRecording() async {
//     if (_isRecording) {
//       _mediaRecorder?.stop();
//       setState(() {
//         _isRecording = false;
//       });
//     } else {
//       _startRecording();
//     }
//   }

//   Future<void> _startRecording() async {
//     final mediaStream =
//         await html.window.navigator.getUserMedia(audio: true);

//     _chunks.clear();
//     _mediaRecorder = html.MediaRecorder(mediaStream);

//     _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
//       final e = event as html.BlobEvent;
//       // _chunks.add(e.data);
//       if (e.data != null) {
//   _chunks.add(e.data!);
// }
//     });

//     _mediaRecorder!.addEventListener('stop', (event) async {
//       final blob = html.Blob(_chunks, 'audio/webm');
//       final reader = html.FileReader();
//       reader.readAsArrayBuffer(blob);
//       await reader.onLoad.first;

//       final bytes = reader.result as Uint8List;
//       final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';

//       final response = await Supabase.instance.client.storage
//           .from('message')
//           .uploadBinary('voice/$fileName', bytes);

//       if (response.isNotEmpty) {
//         final publicUrl = Supabase.instance.client.storage
//             .from('message')
//             .getPublicUrl('voice/$fileName');
//         await sendMessage(url: publicUrl);
//       }
//     });

//     _mediaRecorder!.start();
//     setState(() {
//       _isRecording = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.receiverName)),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<List<Map<String, dynamic>>>(
//               stream: messageStream,
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final messages = snapshot.data!;
//                 return ListView.builder(
//                   controller: _scrollController,
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) =>
//                       buildMessageTile(messages[index]),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.attach_file),
//                   onPressed: pickAndUploadFile,
//                 ),
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration:
//                         const InputDecoration(hintText: 'اكتب رسالة...'),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: () => sendMessage(text: _controller.text),
//                 ),
//                 IconButton(
//                   icon: Icon(_isRecording ? Icons.stop : Icons.mic,
//                       color: Colors.red),
//                   onPressed: _toggleRecording,
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<Map<String, dynamic>>> messageStream;

  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _chunks = [];
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    messageStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('code', widget.code)
        .order('created_at')
        .map((event) => event);
    markMessagesAsRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> markMessagesAsRead() async {
    await Supabase.instance.client
        .from('messages')
        .update({'status': 'read'})
        .eq('code', widget.code)
        .neq('user_id', widget.currentUserId)
        .eq('status', 'delivered');
  }

  Future<void> sendMessage({String? text, String? url}) async {
    if ((text == null || text.trim().isEmpty) && url == null) return;

    await Supabase.instance.client.from('messages').insert({
      'message': text,
      'user_id': widget.currentUserId,
      'code': widget.code,
      'url': url,
      'status': 'sent',
    });

    _controller.clear();
  }

  Future<void> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      final pickedFile = result.files.single;
      final fileName = pickedFile.name;
      if (pickedFile.bytes != null) {
        final response = await Supabase.instance.client.storage
            .from('message')
            .uploadBinary('uploads/$fileName', pickedFile.bytes!);

        if (response.isNotEmpty) {
          final publicUrl = Supabase.instance.client.storage
              .from('message')
              .getPublicUrl('uploads/$fileName');
          await sendMessage(url: publicUrl);
        }
      }
    }
  }

  Widget buildMessageTile(Map<String, dynamic> msg) {
    bool isMe = msg['user_id'] == widget.currentUserId;

    if (!isMe && msg['status'] == 'sent') {
      Supabase.instance.client
          .from('messages')
          .update({'status': 'delivered'}).eq('id', msg['id']);
    }

    final status = msg['status'] ?? 'sent';
    final createdAt = msg['created_at'];
    final time = createdAt != null
        ? DateFormat.Hm().format(DateTime.parse(createdAt))
        : '';

    Widget messageContent;

    if (msg['url'] != null) {
      final url = msg['url'].toString();
      if (url.endsWith('.mp3') || url.endsWith('.webm')) {
        final audioElement = html.AudioElement()
          ..src = url
          ..controls = true
          ..style.border = 'none';

        // استخدام Widget HTML Element عبر HtmlElementView
        final audioWidget = SizedBox(
          height: 40,
          width: 200,
          child: HtmlElementView(viewType: url),
        );

        // تسجيل عنصر HTML لعرضه داخل Flutter
        // يجب أن يكون هذا فريد لكل رابط صوت
        // ولذلك نستخدم url كـ viewType
        // ignore: undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(
          url,
          (int viewId) => audioElement,
        );

        messageContent = audioWidget;
      } else {
        messageContent = Image.network(url, width: 150);
      }
    } else {
      messageContent = Text(msg['message'] ?? '');
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            messageContent,
            const SizedBox(height: 4),
            Text(
              "$time - ${status == 'read' ? 'مقروءة' : status == 'delivered' ? 'تم التسليم' : 'تم الإرسال'}",
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRecording() async {
    if (_isRecording) {
      _mediaRecorder?.stop();
      setState(() {
        _isRecording = false;
      });
    } else {
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final mediaStream =
        await html.window.navigator.getUserMedia(audio: true);

    _chunks.clear();
    _mediaRecorder = html.MediaRecorder(mediaStream);

    _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
      final e = event as html.BlobEvent;
      if (e.data != null) {
        _chunks.add(e.data!);
      }
    });

    _mediaRecorder!.addEventListener('stop', (event) async {
      final blob = html.Blob(_chunks, 'audio/webm');
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';

      final response = await Supabase.instance.client.storage
          .from('message')
          .uploadBinary('voice/$fileName', bytes);

      if (response.isNotEmpty) {
        final publicUrl = Supabase.instance.client.storage
            .from('message')
            .getPublicUrl('voice/$fileName');
        await sendMessage(url: publicUrl);
      }
    });

    _mediaRecorder!.start();
    setState(() {
      _isRecording = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      buildMessageTile(messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: pickAndUploadFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'اكتب رسالة...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sendMessage(text: _controller.text),
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                      color: Colors.red),
                  onPressed: _toggleRecording,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
