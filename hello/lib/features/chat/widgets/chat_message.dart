import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/formatted_text.dart';
import '../models/chat_message_model.dart';

class ChatMessage extends StatelessWidget {
  final ChatMessageModel message;
  final VoidCallback? onFeedback;

  const ChatMessage({
    super.key,
    required this.message,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? const LinearGradient(
                            colors: AppColors.chatBubbleGradient,
                          )
                        : null,
                    color: message.isUser
                        ? null
                        : Theme.of(context).brightness == Brightness.dark
                            ? AppColors.cardDark
                            : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: message.isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: message.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Use formatted text rendering for bot messages, plain text for user messages
                      message.isUser
                          ? Text(
                              message.text,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Colors.white,
                              ),
                            )
                          : FormattedText(
                              data: message.text,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textLight
                                    : AppColors.textDark,
                              ),
                            ),
                      if (!message.isUser && message.isEnhanced) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                                'Enhanced by AI',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey.withOpacity(0.8),
                      ),
                    ),
                    if (!message.isUser && message.confidence != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.verified,
                        size: 12,
                        color: _getConfidenceColor(message.confidence!),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${(message.confidence! * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: _getConfidenceColor(message.confidence!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (!message.isUser && onFeedback != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onFeedback,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.warningOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warningOrange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rate,
                                size: 14,
                                color: AppColors.warningOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Rate',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.warningOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: message.isUser ? AppColors.primaryGreen : AppColors.accentGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        message.isUser ? Icons.person : Icons.eco,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppColors.successGreen;
    if (confidence >= 0.6) return AppColors.warningOrange;
    return AppColors.errorRed;
  }
}
