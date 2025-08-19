import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/analytics_provider.dart';
import '../models/chat_message_model.dart';

class EnhancedFeedbackDialog extends ConsumerStatefulWidget {
  final ChatMessageModel message;
  final String? userQuery;

  const EnhancedFeedbackDialog({
    super.key,
    required this.message,
    this.userQuery,
  });

  @override
  ConsumerState<EnhancedFeedbackDialog> createState() => _EnhancedFeedbackDialogState();
}

class _EnhancedFeedbackDialogState extends ConsumerState<EnhancedFeedbackDialog>
    with TickerProviderStateMixin {
  double _rating = 5.0;
  String _comment = '';
  bool _isSubmitting = false;
  final List<String> _selectedCategories = [];
  late AnimationController _animationController;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Positive feedback categories (for ratings 4-5)
  final List<String> _positiveCategories = [
    '🎯 Very Helpful',
    '✅ Accurate Information',
    '⚡ Quick Response',
    '💡 Easy to Understand',
    '📖 Comprehensive Answer',
    '🌟 Great Suggestions',
    '🎨 Well Formatted',
    '🌿 Eco-Friendly Tips',
  ];

  // Negative feedback categories (for ratings 1-3)
  final List<String> _negativeCategories = [
    '❌ Incorrect Information',
    '🤔 Not Helpful',
    '🐌 Too Slow',
    '😵 Confusing Response',
    '🎯 Off-Topic',
    '🔧 Technical Issues',
    '📝 Poor Grammar',
    '🚫 Irrelevant Content',
  ];

  String get _feedbackType => _rating >= 4.0 ? 'positive' : 'negative';
  List<String> get _availableCategories => _rating >= 4.0 ? _positiveCategories : _negativeCategories;
  Color get _themeColor => _rating >= 4.0 ? AppColors.successGreen : AppColors.warningOrange;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitFeedback() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedbackData = {
        'message_id': widget.message.id,
        'user_query': widget.userQuery ?? 'Query not available',
        'bot_response': widget.message.text,
        'rating': _rating.round(),
        'comment': _comment.trim(),
        'feedback_type': _feedbackType,
        'categories': _selectedCategories,
        'timestamp': DateTime.now().toIso8601String(),
        'confidence': widget.message.confidence ?? 0.8,
        'was_enhanced': widget.message.isEnhanced,
      };

      // Save locally first
      StorageService.saveFeedback(feedbackData);
      
      // Update analytics immediately
      ref.read(analyticsProvider.notifier).updateAfterNewFeedback();

      // Submit to Flask API
      bool apiSuccess = false;
      try {
        apiSuccess = await ApiService.submitFeedback(
          userQuery: widget.userQuery ?? 'Query not available',
          botResponse: widget.message.text,
          rating: _rating.round(),
          comment: _comment.trim(),
          feedbackType: _feedbackType,
          categories: _selectedCategories,
          messageId: widget.message.id,
        );
      } catch (e) {
        print('❌ API submission failed: $e');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _feedbackType == 'positive' ? Icons.celebration : Icons.feedback,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Thank you for your feedback! 🙏',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        apiSuccess
                            ? 'Stored locally & sent to server ✅'
                            : 'Stored locally (server offline) 📱',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: _themeColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to submit feedback: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _animationController.value,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450, maxHeight: 700),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_themeColor, _themeColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.star_rate,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Rate My Response',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        children: [
                          _buildRatingPage(),
                          _buildDetailsPage(),
                        ],
                      ),
                    ),

                    // Page indicator and navigation
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Page indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPageIndicator(0),
                              const SizedBox(width: 8),
                              _buildPageIndicator(1),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Navigation buttons
                          Row(
                            children: [
                              if (_currentPage > 0) ...[
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: _previousPage,
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Back'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                flex: _currentPage == 0 ? 1 : 2,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting 
                                      ? null 
                                      : (_currentPage == 0 ? _nextPage : _submitFeedback),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _themeColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isSubmitting
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Submitting...'),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _currentPage == 0 ? 'Continue' : 'Submit Feedback',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              _currentPage == 0 ? Icons.arrow_forward : Icons.send,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator(int pageIndex) {
    final isActive = _currentPage == pageIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? _themeColor : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildRatingPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conversation preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.userQuery != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Your Question',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userQuery!.length > 100
                        ? '${widget.userQuery!.substring(0, 100)}...'
                        : widget.userQuery!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.borderGrey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                ],
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        size: 16,
                        color: AppColors.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Bot Response',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message.text.length > 150
                      ? '${widget.message.text.substring(0, 150)}...'
                      : widget.message.text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Enhancement badges
                Wrap(
                  spacing: 8,
                  children: [
                    if (widget.message.isEnhanced) 
                      _buildBadge('✨ AI Enhanced', AppColors.accentGreen),
                    if (widget.message.confidence != null)
                      _buildBadge(
                        '🎯 ${(widget.message.confidence! * 100).toStringAsFixed(0)}% confident',
                        AppColors.infoBlue,
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Rating section
          const Text(
            'How would you rate this response?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Center(
            child: Column(
              children: [
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1.0,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 50,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, index) => Icon(
                    Icons.star,
                    color: index < _rating ? _themeColor : Colors.grey.withOpacity(0.3),
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                      _selectedCategories.clear(); // Clear categories when rating changes
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Rating text and feedback type
                Text(
                  '${_rating.round()} out of 5 stars',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _themeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _themeColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _feedbackType == 'positive' ? Icons.sentiment_very_satisfied : Icons.sentiment_dissatisfied,
                        color: _themeColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _feedbackType == 'positive' ? 'Positive Feedback' : 'Needs Improvement',
                        style: TextStyle(
                          fontSize: 14,
                          color: _themeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories section
          Text(
            _rating >= 4.0 
                ? 'What did you like? 😊' 
                : 'What can be improved? 🔧',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(category);
                    } else {
                      _selectedCategories.add(category);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _themeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _themeColor : AppColors.borderGrey,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.textGrey,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Comment section
          const Text(
            'Additional Comments (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            onChanged: (value) => _comment = value,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: _rating >= 4.0 
                  ? 'Tell us what you loved about this response... 💝'
                  : 'Help us understand what went wrong... 🤔',
              hintStyle: TextStyle(color: AppColors.textGrey.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderGrey.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _themeColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              counterStyle: TextStyle(color: AppColors.textGrey.withOpacity(0.7)),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _themeColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: _themeColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '⭐ Rating: ${_rating.round()}/5 stars',
                  style: const TextStyle(fontSize: 13),
                ),
                if (_selectedCategories.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '🏷️ Categories: ${_selectedCategories.length} selected',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
                if (_comment.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '💬 Comment: ${_comment.trim().length} characters',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
