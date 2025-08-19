import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/providers/analytics_provider.dart';
import 'widgets/chat_message.dart';
import 'widgets/message_input.dart';
import 'widgets/enhanced_feedback_dialog.dart';
import 'widgets/typing_indicator.dart';
import 'models/chat_message_model.dart';

final chatMessagesProvider = StateNotifierProvider<ChatNotifier, List<ChatMessageModel>>((ref) {
  return ChatNotifier();
});

final isTypingProvider = StateProvider<bool>((ref) => false);

class ChatNotifier extends StateNotifier<List<ChatMessageModel>> {
  ChatNotifier() : super([]) {
    _loadChatHistory();
  }

  void _loadChatHistory() {
    final history = StorageService.getChatHistory();
    state = history.map((msg) => ChatMessageModel.fromJson(msg)).toList();
  }

  void addMessage(ChatMessageModel message) {
    state = [...state, message];
    StorageService.saveChatMessage(message.toJson());
  }

  void clearMessages() {
    state = [];
    StorageService.clearChatHistory();
  }

  void triggerAnalyticsUpdate(WidgetRef ref) {
    // Trigger analytics refresh after new message
    ref.read(analyticsProvider.notifier).updateAfterNewMessage();
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    ref.read(chatMessagesProvider.notifier).addMessage(userMessage);
    _messageController.clear();
    
    // Show typing indicator
    ref.read(isTypingProvider.notifier).state = true;
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      // Use enhanced message flow (Rasa -> Gemini -> User-friendly response)
      final isEnhancementEnabled = StorageService.isLlmEnhanced;
      final enhancedResult = await ApiService.sendEnhancedMessage(
        message,
        isEnhancementEnabled,
      );
      
      if (enhancedResult['success']) {
        final botResponse = enhancedResult['response'] as String;
        final confidence = (enhancedResult['confidence'] as double?) ?? 0.8;
        final isEnhanced = enhancedResult['is_enhanced'] as bool? ?? false;
        
        print('🤖 Bot Response: $botResponse');
        print('📊 Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
        print('✨ Enhanced: $isEnhanced');
        
        final botMessage = ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: botResponse,
          isUser: false,
          timestamp: DateTime.now(),
          confidence: confidence,
          isEnhanced: isEnhanced,
        );
        
        ref.read(isTypingProvider.notifier).state = false;
        ref.read(chatMessagesProvider.notifier).addMessage(botMessage);
        
        // Update analytics after new message
        ref.read(chatMessagesProvider.notifier).triggerAnalyticsUpdate(ref);
        
        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        // Error handling
        final errorResponse = enhancedResult['response'] as String? ?? 'Sorry, I encountered an error.';
        final errorMessage = ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: errorResponse,
          isUser: false,
          timestamp: DateTime.now(),
          confidence: 0.1,
          isEnhanced: false,
        );
        
        ref.read(isTypingProvider.notifier).state = false;
        ref.read(chatMessagesProvider.notifier).addMessage(errorMessage);
        
        print('❌ Chat Error: ${enhancedResult['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      final errorMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Sorry, I\'m having trouble connecting right now.',
        isUser: false,
        timestamp: DateTime.now(),
        confidence: 0.1,
      );
      
      ref.read(isTypingProvider.notifier).state = false;
      ref.read(chatMessagesProvider.notifier).addMessage(errorMessage);
    }
  }

  void _showFeedbackDialog(ChatMessageModel message) {
    // Find the previous user message to get the query
    final messages = ref.read(chatMessagesProvider);
    String? userQuery;
    
    // Find the bot message index
    final botMessageIndex = messages.indexWhere((m) => m.id == message.id);
    
    // Look for the previous user message
    for (int i = botMessageIndex - 1; i >= 0; i--) {
      if (messages[i].isUser) {
        userQuery = messages[i].text;
        break;
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => EnhancedFeedbackDialog(
        message: message,
        userQuery: userQuery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isTyping = ref.watch(isTypingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.eco,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EcoBot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Are you sure you want to clear all messages?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(chatMessagesProvider.notifier).clearMessages();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState()
                  : AnimationLimiter(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length + (isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length && isTyping) {
                            return const TypingIndicator();
                          }
                          
                          final message = messages[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: ChatMessage(
                                  message: message,
                                  onFeedback: message.isUser ? null : () => _showFeedbackDialog(message),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            MessageInput(
              controller: _messageController,
              onSend: _sendMessage,
              isLoading: isTyping,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.eco,
              size: 50,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to EcoBot!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me anything about environmental topics,\nsustainability, or eco-friendly practices.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('How to reduce plastic waste?'),
              _buildSuggestionChip('Best renewable energy sources'),
              _buildSuggestionChip('Eco-friendly transportation'),
              _buildSuggestionChip('Sustainable living tips'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () => _sendMessage(text),
      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
      labelStyle: const TextStyle(
        color: AppColors.primaryGreen,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
