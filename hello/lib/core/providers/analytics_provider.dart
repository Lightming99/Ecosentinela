import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

// Live analytics provider that updates when data changes
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, Map<String, dynamic>>((ref) {
  return AnalyticsNotifier();
});

// Provider for live refresh trigger
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

class AnalyticsNotifier extends StateNotifier<Map<String, dynamic>> {
  AnalyticsNotifier() : super(_calculateAnalytics()) {
    // Initialize with current data
    refresh();
  }

  static Map<String, dynamic> _calculateAnalytics() {
    final feedbackList = StorageService.getFeedbackHistory();
    final chatHistory = StorageService.getChatHistory();
    
    final totalFeedback = feedbackList.length;
    final positiveFeedback = feedbackList.where((f) {
      final rating = f['rating'];
      if (rating is int) return rating >= 4;
      if (rating is double) return rating >= 4.0;
      return false;
    }).length;
    
    final averageRating = totalFeedback > 0 
        ? feedbackList.map((f) {
            final rating = f['rating'];
            if (rating is int) return rating.toDouble();
            if (rating is double) return rating;
            return 0.0;
          }).reduce((a, b) => a + b) / totalFeedback
        : 0.0;
    
    // Calculate bot responses only (not user messages)
    final botResponses = chatHistory.where((msg) => !(msg['isUser'] ?? true)).length;
    
    // Calculate confidence score from recent responses
    final recentResponses = chatHistory
        .where((msg) => !(msg['isUser'] ?? true) && msg['confidence'] != null)
        .take(10)
        .toList();
    
    final averageConfidence = recentResponses.isNotEmpty
        ? recentResponses.map((msg) {
            final confidence = msg['confidence'];
            if (confidence is double) return confidence;
            if (confidence is int) return confidence.toDouble();
            return 0.8; // default confidence
          }).reduce((a, b) => a + b) / recentResponses.length
        : 0.8;
    
    return {
      'total_conversations': botResponses,
      'total_feedback': totalFeedback,
      'positive_feedback': positiveFeedback,
      'satisfaction_rate': totalFeedback > 0 ? (positiveFeedback / totalFeedback) * 100 : 0.0,
      'average_rating': averageRating,
      'confidence_score': averageConfidence * 100, // Convert to percentage
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  void refresh() {
    state = _calculateAnalytics();
  }
  
  void updateAfterNewMessage() {
    refresh();
  }
  
  void updateAfterNewFeedback() {
    refresh();
  }
}
