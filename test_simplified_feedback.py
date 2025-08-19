#!/usr/bin/env python3
"""
Test script for ultra-simplified feedback storage
Tests the new structure with NO IDs - just pure feedback data
"""

import requests
import json
from datetime import datetime
import time

# API endpoint
API_BASE_URL = "http://localhost:8000"

def test_ultra_simple_feedback():
    """Test storing ultra-simplified feedback data - NO IDs needed"""
    print("🧪 Testing Ultra-Simple Feedback Storage (No IDs)")
    print("=" * 60)

    # Create sample feedback data with ONLY the essential information
    feedback_data = {
        # Core feedback data - exactly what you want stored
        "user_query": "How can I reduce plastic waste in my daily life?",
        "bot_response": "Here are practical ways to reduce plastic waste: 1) Use reusable water bottles and coffee cups, 2) Bring your own shopping bags, 3) Choose products with minimal packaging, 4) Avoid single-use utensils, 5) Buy in bulk when possible, 6) Use glass containers for food storage.",
        "feedback_type": "positive",
        "user_comment": "This was exactly what I needed! Very actionable advice that I can start using immediately.",
        "rating_stars": 5,

        # Just timestamp for when this happened
        "timestamp": datetime.now().isoformat() + "Z"
    }

    print("📝 Ultra-Simple Feedback Data:")
    print(f"   User Query: {feedback_data['user_query']}")
    print(f"   Bot Response: {feedback_data['bot_response'][:60]}...")
    print(f"   Feedback Type: {feedback_data['feedback_type']}")
    print(f"   User Comment: {feedback_data['user_comment']}")
    print(f"   Rating Stars: {feedback_data['rating_stars']}/5 ⭐")
    print()

    try:
        # Send POST request to store feedback
        print("🚀 Sending simplified feedback to API...")
        response = requests.post(
            f"{API_BASE_URL}/api/feedback",
            json=feedback_data,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )

        print(f"📊 Response Status: {response.status_code}")
        print(f"📄 Response Data:")
        print(json.dumps(response.json(), indent=2))

        if response.status_code == 200:
            print("\n✅ SUCCESS: Ultra-simple feedback stored successfully!")
            print("🎯 Check your Neo4j database - it will have ONE clean record with just:")
            print("   • user_query")
            print("   • bot_response")
            print("   • feedback_type")
            print("   • user_comment")
            print("   • rating_stars")
            print("   • timestamp")
        else:
            print(f"\n❌ ERROR: Failed to store feedback (Status: {response.status_code})")

    except requests.exceptions.ConnectionError:
        print("❌ ERROR: Could not connect to API server")
        print("   Make sure your Flask API is running on localhost:8000")
    except Exception as e:
        print(f"❌ ERROR: {e}")

def simulate_flutter_negative_feedback():
    """Simulate negative feedback from Flutter app"""
    print("\n📱 Simulating Flutter App - Negative Feedback")
    print("=" * 60)

    # This is the format your Flutter app should send - NO IDs!
    flutter_feedback = {
        "user_query": "What are the best renewable energy options for homes?",
        "bot_response": "Renewable energy options for homes include solar panels, wind turbines, and geothermal systems.",
        "feedback_type": "negative",
        "user_comment": "Too vague! I need specific information about costs, installation requirements, and which option works best in different climates.",
        "rating_stars": 2,
        "timestamp": datetime.now().isoformat() + "Z"
    }

    print("📱 Flutter Negative Feedback:")
    print(f"   User Query: {flutter_feedback['user_query']}")
    print(f"   Bot Response: {flutter_feedback['bot_response']}")
    print(f"   Feedback Type: {flutter_feedback['feedback_type']} ❌")
    print(f"   User Comment: {flutter_feedback['user_comment']}")
    print(f"   Rating: {flutter_feedback['rating_stars']}/5 stars")

    try:
        response = requests.post(
            f"{API_BASE_URL}/api/feedback",
            json=flutter_feedback,
            headers={
                'Content-Type': 'application/json',
                'User-Agent': 'Flutter-Environmental-App'
            },
            timeout=10
        )

        print(f"\n📊 Flutter Response Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ SUCCESS: Flutter negative feedback received and stored!")
            print("📊 This will help improve the bot's responses!")
        else:
            print("❌ ERROR: Failed to store Flutter feedback")
            print(json.dumps(response.json(), indent=2))

    except Exception as e:
        print(f"❌ ERROR processing Flutter feedback: {e}")

if __name__ == "__main__":
    print("🚀 Ultra-Simple Neo4j Feedback Test")
    print("🌍 No IDs Required - Just Pure Feedback Data")
    print("=" * 60)

    # Test ultra-simple feedback
    test_ultra_simple_feedback()

    # Simulate Flutter negative feedback
    simulate_flutter_negative_feedback()

    print("\n" + "=" * 60)
    print("✅ Test completed!")
    print("📋 Your Flutter app now only needs to send:")
    print("   • user_query (what user asked)")
    print("   • bot_response (what bot replied)")
    print("   • feedback_type (positive/negative)")
    print("   • user_comment (user's detailed feedback)")
    print("   • rating_stars (0-5 stars)")
    print("   • timestamp (when it happened)")
    print("\n🗄️ Neo4j will store each as ONE simple, clean record!")
