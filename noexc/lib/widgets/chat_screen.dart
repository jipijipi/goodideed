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
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadAndDisplayMessages();
  }

  Future<void> _loadAndDisplayMessages() async {
    try {
      _messages = await _chatService.loadChatScript();
      if (!_disposed) {
        _simulateChat();
      }
    } catch (e) {
      if (!_disposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _simulateChat() async {
    if (!_disposed) {
      setState(() {
        _isLoading = false;
      });
    }

    for (int i = 0; i < _messages.length; i++) {
      if (_disposed) break;
      
      await Future.delayed(Duration(milliseconds: _messages[i].delay));
      
      if (!_disposed && mounted) {
        setState(() {
          _displayedMessages.add(_messages[i]);
        });
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
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
    final isBot = message.isFromBot;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 12.0),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isBot 
                    ? Colors.grey[200] 
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 16.0,
                  color: isBot ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 12.0),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}