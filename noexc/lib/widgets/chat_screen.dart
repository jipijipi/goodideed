import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/choice.dart';
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
      await _chatService.loadChatScript();
      if (!_disposed) {
        _simulateInitialChat();
      }
    } catch (e) {
      if (!_disposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _simulateInitialChat() async {
    if (!_disposed) {
      setState(() {
        _isLoading = false;
      });
    }

    final initialMessages = await _chatService.getInitialMessages();
    await _displayMessages(initialMessages);
  }

  Future<void> _displayMessages(List<ChatMessage> messages) async {
    for (ChatMessage message in messages) {
      if (_disposed) break;
      
      await Future.delayed(Duration(milliseconds: message.delay));
      
      if (!_disposed && mounted) {
        setState(() {
          _displayedMessages.add(message);
        });
      }
      
      // Stop at choice messages to wait for user interaction
      if (message.isChoice) break;
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
    if (message.isChoice && message.choices != null) {
      return _buildChoiceBubbles(message);
    }
    return _buildRegularBubble(message);
  }

  Widget _buildRegularBubble(ChatMessage message) {
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

  Widget _buildChoiceBubbles(ChatMessage message) {
    return Column(
      children: message.choices!.map((choice) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: () => _onChoiceSelected(choice, message),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      choice.text,
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ),
      ).toList(),
    );
  }

  void _onChoiceSelected(Choice choice, ChatMessage choiceMessage) async {
    // Replace choice bubbles with selected text as regular user message
    setState(() {
      int choiceIndex = _displayedMessages.indexOf(choiceMessage);
      _displayedMessages[choiceIndex] = ChatMessage(
        id: choiceMessage.id,
        text: choice.text,
        delay: 0,
        sender: 'user',
        isChoice: false,
      );
    });

    // Continue with branched conversation
    await _continueWithChoice(choice.nextMessageId);
  }

  Future<void> _continueWithChoice(int nextMessageId) async {
    final nextMessages = _chatService.getMessagesAfterChoice(nextMessageId);
    await _displayMessages(nextMessages);
  }
}