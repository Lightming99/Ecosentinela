import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  static const String _rasaUrl = 'http://localhost:5005';
  static const String _geminiApiKey = 'AIzaSyB2RdDcAm2Q6X-b9movTdd94Eav15uv1hw';
  static const String _feedbackUrl = 'http://localhost:8000';
  
  static late GenerativeModel _geminiModel;
  
  static void initGemini() {
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-flash', // Use the available model
      apiKey: _geminiApiKey,
    );
  }
  
  // Send message to Rasa chatbot
  static Future<Map<String, dynamic>> sendToRasa(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_rasaUrl/webhooks/rest/webhook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': 'user',
          'message': message,
        }),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // Merge all responses from Rasa into one comprehensive response
          List<String> allResponses = [];
          double totalConfidence = 0.0;
          int responseCount = 0;
          
          for (var item in data) {
            if (item['text'] != null && item['text'].toString().trim().isNotEmpty) {
              allResponses.add(item['text'].toString().trim());
              
              // Calculate average confidence
              if (item['confidence'] != null) {
                totalConfidence += (item['confidence'] as num).toDouble();
                responseCount++;
              }
            }
          }
          
          if (allResponses.isNotEmpty) {
            // Join all responses with proper spacing
            String mergedResponse = allResponses.join('\n\n');
            
            // Calculate average confidence, fallback to 0.8 if no confidence data
            double averageConfidence = responseCount > 0 
                ? totalConfidence / responseCount 
                : 0.8;
            
            print('📊 Rasa returned ${allResponses.length} response(s)');
            print('📝 Merged response length: ${mergedResponse.length} characters');
            print('🎯 Average confidence: ${(averageConfidence * 100).toStringAsFixed(1)}%');
            
            return {
              'success': true,
              'response': mergedResponse,
              'confidence': averageConfidence,
              'response_count': allResponses.length,
            };
          }
        }
      }
      
      return {
        'success': false,
        'error': 'Failed to get response from Rasa',
        'response': 'Sorry, I could not understand your question. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'response': 'Sorry, I am having trouble connecting. Please check your connection.',
      };
    }
  }
  
  // Enhanced chat flow: Rasa -> Gemini enhancement -> User-friendly response
  static Future<Map<String, dynamic>> sendEnhancedMessage(
    String userQuery, 
    bool isEnhancementEnabled,
  ) async {
    try {
      // Step 1: Get response from Rasa
      print('📤 Sending to Rasa: $userQuery');
      final rasaResult = await sendToRasa(userQuery);
      
      if (!rasaResult['success']) {
        return rasaResult;
      }
      
      final rasaResponse = rasaResult['response'] as String;
      final confidence = rasaResult['confidence'] as double;
      
      print('📥 Rasa response: $rasaResponse');
      print('🎯 Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
      
      // Step 2: Enhance with Gemini if enabled
      if (isEnhancementEnabled) {
        print('✨ Enhancing with Gemini...');
        final enhancementResult = await enhanceWithGemini(
          userQuery, 
          rasaResponse, 
          isEnhancementEnabled,
        );
        
        if (enhancementResult['success']) {
          final enhancedResponse = enhancementResult['enhanced_response'] as String;
          print('🚀 Enhanced response: $enhancedResponse');
          
          return {
            'success': true,
            'response': enhancedResponse,
            'original_response': rasaResponse,
            'confidence': confidence,
            'is_enhanced': true,
            'user_query': userQuery,
          };
        }
      }
      
      // Return original Rasa response if enhancement disabled or failed
      return {
        'success': true,
        'response': rasaResponse,
        'original_response': rasaResponse,
        'confidence': confidence,
        'is_enhanced': false,
        'user_query': userQuery,
      };
      
    } catch (e) {
      print('❌ Error in sendEnhancedMessage: $e');
      return {
        'success': false,
        'error': e.toString(),
        'response': 'Sorry, I encountered an error while processing your request. Please try again.',
        'user_query': userQuery,
      };
    }
  }

  // Enhance response with Google Gemini (improved prompt)
  static Future<Map<String, dynamic>> enhanceWithGemini(
    String userQuery, 
    String rasaResponse,
    bool isEnhancementEnabled,
  ) async {
    if (!isEnhancementEnabled) {
      return {
        'success': true,
        'enhanced_response': rasaResponse,
        'is_enhanced': false,
      };
    }

    try {
      final prompt = '''
You are EcoBot, an intelligent eco-friendly AI assistant specializing in environmental data and sustainability. The user asked a question and Rasa provided a comprehensive response (possibly multiple parts). Your job is to enhance this response to make it more user-friendly while preserving ALL the information.

USER QUERY: "$userQuery"
RASA RESPONSE (Complete): "$rasaResponse"

Your enhancement task:
1. 📝 Clean up formatting by converting asterisks in response given by rasa like (**text**) to proper bold formatting (**text**) and improving grammar, clarity, and sentence flow
2. 🔗 Organize multiple parts into a coherent, well-structured response
3. 🌿 Add relevant eco-friendly context when appropriate for environmental topics
4. 😊 Make it conversational, friendly, and professional
5. ✅ Preserve ALL factual information, data values, and measurements from the original response
6. 📏 Keep response concise but comprehensive (max 300 words for complex queries, shorter for simple ones)
7. 🚫 Do NOT remove any important information, numerical data, or specific values from the original
8. 🎯 Use proper formatting with paragraphs, bullet points, or numbered lists when helpful
9. 🌍 For environmental data queries (AQI, Water Quality, Waste Management), present data clearly with context
10. 📋 For incident report forms, maintain conversational flow while asking for required information step-by-step
11. 💡 Add brief eco-tips only if directly relevant to the query
12. 🔧 If the original response has multiple distinct parts, organize them logically with clear sections
13. 🛠️ If the original response includes technical details or code snippets, ensure they are properly formatted and easy to read
14. 📊 If the original response includes numerical data, present it in an easy-to-understand format with proper units
15. There is a form when user asks about report an incident, incident report on that just improve the text given by rasa and do not add any extra text
16. if the original response include any markdown formatting of ** it means bold text you are  free to enhance that using emojis and bolding the text
17. For water data specify that data source is EEA waterbase dataset and it's of 2023.


Special handling for different query types:
- **Environmental Data (AQI, Water Quality, etc.)**: Present data with clear explanations and health/environmental implications
- **Waste Management**: Include practical tips and local guidelines when relevant  
- **Incident Report Forms**: Guide users through form completion conversationally, asking one question at a time
- **General Eco Queries**: Provide actionable advice with supporting data when available
- ** Water Quality**: Include specific data points and their implications for health and environment that rasa response is giving you

Format guidelines:
- Use clear paragraphs separated by line breaks
- Add relevant emojis (2-4 per response) for visual appeal and topic identification
- Use bullet points (•) or numbers (1.) for lists when appropriate
- Maintain a helpful, knowledgeable tone
- Ensure proper spacing for mobile readability
- Remove any formatting artifacts like excessive asterisks - convert **text** patterns to proper bold formatting
- Convert asterisk-wrapped text (**important text**) to proper markdown bold formatting (**important text**)
- Present numerical data in easy-to-understand format

ENHANCED RESPONSE:''';

      final content = [Content.text(prompt)];
      final response = await _geminiModel.generateContent(content);
      
      final enhancedText = response.text?.trim() ?? rasaResponse;
      
      print('📊 Original response length: ${rasaResponse.length} chars');
      print('✨ Enhanced response length: ${enhancedText.length} chars');
      
      return {
        'success': true,
        'enhanced_response': enhancedText,
        'is_enhanced': true,
      };
    } catch (e) {
      print('❌ Gemini enhancement failed: $e');
      // If enhancement fails, return original response
      return {
        'success': true,
        'enhanced_response': rasaResponse,
        'is_enhanced': false,
        'enhancement_error': e.toString(),
      };
    }
  }
  
  // Test API connections
  static Future<Map<String, bool>> testConnections() async {
    final results = <String, bool>{};
    
    // Test Rasa connection
    try {
      final rasaResponse = await http.get(
        Uri.parse('$_rasaUrl/version'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      results['rasa'] = rasaResponse.statusCode == 200;
    } catch (e) {
      results['rasa'] = false;
    }
    
    // Test Gemini connection
    try {
      initGemini();
      final content = [Content.text('Hello, this is a test.')];
      await _geminiModel.generateContent(content);
      results['gemini'] = true;
    } catch (e) {
      results['gemini'] = false;
    }
    
    // Test feedback API connection
    try {
      final feedbackResponse = await http.get(
        Uri.parse('$_feedbackUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      results['feedback_api'] = feedbackResponse.statusCode == 200;
    } catch (e) {
      results['feedback_api'] = false;
    }
    
    return results;
  }
  
  // Submit feedback to Flask API (matching Flask structure)
  static Future<bool> submitFeedback({
    required String userQuery,
    required String botResponse,
    required int rating,
    required String comment,
    required String feedbackType,
    List<String>? categories,
    String? messageId,
  }) async {
    try {
      final feedbackData = {
        'user_query': userQuery,
        'bot_response': botResponse,
        'feedback_type': feedbackType,
        'user_comment': comment,
        'rating_stars': rating,
        'message_id': messageId ?? '',
        'categories': categories ?? [],
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📤 Submitting feedback to Flask API: $feedbackData');

      final response = await http.post(
        Uri.parse('$_feedbackUrl/api/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(feedbackData),
      ).timeout(const Duration(seconds: 10));

      print('📥 Flask API response status: ${response.statusCode}');
      print('📥 Flask API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('✅ Feedback successfully submitted to Flask API');
          return true;
        } else {
          print('❌ Flask API returned success=false: ${responseData['error']}');
          return false;
        }
      } else {
        print('❌ HTTP error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Failed to submit feedback to Flask API: $e');
      return false;
    }
  }
}
