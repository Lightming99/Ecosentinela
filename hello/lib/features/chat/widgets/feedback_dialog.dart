import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/analytics_provider.dart';
import '../models/chat_message_model.dart';

class FeedbackDialog extends ConsumerStatefulWidget {
  final ChatMessageModel message;
  final String? userQuery;

  const FeedbackDialog({
    super.key,
    required this.message,
    this.userQuery,
  });

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog>
    with TickerProviderStateMixin {
  double _rating = 5.0;
  String _comment = '';
  bool _isSubmitting = false;
  final List<String> _selectedCategories = [];
  late AnimationController _animationController;
  late AnimationController _submitController;
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
    _submitController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _submitController.dispose();
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
    _submitController.forward();

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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.feedback,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Rate this response',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Conversation Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Query
                  if (widget.userQuery != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Your Question:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.userQuery!.length > 80
                          ? '${widget.userQuery!.substring(0, 80)}...'
                          : widget.userQuery!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.primaryGreen,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: AppColors.borderGrey.withOpacity(0.5)),
                    const SizedBox(height: 12),
                  ],
                  
                  // Bot Response
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 14,
                        color: AppColors.accentGreen,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Bot Response:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.message.text.length > 120
                        ? '${widget.message.text.substring(0, 120)}...'
                        : widget.message.text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Enhancement and Confidence badges
                  Row(
                    children: [
                      if (widget.message.isEnhanced) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: AppColors.accentGreen,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'AI Enhanced',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (widget.message.confidence != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.infoBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 12,
                                color: AppColors.infoBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(widget.message.confidence! * 100).toStringAsFixed(0)}% confident',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.infoBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Rating Section
            const Text(
              'How would you rate this response?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Center(
              child: Column(
                children: [
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1.0,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 40,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: AppColors.warningOrange,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                        _selectedCategories.clear(); // Clear categories when rating changes
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_rating.round()} out of 5 stars',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _feedbackType == 'positive' 
                          ? AppColors.successGreen.withOpacity(0.1)
                          : AppColors.warningOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _feedbackType == 'positive' ? 'Positive Feedback' : 'Negative Feedback',
                      style: TextStyle(
                        fontSize: 12,
                        color: _feedbackType == 'positive' 
                            ? AppColors.successGreen 
                            : AppColors.warningOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Categories (shown for all ratings, different options based on rating)
            Text(
              _rating >= 3.0 
                  ? 'What did you like? (Optional)'
                  : 'What can be improved? (Select issues)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _availableCategories.map((category) {
                    final isSelected = _selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppColors.textGrey,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                      backgroundColor: Colors.transparent,
                      selectedColor: _feedbackType == 'positive' 
                          ? AppColors.successGreen 
                          : AppColors.warningOrange,
                      side: BorderSide(
                        color: isSelected 
                            ? (_feedbackType == 'positive' 
                                ? AppColors.successGreen 
                                : AppColors.warningOrange)
                            : AppColors.borderGrey,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Comment Section
            const Text(
              'Additional Comments (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 8),
            
            TextField(
              onChanged: (value) => _comment = value,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _rating >= 3.0 
                    ? 'Tell us what you loved about this response...'
                    : 'Help us understand what went wrong...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _feedbackType == 'positive' 
                      ? AppColors.successGreen 
                      : AppColors.warningOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    : Text(
                        'Submit ${_feedbackType == 'positive' ? 'Positive' : 'Negative'} Feedback',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
