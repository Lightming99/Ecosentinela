import 'dart:convert';
import 'dart:io';

// Simple standalone script to test Gemini API
// Run this with: dart run test_gemini_api.dart

const String API_KEY = 'AIzaSyB2RdDcAm2Q6X-b9movTdd94Eav15uv1hw';

void main() async {
  print('🔍 Testing Gemini API...\n');
  
  // Test 1: Basic API Key Validation
  print('1️⃣  Testing API key validity...');
  await testApiKey();
  
  // Test 2: Models List
  print('\n2️⃣  Testing available models...');
  await testModels();
  
  // Test 3: Generate Content
  print('\n3️⃣  Testing content generation...');
  await testGeneration();
  
  print('\n✅ API test completed!');
}

Future<void> testApiKey() async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$API_KEY')
    );
    request.headers.set('Content-Type', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      final modelsCount = data['models']?.length ?? 0;
      print('   ✅ API key is valid! Found $modelsCount models.');
    } else if (response.statusCode == 403) {
      print('   ❌ API key is invalid or lacks permissions.');
      print('   📝 Generate a new key at: https://makersuite.google.com/app/apikey');
    } else {
      print('   ❌ HTTP ${response.statusCode}: ${response.reasonPhrase}');
      print('   Response: ${responseBody.substring(0, 200)}...');
    }
    
    client.close();
  } catch (e) {
    print('   ❌ Network error: $e');
    print('   📝 Check your internet connection and firewall settings.');
  }
}

Future<void> testModels() async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$API_KEY')
    );
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      final models = data['models'] as List;
      
      print('   Available models:');
      for (var model in models.take(5)) {
        final name = model['name'].toString().split('/').last;
        print('   • $name');
      }
      
      if (models.length > 5) {
        print('   • ... and ${models.length - 5} more models');
      }
    } else {
      print('   ❌ Failed to fetch models: ${response.statusCode}');
    }
    
    client.close();
  } catch (e) {
    print('   ❌ Error fetching models: $e');
  }
}

Future<void> testGeneration() async {
  try {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$API_KEY')
    );
    
    request.headers.set('Content-Type', 'application/json');
    
    final payload = jsonEncode({
      'contents': [{
        'parts': [{
          'text': 'Hello! Please respond with exactly "API is working correctly" to confirm the connection.'
        }]
      }]
    });
    
    request.write(payload);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      final candidates = data['candidates'] as List?;
      
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List;
        final text = parts[0]['text'];
        
        print('   ✅ Content generation successful!');
        print('   📝 Response: $text');
        
        if (text.toString().toLowerCase().contains('api is working')) {
          print('   🎉 Perfect! API is responding correctly.');
        }
      } else {
        print('   ⚠️  Empty response from API');
        print('   Response: $responseBody');
      }
    } else {
      print('   ❌ Generation failed: ${response.statusCode}');
      print('   Response: $responseBody');
    }
    
    client.close();
  } catch (e) {
    print('   ❌ Error generating content: $e');
  }
}
