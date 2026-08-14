import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String donationId;
  final String currentUserId;
  final String recipientId;

  const ChatScreen({
    super.key,
    required this.donationId,
    required this.currentUserId,
    required this.recipientId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetch();
    // Auto-refresh chat messages every 3 seconds for real-time messaging experience!
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetch());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await ApiService.get('/chat/${widget.donationId}');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body)['data'] ?? [];
        if (mounted) {
          setState(() {
            _messages = data;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();

    try {
      final res = await ApiService.post('/chat', {
        'donationId': widget.donationId,
        'senderId': widget.currentUserId,
        'receiverId': widget.recipientId,
        'recipientId': widget.recipientId,
        'text': text,
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        NotificationService().addChatNotification(
          title: '💬 1-on-1 Chat Message Sent',
          body: text,
        );
        await _fetch();
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent + 60,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Direct 1-on-1 Chat'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              '🔒 Direct Chat Active: Coordinate pickup timing, location, and item details safely.',
              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Send a message below to start coordinating!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (c, i) {
                          final msg = _messages[i];
                          final isMe = msg['senderId'] == widget.currentUserId;
                          return Align(
                            alignment:
                                isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.green.shade700
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.green.shade800,
                  onPressed: _send,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
