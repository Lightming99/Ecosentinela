import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';

class GeminiApiTester {
  static const String _geminiApiKey = 'AIzaSyB2RdDcAm2Q6X-b9movTdd94Eav15uv1hw';
  
  // Test the API key validity by making a direct HTTP request
  static Future<Map<String, dynamic>> testApiKeyDirectly() async {
    const String testUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
    
    try {
      final response = await http.get(
        Uri.parse('$testUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'API key is valid',
          'status_code': response.statusCode,
          'models_count': data['models']?.length ?? 0,
          'response_data': data,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'API key is invalid or has no permissions',
          'status_code': response.statusCode,
          'error': 'Authentication failed',
          'response_body': response.body,
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Bad request - check API key format',
          'status_code': response.statusCode,
          'error': 'Invalid request',
          'response_body': response.body,
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'status_code': response.statusCode,
          'error': response.reasonPhrase,
          'response_body': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error or timeout',
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      };
    }
  }
  
  // Test using the Google Generative AI package
  static Future<Map<String, dynamic>> testUsingPackage() async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', // Use available model
        apiKey: _geminiApiKey,
      );
      
      final content = [Content.text('Hello, this is a test message. Please respond with "API is working".')];
      final response = await model.generateContent(content).timeout(const Duration(seconds: 15));
      
      if (response.text != null && response.text!.isNotEmpty) {
        return {
          'success': true,
          'message': 'Gemini API is working via package',
          'response_text': response.text,
          'response_length': response.text!.length,
        };
      } else {
        return {
          'success': false,
          'message': 'Empty response from Gemini',
          'response_object': response.toString(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error using Gemini package',
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      };
    }
  }
  
  // Test with different model variants
  static Future<Map<String, dynamic>> testDifferentModels() async {
    final models = ['gemini-1.5-flash', 'gemini-1.5-pro'];
    final results = <String, dynamic>{};
    
    for (final modelName in models) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _geminiApiKey,
        );
        
        final content = [Content.text('Test message for $modelName')];
        final response = await model.generateContent(content).timeout(const Duration(seconds: 10));
        
        results[modelName] = {
          'success': response.text != null && response.text!.isNotEmpty,
          'response': response.text?.substring(0, 100) ?? 'No response',
          'error': null,
        };
      } catch (e) {
        results[modelName] = {
          'success': false,
          'response': null,
          'error': e.toString(),
        };
      }
    }
    
    return results;
  }
  
  // Comprehensive API test
  static Future<Map<String, dynamic>> runComprehensiveTest() async {
    final testResults = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'api_key': '${_geminiApiKey.substring(0, 10)}...${_geminiApiKey.substring(_geminiApiKey.length - 5)}',
    };
    
    print('🔍 Starting Gemini API Tests...\n');
    
    // Test 1: Direct HTTP API call
    print('1️⃣  Testing API key validity (Direct HTTP)...');
    final directTest = await testApiKeyDirectly();
    testResults['direct_http_test'] = directTest;
    print(directTest['success'] ? '✅ ${directTest['message']}' : '❌ ${directTest['message']}');
    if (!directTest['success']) {
      print('   Error: ${directTest['error']}');
    }
    print('');
    
    // Test 2: Package-based test
    print('2️⃣  Testing with Google Generative AI package...');
    final packageTest = await testUsingPackage();
    testResults['package_test'] = packageTest;
    print(packageTest['success'] ? '✅ ${packageTest['message']}' : '❌ ${packageTest['message']}');
    if (packageTest['success']) {
      print('   Response: ${packageTest['response_text']?.substring(0, 50)}...');
    } else {
      print('   Error: ${packageTest['error']}');
    }
    print('');
    
    // Test 3: Different models
    print('3️⃣  Testing different Gemini models...');
    final modelsTest = await testDifferentModels();
    testResults['models_test'] = modelsTest;
    modelsTest.forEach((model, result) {
      print(result['success'] 
          ? '✅ $model: Working' 
          : '❌ $model: ${result['error']?.substring(0, 50)}...');
    });
    print('');
    
    // Test 4: Network connectivity
    print('4️⃣  Testing network connectivity to Google...');
    try {
      final googlePing = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      
      testResults['network_test'] = {
        'success': googlePing.statusCode == 200,
        'status_code': googlePing.statusCode,
      };
      print(googlePing.statusCode == 200 ? '✅ Network connectivity OK' : '❌ Network issues');
    } catch (e) {
      testResults['network_test'] = {
        'success': false,
        'error': e.toString(),
      };
      print('❌ Network connectivity failed: ${e.toString().substring(0, 50)}...');
    }
    print('');
    
    // Summary
    print('📊 TEST SUMMARY:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final directSuccess = testResults['direct_http_test']['success'] ?? false;
    final packageSuccess = testResults['package_test']['success'] ?? false;
    final networkSuccess = testResults['network_test']['success'] ?? false;
    
    if (directSuccess && packageSuccess) {
      print('🎉 ALL TESTS PASSED! Your Gemini API is working correctly.');
      print('   The issue might be in your app implementation.');
    } else if (!directSuccess) {
      print('❌ API KEY ISSUE: Your API key appears to be invalid or restricted.');
      print('   📝 Action needed: Check your API key or generate a new one.');
      print('   🔗 Go to: https://makersuite.google.com/app/apikey');
    } else if (!packageSuccess) {
      print('⚠️  PACKAGE ISSUE: API key works but package has problems.');
      print('   📝 Action needed: Check package version or implementation.');
    } else if (!networkSuccess) {
      print('🌐 NETWORK ISSUE: Cannot reach Google services.');
      print('   📝 Action needed: Check your internet connection or firewall.');
    }
    
    return testResults;
  }
}

// Widget for testing in Flutter app
class GeminiTestScreen extends StatefulWidget {
  const GeminiTestScreen({super.key});

  @override
  State<GeminiTestScreen> createState() => _GeminiTestScreenState();
}

class _GeminiTestScreenState extends State<GeminiTestScreen> {
  bool _isTesting = false;
  Map<String, dynamic>? _testResults;
  String _testOutput = '';

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _testResults = null;
      _testOutput = '';
    });

    try {
      final results = await GeminiApiTester.runComprehensiveTest();
      setState(() {
        _testResults = results;
        _testOutput = _formatResults(results);
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testOutput = 'Test failed with error: $e';
        _isTesting = false;
      });
    }
  }

  String _formatResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('🔍 GEMINI API TEST RESULTS');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('📅 Timestamp: ${results['timestamp']}');
    buffer.writeln('🔑 API Key: ${results['api_key']}');
    buffer.writeln('');
    
    // Direct HTTP Test
    final directTest = results['direct_http_test'];
    buffer.writeln('1️⃣  DIRECT HTTP TEST:');
    buffer.writeln('   Status: ${directTest['success'] ? '✅ PASSED' : '❌ FAILED'}');
    buffer.writeln('   Message: ${directTest['message']}');
    if (directTest['status_code'] != null) {
      buffer.writeln('   HTTP Status: ${directTest['status_code']}');
    }
    if (!directTest['success'] && directTest['error'] != null) {
      buffer.writeln('   Error: ${directTest['error']}');
    }
    buffer.writeln('');
    
    // Package Test
    final packageTest = results['package_test'];
    buffer.writeln('2️⃣  PACKAGE TEST:');
    buffer.writeln('   Status: ${packageTest['success'] ? '✅ PASSED' : '❌ FAILED'}');
    buffer.writeln('   Message: ${packageTest['message']}');
    if (packageTest['success'] && packageTest['response_text'] != null) {
      final response = packageTest['response_text'].toString();
      buffer.writeln('   Response: ${response.length > 100 ? response.substring(0, 100) + '...' : response}');
    }
    if (!packageTest['success'] && packageTest['error'] != null) {
      buffer.writeln('   Error: ${packageTest['error']}');
    }
    buffer.writeln('');
    
    // Models Test
    final modelsTest = results['models_test'];
    buffer.writeln('3️⃣  MODELS TEST:');
    modelsTest.forEach((model, result) {
      buffer.writeln('   $model: ${result['success'] ? '✅ Working' : '❌ Failed'}');
      if (!result['success'] && result['error'] != null) {
        buffer.writeln('      Error: ${result['error'].toString().substring(0, 50)}...');
      }
    });
    buffer.writeln('');
    
    // Network Test
    final networkTest = results['network_test'];
    buffer.writeln('4️⃣  NETWORK TEST:');
    buffer.writeln('   Status: ${networkTest['success'] ? '✅ PASSED' : '❌ FAILED'}');
    if (networkTest['status_code'] != null) {
      buffer.writeln('   HTTP Status: ${networkTest['status_code']}');
    }
    buffer.writeln('');
    
    // Recommendations
    buffer.writeln('💡 RECOMMENDATIONS:');
    buffer.writeln('───────────────────────────────────────');
    
    final directSuccess = directTest['success'] ?? false;
    final packageSuccess = packageTest['success'] ?? false;
    
    if (directSuccess && packageSuccess) {
      buffer.writeln('🎉 Your API is working perfectly!');
      buffer.writeln('   If you\'re still having issues in your app,');
      buffer.writeln('   check your implementation logic.');
    } else if (!directSuccess) {
      buffer.writeln('❌ API Key Issue Detected:');
      buffer.writeln('   1. Verify your API key is correct');
      buffer.writeln('   2. Check if Gemini API is enabled in your project');
      buffer.writeln('   3. Ensure billing is set up (if required)');
      buffer.writeln('   4. Generate a new API key if needed');
      buffer.writeln('   🔗 https://makersuite.google.com/app/apikey');
    } else if (!packageSuccess) {
      buffer.writeln('⚠️  Package Issue:');
      buffer.writeln('   1. Update google_generative_ai package');
      buffer.writeln('   2. Check Flutter/Dart SDK compatibility');
      buffer.writeln('   3. Verify network permissions');
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini API Tester'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.api,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Gemini API Comprehensive Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will test your API key, network connectivity, and package integration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isTesting ? null : _runTests,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: _isTesting
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
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
                                Text('Running Tests...'),
                              ],
                            )
                          : const Text('Run Comprehensive Test'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_testOutput.isNotEmpty) ...[
              const Text(
                'Test Results:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _testOutput,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
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
}
