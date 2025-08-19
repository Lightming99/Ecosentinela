#!/usr/bin/env python3
"""
Test script for the Neo4j Feedback API
Run this script to test all API endpoints with sample data
"""

import requests
import json
from datetime import datetime, timedelta
import random
import uuid

# API Configuration
API_BASE_URL = "http://localhost:8000/api"

def generate_sample_feedback():
    """Generate sample feedback data for testing"""
    sample_intents = [
        "carbon_reduction_inquiry",
        "waste_management_policy",
        "renewable_energy_info",
        "environmental_regulations",
        "air_quality_concern"
    ]
    
    sample_categories = [
        ["helpful", "accurate"],
        ["informative", "clear"],
        ["confusing", "incomplete"],
        ["detailed", "relevant"],
        ["unclear", "outdated"]
    ]
    
    sample_messages = [
        "How to reduce carbon emissions in urban areas?",
        "What are the waste management policies for small businesses?",
        "Can you explain renewable energy incentives?",
        "What environmental regulations apply to manufacturing?",
        "How can I report air quality issues in my area?"
    ]
    
    feedback_types = ["positive", "negative"]
    
    return {
        "feedback_id": str(uuid.uuid4()),
        "message_id": f"msg_{random.randint(1000, 9999)}",
        "message_text": random.choice(sample_messages),
        "conversation_id": f"conv_{random.randint(100, 999)}",
        "user_id": f"user_{random.randint(100, 999)}",
        "feedback_type": random.choice(feedback_types),
        "comment": "This response was helpful for understanding the policy." if random.choice([True, False]) else "",
        "categories": random.choice(sample_categories),
        "timestamp": (datetime.now() - timedelta(days=random.randint(0, 30))).isoformat() + "Z",
        "intent": random.choice(sample_intents),
        "confidence": round(random.uniform(0.6, 0.95), 2),
        "entities": [
            {
                "entity": "topic",
                "value": random.choice(["carbon", "waste", "energy", "regulations", "air quality"])
            }
        ]
    }

def test_health_check():
    """Test the health check endpoint"""
    print("🔍 Testing Health Check...")
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_store_feedback():
    """Test storing feedback"""
    print("\n📝 Testing Store Feedback...")
    
    # Test with valid data
    sample_data = generate_sample_feedback()
    print(f"Sample data: {json.dumps(sample_data, indent=2)}")
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/feedback",
            json=sample_data,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        # Test with invalid data
        print("\n🚫 Testing with invalid data...")
        invalid_data = {"invalid": "data"}
        response = requests.post(
            f"{API_BASE_URL}/feedback",
            json=invalid_data,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        print(f"Invalid data status code: {response.status_code}")
        print(f"Invalid data response: {json.dumps(response.json(), indent=2)}")
        
        return True
    except Exception as e:
        print(f"❌ Store feedback test failed: {e}")
        return False

def test_analytics():
    """Test analytics endpoint"""
    print("\n📊 Testing Analytics...")
    try:
        response = requests.get(f"{API_BASE_URL}/feedback/analytics", timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Analytics test failed: {e}")
        return False

def test_trends():
    """Test trends endpoint"""
    print("\n📈 Testing Trends...")
    try:
        # Test with default days
        response = requests.get(f"{API_BASE_URL}/feedback/trends", timeout=10)
        print(f"Default trends - Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        # Test with custom days
        response = requests.get(f"{API_BASE_URL}/feedback/trends?days=7", timeout=10)
        print(f"\nCustom days (7) - Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return True
    except Exception as e:
        print(f"❌ Trends test failed: {e}")
        return False

def test_intent_performance():
    """Test intent performance endpoint"""
    print("\n🎯 Testing Intent Performance...")
    try:
        response = requests.get(f"{API_BASE_URL}/feedback/intents", timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Intent performance test failed: {e}")
        return False

def test_user_engagement():
    """Test user engagement endpoint"""
    print("\n👥 Testing User Engagement...")
    try:
        # Test with default limit
        response = requests.get(f"{API_BASE_URL}/feedback/engagement", timeout=10)
        print(f"Default limit - Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        # Test with custom limit
        response = requests.get(f"{API_BASE_URL}/feedback/engagement?limit=5", timeout=10)
        print(f"\nCustom limit (5) - Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        return True
    except Exception as e:
        print(f"❌ User engagement test failed: {e}")
        return False

def test_category_insights():
    """Test category insights endpoint"""
    print("\n🏷️ Testing Category Insights...")
    try:
        response = requests.get(f"{API_BASE_URL}/feedback/categories", timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Category insights test failed: {e}")
        return False

def populate_sample_data(num_records=10):
    """Populate the database with sample data for testing"""
    print(f"\n🌱 Populating database with {num_records} sample records...")
    
    success_count = 0
    for i in range(num_records):
        sample_data = generate_sample_feedback()
        try:
            response = requests.post(
                f"{API_BASE_URL}/feedback",
                json=sample_data,
                headers={'Content-Type': 'application/json'},
                timeout=10
            )
            if response.status_code == 200:
                success_count += 1
                print(f"✅ Record {i+1}/{num_records} stored successfully")
            else:
                print(f"❌ Record {i+1}/{num_records} failed: {response.status_code}")
        except Exception as e:
            print(f"❌ Record {i+1}/{num_records} error: {e}")
    
    print(f"\n📝 Successfully stored {success_count}/{num_records} records")
    return success_count

def run_comprehensive_test():
    """Run all tests in sequence"""
    print("🚀 Starting Comprehensive API Test Suite")
    print("=" * 50)
    
    # Test health check first
    if not test_health_check():
        print("❌ Health check failed. Make sure the API server is running.")
        return
    
    # Populate some sample data first
    populate_sample_data(15)
    
    # Run all endpoint tests
    test_store_feedback()
    test_analytics()
    test_trends()
    test_intent_performance()
    test_user_engagement()
    test_category_insights()
    
    print("\n" + "=" * 50)
    print("✅ Test suite completed!")

def generate_curl_commands():
    """Generate curl commands for manual testing"""
    print("\n📋 CURL Commands for Manual Testing:")
    print("=" * 40)
    
    sample_data = generate_sample_feedback()
    
    commands = [
        # Health check
        f"curl -X GET {API_BASE_URL}/health",
        
        # Store feedback
        f"curl -X POST {API_BASE_URL}/feedback \\\n  -H 'Content-Type: application/json' \\\n  -d '{json.dumps(sample_data)}'",
        
        # Analytics
        f"curl -X GET {API_BASE_URL}/feedback/analytics",
        
        # Trends
        f"curl -X GET {API_BASE_URL}/feedback/trends",
        f"curl -X GET {API_BASE_URL}/feedback/trends?days=7",
        
        # Intent performance
        f"curl -X GET {API_BASE_URL}/feedback/intents",
        
        # User engagement
        f"curl -X GET {API_BASE_URL}/feedback/engagement",
        f"curl -X GET {API_BASE_URL}/feedback/engagement?limit=5",
        
        # Category insights
        f"curl -X GET {API_BASE_URL}/feedback/categories"
    ]
    
    for i, cmd in enumerate(commands, 1):
        print(f"\n{i}. {cmd}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Test Neo4j Feedback API")
    parser.add_argument("--base-url", default="http://localhost:8000/api", 
                       help="Base URL for the API")
    parser.add_argument("--populate", type=int, default=0,
                       help="Number of sample records to populate")
    parser.add_argument("--test", action="store_true",
                       help="Run comprehensive test suite")
    parser.add_argument("--curl", action="store_true",
                       help="Generate curl commands for manual testing")
    
    args = parser.parse_args()
    
    # Update base URL if provided
    API_BASE_URL = args.base_url
    
    if args.curl:
        generate_curl_commands()
    elif args.populate > 0:
        populate_sample_data(args.populate)
    elif args.test:
        run_comprehensive_test()
    else:
        # Default: run comprehensive test
        run_comprehensive_test()