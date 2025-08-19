import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/theme/app_colors.dart';

class ApiTestScreen extends ConsumerStatefulWidget {
  const ApiTestScreen({super.key});

  @override
  ConsumerState<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends ConsumerState<ApiTestScreen> {
  bool _isTesting = false;
  Map<String, dynamic>? _testResults;

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _testResults = null;
    });

    try {
      // Test connections
      final connections = await ApiService.testConnections();
      
      // Test a sample Rasa query
      final rasaTest = await ApiService.sendToRasa("Hello, how are you?");
      
      // Test Gemini enhancement
      final enhancementTest = await ApiService.enhanceWithGemini(
        "Test query", 
        "Test response", 
        true
      );

      setState(() {
        _testResults = {
          'connections': connections,
          'rasa_test': rasaTest,
          'enhancement_test': enhancementTest,
        };
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'error': e.toString(),
        };
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isTesting ? null : _runTests,
              child: _isTesting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Testing...'),
                      ],
                    )
                  : const Text('Run API Tests'),
            ),
            
            const SizedBox(height: 20),
            
            if (_testResults != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Results:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatTestResults(_testResults!),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTestResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    results.forEach((key, value) {
      buffer.writeln('$key:');
      buffer.writeln('  ${value.toString()}');
      buffer.writeln();
    });
    
    return buffer.toString();
  }
}
