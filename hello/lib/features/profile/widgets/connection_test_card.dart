import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

class ConnectionTestCard extends StatefulWidget {
  const ConnectionTestCard({super.key});

  @override
  State<ConnectionTestCard> createState() => _ConnectionTestCardState();
}

class _ConnectionTestCardState extends State<ConnectionTestCard> {
  Map<String, bool>? _connectionResults;
  bool _isLoading = false;

  Future<void> _testConnections() async {
    setState(() {
      _isLoading = true;
      _connectionResults = null;
    });

    try {
      final results = await ApiService.testConnections();
      setState(() {
        _connectionResults = results;
      });
    } catch (e) {
      setState(() {
        _connectionResults = {
          'rasa': false,
          'gemini': false,
          'feedback_api': false,
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.wifi_tethering,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Connection Test',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _testConnections,
                    child: const Text('Test'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_connectionResults != null) ...[
              _buildConnectionItem('Rasa Chatbot', _connectionResults!['rasa'] ?? false, 'localhost:5005'),
              _buildConnectionItem('Google Gemini', _connectionResults!['gemini'] ?? false, 'AI Enhancement'),
              _buildConnectionItem('Feedback API', _connectionResults!['feedback_api'] ?? false, 'localhost:8000'),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Tap "Test" to check API connections',
                    style: TextStyle(
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionItem(String name, bool isConnected, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.successGreen : AppColors.errorRed,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              fontSize: 12,
              color: isConnected ? AppColors.successGreen : AppColors.errorRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
