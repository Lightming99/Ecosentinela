import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class RasaTestWidget extends StatefulWidget {
  const RasaTestWidget({super.key});

  @override
  State<RasaTestWidget> createState() => _RasaTestWidgetState();
}

class _RasaTestWidgetState extends State<RasaTestWidget> {
  final TextEditingController _controller = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  Future<void> _testRasa() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      // Test raw Rasa response
      final rasaResult = await ApiService.sendToRasa(_controller.text.trim());
      
      // Test enhanced response
      final enhancedResult = await ApiService.sendEnhancedMessage(
        _controller.text.trim(), 
        true, // Enable enhancement
      );

      setState(() {
        _result = '''
🔍 RAW RASA RESPONSE:
Success: ${rasaResult['success']}
Response: ${rasaResult['response']}
Confidence: ${rasaResult['confidence']}
Response Count: ${rasaResult['response_count'] ?? 'N/A'}

✨ ENHANCED RESPONSE:
Success: ${enhancedResult['success']}
Response: ${enhancedResult['response']}
Confidence: ${enhancedResult['confidence']}
Is Enhanced: ${enhancedResult['is_enhanced']}
Response Count: ${enhancedResult['response_count'] ?? 'N/A'}
        ''';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Rasa Multi-Response Handling',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Enter test message',
              hintText: 'e.g., "Tell me about pollution"',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _testRasa,
            child: _isLoading
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Testing...'),
                    ],
                  )
                : const Text('Test Rasa API'),
          ),
          const SizedBox(height: 16),
          if (_result.isNotEmpty) ...[
            const Text(
              'Results:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _result,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
