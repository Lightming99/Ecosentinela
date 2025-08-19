import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _settingsBox = 'settings';
  static const String _chatHistoryBox = 'chat_history';
  static const String _feedbackBox = 'feedback';
  
  static late Box _settings;
  static late Box _chatHistory;
  static late Box _feedback;
  
  static Future<void> init() async {
    _settings = await Hive.openBox(_settingsBox);
    _chatHistory = await Hive.openBox(_chatHistoryBox);
    _feedback = await Hive.openBox(_feedbackBox);
  }
  
  // Settings
  static bool get isLlmEnhanced => _settings.get('llm_enhanced', defaultValue: true);
  static set isLlmEnhanced(bool value) => _settings.put('llm_enhanced', value);
  
  static bool get isDarkMode => _settings.get('dark_mode', defaultValue: false);
  static set isDarkMode(bool value) => _settings.put('dark_mode', value);
  
  static String get userName => _settings.get('user_name', defaultValue: 'User');
  static set userName(String value) => _settings.put('user_name', value);
  
  // Chat History
  static List<Map<String, dynamic>> getChatHistory() {
    final history = _chatHistory.get('messages', defaultValue: <dynamic>[]);
    return List<Map<String, dynamic>>.from(
      history.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is Map) {
          return Map<String, dynamic>.from(item);
        } else {
          return <String, dynamic>{};
        }
      })
    );
  }
  
  static void saveChatMessage(Map<String, dynamic> message) {
    final history = getChatHistory();
    history.add(Map<String, dynamic>.from(message));
    // Keep only last 100 messages to prevent unlimited storage growth
    if (history.length > 100) {
      history.removeRange(0, history.length - 100);
    }
    _chatHistory.put('messages', history);
  }
  
  static void clearChatHistory() {
    _chatHistory.delete('messages');
  }
  
  // Feedback
  static List<Map<String, dynamic>> getFeedbackHistory() {
    final feedback = _feedback.get('feedback_list', defaultValue: <dynamic>[]);
    return List<Map<String, dynamic>>.from(
      feedback.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is Map) {
          return Map<String, dynamic>.from(item);
        } else {
          return <String, dynamic>{};
        }
      })
    );
  }
  
  static void saveFeedback(Map<String, dynamic> feedback) {
    final feedbackList = getFeedbackHistory();
    feedbackList.add(Map<String, dynamic>.from(feedback));
    // Keep only last 50 feedback entries
    if (feedbackList.length > 50) {
      feedbackList.removeRange(0, feedbackList.length - 50);
    }
    _feedback.put('feedback_list', feedbackList);
  }
  
  static void clearFeedback() {
    _feedback.delete('feedback_list');
  }
  
  // Analytics
  static Map<String, dynamic> getBotAnalytics() {
    final feedbackList = getFeedbackHistory();
    final chatHistory = getChatHistory();
    
    final totalFeedback = feedbackList.length;
    final positiveFeedback = feedbackList.where((f) => f['rating'] >= 4).length;
    final averageRating = totalFeedback > 0 
        ? feedbackList.map((f) => f['rating'] as int).reduce((a, b) => a + b) / totalFeedback
        : 0.0;
    
    return {
      'total_conversations': chatHistory.length,
      'total_feedback': totalFeedback,
      'positive_feedback': positiveFeedback,
      'satisfaction_rate': totalFeedback > 0 ? (positiveFeedback / totalFeedback) * 100 : 0.0,
      'average_rating': averageRating,
      'confidence_score': averageRating * 20, // Convert 5-star to 100%
    };
  }
}
