import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/choice.dart';
import '../services/chat_service.dart';
import '../services/user_data_service.dart';
import '../services/text_templating_service.dart';
import 'user_variables_panel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final UserDataService _userDataService;
  late final TextTemplatingService _templatingService;
  late final ChatService _chatService;
  List<ChatMessage> _messages = [];
  List<ChatMessage> _displayedMessages = [];
  bool _disposed = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatMessage? _currentTextInputMessage;
  bool _isPanelVisible = false;
  final GlobalKey<UserVariablesPanelState> _panelKey = GlobalKey();
  final List<Timer> _activeTimers = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadAndDisplayMessages();
  }

  void _initializeServices() {
    _userDataService = UserDataService();
    _templatingService = TextTemplatingService(_userDataService);
    _chatService = ChatService(
      userDataService: _userDataService,
      templatingService: _templatingService,
    );
  }

  Future<void> _loadAndDisplayMessages() async {
    try {
      await _chatService.loadChatScript();
      if (!_disposed) {
        _simulateInitialChat();
      }
    } catch (e) {
      // Handle error silently or add error handling as needed
    }
  }

  void _simulateInitialChat() async {
    final initialMessages = await _chatService.getInitialMessages();
    await _displayMessages(initialMessages);
  }

  Future<void> _displayMessages(List<ChatMessage> messages) async {
    // Process templates in messages before displaying
    final processedMessages = await _chatService.processMessageTemplates(messages);
    
    for (ChatMessage message in processedMessages) {
      if (_disposed) break;
      
      // Use Timer instead of Future.delayed for better control
      final completer = Completer<void>();
      final timer = Timer(Duration(milliseconds: message.delay), () {
        if (!_disposed && mounted) {
          setState(() {
            _displayedMessages.add(message);
          });
          
          // Scroll to bottom after adding message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.minScrollExtent,
                duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      completer.complete();
    });
    
    _activeTimers.add(timer);
    await completer.future;
    _activeTimers.remove(timer);
    
    if (_disposed) break;
    
    // Stop at choice messages or text input messages to wait for user interaction
      if (message.isChoice || message.isTextInput) {
        if (message.isTextInput) {
          setState(() {
            _currentTextInputMessage = message;
          });
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    
    // Cancel all active timers
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() {
      _isPanelVisible = !_isPanelVisible;
    });
    if (_isPanelVisible) {
      _panelKey.currentState?.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _togglePanel,
            tooltip: 'My Information',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main chat content
          ListView.builder(
            reverse: true,
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 16.0),
            itemCount: _displayedMessages.length,
            itemBuilder: (context, index) {
              final message = _displayedMessages.reversed.toList()[index];
              return _buildMessageBubble(message);
            },
          ),
          
          // Sliding panel overlay
          if (_isPanelVisible)
            GestureDetector(
              onTap: _togglePanel,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const SizedBox.expand(),
              ),
            ),
          
          // Sliding panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isPanelVisible ? 0 : -400,
            left: 0,
            right: 0,
            height: 400,
            child: GestureDetector(
              onTap: () {}, // Prevent tap from closing panel
              child: UserVariablesPanel(
                key: _panelKey,
                userDataService: _userDataService,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isChoice && message.choices != null) {
      return _buildChoiceBubbles(message);
    }
    if (message.isTextInput && message == _currentTextInputMessage) {
      return _buildTextInputBubble(message);
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
    // Store the user's choice if storeKey is provided
    await _chatService.handleUserChoice(choiceMessage, choice.text);
    
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

  Widget _buildTextInputBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: message.placeholderText,
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) => _onTextInputSubmitted(value, message),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: () => _onTextInputSubmitted(_textController.text, message),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ),
                ],
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
    );
  }

  void _onTextInputSubmitted(String userInput, ChatMessage textInputMessage) async {
    if (userInput.trim().isEmpty) return;

    // Store the user's input if storeKey is provided
    await _chatService.handleUserTextInput(textInputMessage, userInput.trim());

    // Create user response message
    final userResponseMessage = _chatService.createUserResponseMessage(
      textInputMessage.id + 1000, // Use a high ID to avoid conflicts
      userInput.trim(),
    );

    // Replace text input bubble with user response
    setState(() {
      int textInputIndex = _displayedMessages.indexOf(textInputMessage);
      _displayedMessages[textInputIndex] = userResponseMessage;
      _currentTextInputMessage = null;
      _textController.clear();
    });

    // Continue with next messages if available
    if (textInputMessage.nextMessageId != null) {
      await _continueWithTextInput(textInputMessage.nextMessageId!, userInput.trim());
    }
  }

  Future<void> _continueWithTextInput(int nextMessageId, String userInput) async {
    final nextMessages = _chatService.getMessagesAfterTextInput(nextMessageId, userInput);
    await _displayMessages(nextMessages);
  }

}