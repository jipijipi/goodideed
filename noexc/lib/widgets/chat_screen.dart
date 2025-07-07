import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/choice.dart';
import '../services/chat_service.dart';
import '../services/user_data_service.dart';
import '../services/text_templating_service.dart';
import '../constants/ui_constants.dart';
import '../constants/app_constants.dart';
import '../config/chat_config.dart';
import '../constants/theme_constants.dart';
import 'user_variables_panel.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  
  const ChatScreen({super.key, this.onThemeToggle});

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
                duration: UIConstants.scrollAnimationDuration,
              curve: UIConstants.scrollAnimationCurve,
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
        title: const Text(ChatConfig.chatScreenTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onThemeToggle,
            tooltip: ChatConfig.toggleThemeTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _togglePanel,
            tooltip: ChatConfig.userInfoTooltip,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main chat content
          ListView.builder(
            reverse: true,
            controller: _scrollController,
            padding: UIConstants.chatListPadding,
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
                color: Colors.black.withOpacity(UIConstants.overlayOpacity),
                child: const SizedBox.expand(),
              ),
            ),
          
          // Sliding panel
          AnimatedPositioned(
            duration: UIConstants.panelAnimationDuration,
            curve: UIConstants.panelAnimationCurve,
            bottom: _isPanelVisible ? 0 : -UIConstants.panelHeight,
            left: 0,
            right: 0,
            height: UIConstants.panelHeight,
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
      padding: UIConstants.messageBubbleMargin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.smart_toy, color: ThemeConstants.avatarIconColor),
            ),
            const SizedBox(width: UIConstants.avatarSpacing),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * UIConstants.messageMaxWidthFactor,
              ),
              padding: UIConstants.messageBubblePadding,
              decoration: BoxDecoration(
                color: isBot 
                    ? ThemeConstants.botMessageBackgroundLight 
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(UIConstants.messageBubbleRadius),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: UIConstants.messageFontSize,
                  color: isBot ? ThemeConstants.botMessageTextColor : ThemeConstants.userMessageTextColor,
                ),
              ),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: UIConstants.avatarSpacing),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, color: ThemeConstants.avatarIconColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceBubbles(ChatMessage message) {
    final bool hasSelection = message.selectedChoiceText != null;
    
    return Column(
      children: message.choices!.map((choice) {
        final bool isSelected = message.selectedChoiceText == choice.text;
        final bool isUnselected = hasSelection && !isSelected;
        
        return Padding(
          padding: UIConstants.choiceButtonMargin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: hasSelection ? null : () => _onChoiceSelected(choice, message),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * UIConstants.messageMaxWidthFactor,
                    ),
                    padding: UIConstants.messageBubblePadding,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : isUnselected
                              ? Theme.of(context).colorScheme.primary.withOpacity(UIConstants.unselectedChoiceOpacity)
                              : Theme.of(context).colorScheme.primary.withOpacity(UIConstants.selectedChoiceOpacity),
                      borderRadius: BorderRadius.circular(UIConstants.messageBubbleRadius),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        width: isSelected ? UIConstants.selectedChoiceBorderWidth : UIConstants.unselectedChoiceBorderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            choice.text,
                            style: TextStyle(
                              fontSize: UIConstants.messageFontSize,
                              color: isUnselected ? ThemeConstants.userMessageTextColor.withOpacity(UIConstants.unselectedTextOpacity) : ThemeConstants.userMessageTextColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: UIConstants.iconSpacing),
                          const Icon(
                            Icons.check_circle,
                            color: ThemeConstants.userMessageTextColor,
                            size: UIConstants.checkIconSize,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: UIConstants.avatarSpacing),
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.person, color: ThemeConstants.avatarIconColor),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _onChoiceSelected(Choice choice, ChatMessage choiceMessage) async {
    // Store the user's choice if storeKey is provided
    await _chatService.handleUserChoice(choiceMessage, choice.text);
    
    // Update choice message to mark the selected choice and disable interaction
    setState(() {
      int choiceIndex = _displayedMessages.indexOf(choiceMessage);
      _displayedMessages[choiceIndex] = ChatMessage(
        id: choiceMessage.id,
        text: choiceMessage.text,
        delay: choiceMessage.delay,
        sender: choiceMessage.sender,
        isChoice: true, // Keep as choice message
        choices: choiceMessage.choices,
        nextMessageId: choiceMessage.nextMessageId,
        storeKey: choiceMessage.storeKey,
        placeholderText: choiceMessage.placeholderText,
        selectedChoiceText: choice.text, // Mark which choice was selected
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
      padding: UIConstants.messageBubbleMargin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * UIConstants.messageMaxWidthFactor,
              ),
              padding: UIConstants.messageBubblePadding,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(UIConstants.messageBubbleRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: ThemeConstants.userMessageTextColor),
                      decoration: InputDecoration(
                        hintText: message.placeholderText,
                        hintStyle: const TextStyle(color: ThemeConstants.hintTextColor),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) => _onTextInputSubmitted(value, message),
                    ),
                  ),
                  const SizedBox(width: UIConstants.iconSpacing),
                  GestureDetector(
                    onTap: () => _onTextInputSubmitted(_textController.text, message),
                    child: const Icon(
                      Icons.send,
                      color: ThemeConstants.userMessageTextColor,
                      size: UIConstants.sendIconSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: UIConstants.avatarSpacing),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.person, color: ThemeConstants.avatarIconColor),
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
      textInputMessage.id + AppConstants.userResponseIdOffset, // Use a high ID to avoid conflicts
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