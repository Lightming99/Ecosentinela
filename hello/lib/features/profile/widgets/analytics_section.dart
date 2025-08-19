import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/analytics_provider.dart';
import 'dart:math' as math;

class AnalyticsSection extends ConsumerWidget {
  const AnalyticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildAnalyticsContent(analytics),
      ),
    );
  }
  
  Widget _buildAnalyticsContent(Map<String, dynamic> analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.analytics,
                color: AppColors.accentGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Bot Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Live indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.successGreen.withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    color: AppColors.successGreen,
                    size: 8,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Analytics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildAnalyticsCard(
              title: 'Conversations',
              value: analytics['total_conversations'].toString(),
              icon: Icons.chat_bubble_outline,
              color: AppColors.primaryGreen,
            ),
            _buildAnalyticsCard(
              title: 'Accuracy Score',
              value: '${analytics['confidence_score'].toStringAsFixed(0)}%',
              icon: Icons.verified,
              color: AppColors.successGreen,
            ),
            _buildAnalyticsCard(
              title: 'Satisfaction',
              value: '${analytics['satisfaction_rate'].toStringAsFixed(0)}%',
              icon: Icons.sentiment_satisfied,
              color: AppColors.warningOrange,
            ),
            _buildAnalyticsCard(
              title: 'Avg Rating',
              value: analytics['average_rating'].toStringAsFixed(1),
              icon: Icons.star,
              color: AppColors.infoBlue,
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Confidence Meter
        _buildConfidenceMeter(analytics['confidence_score'].toDouble()),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceMeter(double confidence) {
    final clampedConfidence = math.max(0.0, math.min(100.0, confidence));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Confidence',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderGrey.withOpacity(0.5),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${clampedConfidence.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(clampedConfidence),
                    ),
                  ),
                  Icon(
                    _getConfidenceIcon(clampedConfidence),
                    color: _getConfidenceColor(clampedConfidence),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: clampedConfidence / 100,
                  backgroundColor: AppColors.borderGrey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getConfidenceColor(clampedConfidence),
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getConfidenceText(clampedConfidence),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return AppColors.successGreen;
    if (confidence >= 60) return AppColors.warningOrange;
    return AppColors.errorRed;
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 80) return Icons.sentiment_very_satisfied;
    if (confidence >= 60) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _getConfidenceText(double confidence) {
    if (confidence >= 80) return 'Excellent performance';
    if (confidence >= 60) return 'Good performance';
    return 'Needs improvement';
  }
}
