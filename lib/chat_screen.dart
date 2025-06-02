import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:farmplanning/global.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

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
  String? highlightedMessageId;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<Map<String, dynamic>>> messageStream;
  final fileName = '${const Uuid().v4()}.jpg';
  final Map<String, GlobalKey> _messageKeys = {};

  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _chunks = [];
  bool _isRecording = false;

  Uint8List? pendingAudio;
  String? pendingAudioName;
  Uint8List? pendingImage;
  String? pendingImageName;

  Map<String, dynamic>? replyTo;

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

  Future<void> sendMessage({String? text}) async {
    String? uploadedUrl;

    if (pendingAudio != null && pendingAudioName != null) {
      final response = await Supabase.instance.client.storage
          .from('message')
          .uploadBinary('voice/$pendingAudioName', pendingAudio!);
      if (response.isNotEmpty) {
        uploadedUrl = Supabase.instance.client.storage
            .from('message')
            .getPublicUrl('voice/$pendingAudioName');
      }
      pendingAudio = null;
      pendingAudioName = null;
    }

    if (pendingImage != null && pendingImageName != null) {
      final String uniqueImageName = '${const Uuid().v4()}.jpg';
      final response = await Supabase.instance.client.storage
          .from('message')
          .uploadBinary('uploads/$uniqueImageName', pendingImage!);

      if (response.isNotEmpty) {
        uploadedUrl = Supabase.instance.client.storage
            .from('message')
            .getPublicUrl('uploads/$uniqueImageName');
      }
      pendingImage = null;
      pendingImageName = null;
    }

    if ((text == null || text.trim().isEmpty) && uploadedUrl == null) return;

    await Supabase.instance.client.from('messages').insert({
      'message': text,
      'user_id': widget.currentUserId,
      'code': widget.code,
      'url': uploadedUrl,
      'status': 'sent',
      'reply_to': replyTo?['id']
    });

    replyTo = null;
    _controller.clear();
    setState(() {});
  }

  Future<void> pickAndStoreImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final pickedFile = result.files.single;
      if (pickedFile.bytes != null) {
        pendingImage = pickedFile.bytes!;
        pendingImageName = pickedFile.name;
        setState(() {});
      }
    }
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
    final mediaStream = await html.window.navigator.getUserMedia(audio: true);

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

      pendingAudio = reader.result as Uint8List;
      pendingAudioName = 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';
      setState(() {});
    });

    _mediaRecorder!.start();
    setState(() {
      _isRecording = true;
    });
  }

  Widget buildMessageTile(Map<String, dynamic> msg) {
    final messageKey =
        _messageKeys.putIfAbsent(msg['id'].toString(), () => GlobalKey());

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

        final audioWidget = SizedBox(
          height: 40,
          width: 200,
          child: HtmlElementView(viewType: url),
        );

        // ignore: undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(
          url,
          (int viewId) => audioElement,
        );

        messageContent = Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg['message'] ?? ''),
            const SizedBox(height: 6),
            audioWidget,
          ],
        );
      } else {
        messageContent = Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg['message'] ?? ''),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    return Dialog(
                      backgroundColor: Colors.transparent,
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          InteractiveViewer(
                            child: Image.network(url),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.download,
                                  color: Colors.blue),
                              onPressed: () async {
                                try {
                                  final response =
                                      await http.get(Uri.parse(url));
                                  if (response.statusCode == 200) {
                                    final bytes = response.bodyBytes;
                                    final blob = html.Blob([bytes]);
                                    final blobUrl =
                                        html.Url.createObjectUrlFromBlob(blob);

                                    final anchor =
                                        html.AnchorElement(href: blobUrl)
                                          ..download = 'image.jpg'
                                          ..style.display = 'none';

                                    html.document.body!.append(anchor);
                                    anchor.click();
                                    anchor.remove();
                                    html.Url.revokeObjectUrl(blobUrl);
                                  } else {
                                    print(
                                        'فشل تحميل الصورة: ${response.statusCode}');
                                  }
                                } catch (e) {
                                  print('حدث خطأ أثناء التحميل: $e');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Image.network(url, width: 150),
            ),
          ],
        );
      }
    } else {
      messageContent = Text(msg['message'] ?? '');
    }

    return KeyedSubtree(
      key: _messageKeys[msg['id'].toString()],
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            replyTo = msg;
          });
        },
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // color: isMe ? Colors.green[100] : Colors.grey[200],
              color: highlightedMessageId == msg['id'].toString()
                  ? Colors.yellow[300]
                  : isMe
                      ? Colors.green[100]
                      : Colors.grey[200],

              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (msg['reply_to'] != null)
                  FutureBuilder(
                    future: Supabase.instance.client
                        .from('messages')
                        .select()
                        .eq('id', msg['reply_to'])
                        .maybeSingle(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final replyMsg = snapshot.data!;
                        final replyUrl = replyMsg['url']?.toString();

                        Widget replyPreview;

                        if (replyUrl != null) {
                          if (replyUrl.endsWith('.webm') ||
                              replyUrl.endsWith('.mp3')) {
                            final audioElement = html.AudioElement()
                              ..src = replyUrl
                              ..controls = true
                              ..style.border = 'none';

                            // ignore: undefined_prefixed_name
                            ui.platformViewRegistry.registerViewFactory(
                              'reply_${replyMsg['id']}',
                              (int viewId) => audioElement,
                            );

                            replyPreview = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (replyMsg['message'] != null)
                                  Text(replyMsg['message']),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 40,
                                  width: 200,
                                  child: HtmlElementView(
                                      viewType: 'reply_${replyMsg['id']}'),
                                ),
                              ],
                            );
                          } else {
                            replyPreview = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (replyMsg['message'] != null)
                                  Text(replyMsg['message']),
                                const SizedBox(height: 4),
                                Image.network(replyUrl, width: 100),
                              ],
                            );
                          }
                        } else {
                          replyPreview = Text(replyMsg['message'] ?? '',
                              style:
                                  const TextStyle(fontStyle: FontStyle.italic));
                        }

                        return GestureDetector(
                          onTap: () {
                            final replyKey =
                                _messageKeys[replyMsg['id'].toString()];
                            if (replyKey != null &&
                                replyKey.currentContext != null) {
                              Scrollable.ensureVisible(
                                replyKey.currentContext!,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() {
                                highlightedMessageId =
                                    replyMsg['id'].toString();
                              });
                              Future.delayed(const Duration(seconds: 5), () {
                                setState(() {
                                  highlightedMessageId = null;
                                });
                              });
                            }
                          },

                          // onTap: () {
                          //   final replyKey =
                          //       _messageKeys[replyMsg['id'].toString()];
                          //   if (replyKey != null &&
                          //       replyKey.currentContext != null) {
                          //     Scrollable.ensureVisible(
                          //       replyKey.currentContext!,
                          //       duration: const Duration(milliseconds: 300),
                          //       curve: Curves.easeInOut,
                          //     );
                          //   }
                          // },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: replyPreview,
                          ),
                        );
                      }

                      // if (snapshot.hasData) {
                      //   final replyMsg = snapshot.data!;
                      //   return GestureDetector(
                      //     onTap: () {
                      //       final replyKey =
                      //           _messageKeys[replyMsg['id'].toString()];
                      //       if (replyKey != null &&
                      //           replyKey.currentContext != null) {
                      //         Scrollable.ensureVisible(
                      //           replyKey.currentContext!,
                      //           duration: const Duration(milliseconds: 300),
                      //           curve: Curves.easeInOut,
                      //         );
                      //       }
                      //     },
                      //     child: Container(
                      //       padding: const EdgeInsets.all(6),
                      //       margin: const EdgeInsets.only(bottom: 4),
                      //       decoration: BoxDecoration(
                      //         color: Colors.grey[300],
                      //         borderRadius: BorderRadius.circular(4),
                      //       ),
                      //       child: Text(
                      //         replyMsg['message'] ?? '[ملف]',
                      //         style: const TextStyle(
                      //           fontStyle: FontStyle.italic,
                      //           fontSize: 12,
                      //           decoration: TextDecoration
                      //               .underline, // توضح أنه يمكن الضغط عليه
                      //         ),
                      //       ),
                      //     ),
                      //   );
                      // }

                      return const SizedBox();
                    },
                  ),
                messageContent,
                const SizedBox(height: 4),
                Text(
                  "$time - ${status == 'read' ? 'مقروءة' : status == 'delivered' ? 'تم التسليم' : 'تم الإرسال'}",
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: colorbar,
        foregroundColor: Colorapp,
      ),
      body: Column(
        children: [
          if (replyTo != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[300],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'الرد على: ${replyTo!['message'] ?? '[ملف]'}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        replyTo = null;
                      });
                    },
                  )
                ],
              ),
            ),
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
          // عرض مصغر للملف
          if (pendingImage != null || pendingAudio != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (pendingImage != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.memory(
                          pendingImage!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              pendingImage = null;
                              pendingImageName = null;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (pendingAudio != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.mic, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تسجيل صوتي جاهز للإرسال',
                                style: TextStyle(color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  pendingAudio = null;
                                  pendingAudioName = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: pickAndStoreImage,
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
