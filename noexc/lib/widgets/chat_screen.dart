import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  List<ChatMessage> _messages = [];
  List<ChatMessage> _displayedMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndDisplayMessages();
  }

  Future<void> _loadAndDisplayMessages() async {
    try {
      _messages = await _chatService.loadChatScript();
      _simulateChat();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _simulateChat() async {
    setState(() {
      _isLoading = false;
    });

    for (int i = 0; i < _messages.length; i++) {
      await Future.delayed(Duration(milliseconds: _messages[i].delay));
      if (mounted) {
        setState(() {
          _displayedMessages.add(_messages[i]);
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _displayedMessages.length,
              itemBuilder: (context, index) {
                final message = _displayedMessages[index];
                return _buildMessageBubble(message);
              },
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.chat_bubble, color: Colors.white),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  message.timestamp,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}