import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AnalyticsCard extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const AnalyticsCard({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.primaryGreen,
                ),
                SizedBox(width: 8),
                Text(
                  'Bot Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnalyticsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildAnalyticsItem(
          'Conversations',
          analytics['total_conversations']?.toString() ?? '0',
          Icons.chat,
          AppColors.primaryGreen,
        ),
        _buildAnalyticsItem(
          'Feedback',
          analytics['total_feedback']?.toString() ?? '0',
          Icons.feedback,
          AppColors.accentGreen,
        ),
        _buildAnalyticsItem(
          'Satisfaction',
          '${analytics['satisfaction_rate']?.toStringAsFixed(1) ?? '0'}%',
          Icons.sentiment_satisfied,
          AppColors.successGreen,
        ),
        _buildAnalyticsItem(
          'Confidence',
          '${analytics['confidence_score']?.toStringAsFixed(1) ?? '0'}%',
          Icons.verified,
          AppColors.infoBlue,
        ),
      ],
    );
  }

  Widget _buildAnalyticsItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
