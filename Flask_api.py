from flask import Flask, request, jsonify
from flask_cors import CORS
from marshmallow import Schema, fields, ValidationError, EXCLUDE
import os
import logging
from datetime import datetime
from typing import Dict, Any
import traceback

# Import our Neo4j service
from neo4j_service import Neo4jService

# Configure logging with more detailed format
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
    handlers=[
        logging.StreamHandler(),  # Console output
        logging.FileHandler('feedback_api.log')  # File output
    ]
)
logger = logging.getLogger(__name__)

# Enable detailed request logging
werkzeug_logger = logging.getLogger('werkzeug')
werkzeug_logger.setLevel(logging.INFO)

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter web app

# Initialize Neo4j service
neo4j_service = None

def init_neo4j():
    """Initialize Neo4j service with environment variables"""
    global neo4j_service
    try:
        neo4j_uri = os.getenv('NEO4J_URI', 'bolt://localhost:7687')
        neo4j_username = os.getenv('NEO4J_USERNAME', 'neo4j')
        neo4j_password = os.getenv('NEO4J_PASSWORD', 'password')
        neo4j_database = os.getenv('NEO4J_DATABASE', 'neo4j')
        neo4j_service = Neo4jService(neo4j_uri, neo4j_username, neo4j_password, neo4j_database)
        logger.info("Neo4j service initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Neo4j service: {e}")
        raise

# Validation schemas
class FeedbackSchema(Schema):
    # Core feedback data only - no IDs needed
    user_query = fields.Str(required=True)  # What user asked
    bot_response = fields.Str(required=True)  # What bot replied
    feedback_type = fields.Str(required=True, validate=lambda x: x in ['positive', 'negative'])
    user_comment = fields.Str(missing='')  # User's detailed feedback/comment - can be empty string
    rating_stars = fields.Int(required=True, validate=lambda x: 1 <= x <= 5)  # Star rating 1-5 (required)

    # Optional fields that Flutter might send
    message_id = fields.Str(missing='')  # Optional message ID
    categories = fields.List(fields.Str(), missing=[])  # Optional categories list

    # Simple metadata - allow flexible timestamp formats
    timestamp = fields.Str(required=True)

    class Meta:
        # Allow unknown fields to be ignored
        unknown = EXCLUDE

feedback_schema = FeedbackSchema()

def create_error_response(message: str, status_code: int = 400, details: Dict = None) -> tuple:
    """Create standardized error response"""
    error_response = {
        'success': False,
        'error': message,
        'timestamp': datetime.now().isoformat()
    }
    if details:
        error_response['details'] = details
    
    return jsonify(error_response), status_code

def create_success_response(data: Any = None, message: str = "Success") -> Dict:
    """Create standardized success response"""
    response = {
        'success': True,
        'message': message,
        'timestamp': datetime.now().isoformat()
    }
    if data is not None:
        response['data'] = data
    
    return jsonify(response)

@app.route('/api/health', methods=['GET'])
def health_check():
    """Service health check endpoint"""
    try:
        if neo4j_service is None:
            return create_error_response("Neo4j service not initialized", 503)
        
        health_status = neo4j_service.health_check()
        
        if health_status['status'] == 'healthy':
            return create_success_response(health_status, "Service is healthy")
        else:
            return create_error_response("Service is unhealthy", 503, health_status)
            
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return create_error_response("Health check failed", 500, {'error': str(e)})

@app.route('/api/feedback', methods=['POST'])
def store_feedback():
    """Store user feedback endpoint with detailed logging"""
    client_ip = request.remote_addr
    user_agent = request.headers.get('User-Agent', 'Unknown')

    logger.info("=" * 80)
    logger.info(f"📥 NEW FEEDBACK REQUEST RECEIVED")
    logger.info(f"   📍 Client IP: {client_ip}")
    logger.info(f"   🌐 User Agent: {user_agent}")
    logger.info(f"   📅 Timestamp: {datetime.now().isoformat()}")
    logger.info(f"   🔗 Request URL: {request.url}")
    logger.info(f"   📦 Content Type: {request.content_type}")
    logger.info("=" * 80)

    try:
        # Log request headers for debugging
        logger.info("📋 REQUEST HEADERS:")
        for header, value in request.headers:
            logger.info(f"   {header}: {value}")

        # Validate request data
        if not request.json:
            logger.error("❌ VALIDATION FAILED: No JSON data provided")
            return create_error_response("No JSON data provided")
        
        logger.info("✅ JSON data received successfully")
        logger.info(f"📝 RAW REQUEST DATA:")
        logger.info(f"   {request.json}")

        # Validate against schema
        try:
            validated_data = feedback_schema.load(request.json)
            logger.info("✅ SCHEMA VALIDATION: Passed")
            logger.info(f"📊 VALIDATED FEEDBACK DATA:")
            logger.info(f"   User Query: {validated_data.get('user_query', '')[:100]}...")
            logger.info(f"   Bot Response: {validated_data.get('bot_response', '')[:100]}...")
            logger.info(f"   Feedback Type: {validated_data.get('feedback_type')}")
            logger.info(f"   User Comment: {validated_data.get('user_comment', 'No comment')}")
            logger.info(f"   Rating Stars: {validated_data.get('rating_stars', 0)}/5")
        except ValidationError as e:
            logger.error("❌ SCHEMA VALIDATION FAILED:")
            for field, errors in e.messages.items():
                logger.error(f"   {field}: {errors}")
            return create_error_response("Validation error", 400, e.messages)
        
        # Validate timestamp format
        try:
            parsed_timestamp = datetime.fromisoformat(validated_data['timestamp'].replace('Z', '+00:00'))
            logger.info(f"✅ TIMESTAMP VALIDATION: Passed - {parsed_timestamp}")
        except ValueError as e:
            logger.error(f"❌ TIMESTAMP VALIDATION FAILED: {e}")
            return create_error_response("Invalid timestamp format. Use ISO 8601 format.")
        
        # Check Neo4j service availability
        if neo4j_service is None:
            logger.error("❌ NEO4J SERVICE: Not available")
            return create_error_response("Neo4j service not available", 503)
        
        logger.info("✅ NEO4J SERVICE: Available and ready")

        # Store in Neo4j
        logger.info("🚀 ATTEMPTING TO STORE FEEDBACK IN NEO4J...")
        logger.info(f"   Database: {neo4j_service.database}")
        logger.info(f"   URI: {os.getenv('NEO4J_URI')}")

        success = neo4j_service.store_feedback(validated_data)
        
        if success:
            logger.info("✅ FEEDBACK STORAGE: SUCCESS!")
            logger.info(f"   Stored in database: {neo4j_service.database}")
            logger.info(f"   Feedback Type: {validated_data['feedback_type']}")
            logger.info(f"   Rating: {validated_data.get('rating_stars', 0)}/5 stars")
            logger.info("🎉 FEEDBACK SUCCESSFULLY TRANSFERRED FROM FLUTTER TO NEO4J!")
            logger.info("=" * 80)

            return create_success_response(
                data={
                    'database': neo4j_service.database,
                    'stored_at': datetime.now().isoformat(),
                    'feedback_type': validated_data['feedback_type'],
                    'rating_stars': validated_data.get('rating_stars', 0)
                },
                message="Feedback stored successfully in Neo4j database"
            )
        else:
            logger.error("❌ FEEDBACK STORAGE: FAILED!")
            logger.error("   Neo4j storage operation returned False")
            logger.error("=" * 80)
            return create_error_response("Failed to store feedback in Neo4j", 500)

    except Exception as e:
        logger.error("💥 CRITICAL ERROR IN FEEDBACK PROCESSING:")
        logger.error(f"   Error Type: {type(e).__name__}")
        logger.error(f"   Error Message: {str(e)}")
        logger.error("   Stack Trace:")
        for line in traceback.format_exc().splitlines():
            logger.error(f"   {line}")
        logger.error("=" * 80)
        return create_error_response("Internal server error", 500, {'error': str(e)})

@app.route('/api/feedback/analytics', methods=['GET'])
def get_analytics():
    """Get overall feedback analytics"""
    try:
        if neo4j_service is None:
            return create_error_response("Neo4j service not available", 503)
        
        analytics = neo4j_service.get_overall_analytics()
        
        if analytics:
            return create_success_response(analytics, "Analytics retrieved successfully")
        else:
            return create_success_response({
                'total_feedback': 0,
                'positive_count': 0,
                'negative_count': 0,
                'satisfaction_rate': 0
            }, "No feedback data available")
            
    except Exception as e:
        logger.error(f"Get analytics error: {e}")
        return create_error_response("Failed to get analytics", 500, {'error': str(e)})

@app.route('/api/feedback/trends', methods=['GET'])
def get_trends():
    """Get feedback trends over time"""
    try:
        if neo4j_service is None:
            return create_error_response("Neo4j service not available", 503)
        
        # Get days parameter, default to 30
        days = request.args.get('days', 30, type=int)
        
        if days <= 0 or days > 365:
            return create_error_response("Days parameter must be between 1 and 365")
        
        trends = neo4j_service.get_feedback_trends(days)
        
        return create_success_response(trends, f"Trends for last {days} days retrieved successfully")
        
    except Exception as e:
        logger.error(f"Get trends error: {e}")
        return create_error_response("Failed to get trends", 500, {'error': str(e)})

@app.route('/api/feedback/intents', methods=['GET'])
def get_intent_performance():
    """Get intent performance analytics"""
    try:
        if neo4j_service is None:
            return create_error_response("Neo4j service not available", 503)
        
        intents = neo4j_service.get_intent_performance()
        
        return create_success_response(intents, "Intent performance retrieved successfully")
        
    except Exception as e:
        logger.error(f"Get intent performance error: {e}")
        return create_error_response("Failed to get intent performance", 500, {'error': str(e)})

@app.route('/api/feedback/engagement', methods=['GET'])
def get_user_engagement():
    """Get user engagement metrics"""
    try:
        if neo4j_service is None:
            return create_error_response("Neo4j service not available", 503)
        
        # Get limit parameter, default to 20
        limit = request.args.get('limit', 20, type=int)
        
        if limit <= 0 or limit > 100:
            return create_error_response("Limit parameter must be between 1 and 100")
        
        engagement = neo4j_service.get_user_engagement(limit)
        
        return create_success_response(engagement, f"Top {limit} user engagement metrics retrieved successfully")
        
    except Exception as e:
        logger.error(f"Get user engagement error: {e}")
        return create_error_response("Failed to get user engagement", 500, {'error': str(e)})

@app.route('/api/feedback/categories', methods=['GET'])
def get_category_insights():
    """Get feedback category insights"""
    try:
        if neo4j_service is None:
            return create_error_response("Neo4j service not available", 503)
        
        categories = neo4j_service.get_category_insights()
        
        return create_success_response(categories, "Category insights retrieved successfully")
        
    except Exception as e:
        logger.error(f"Get category insights error: {e}")
        return create_error_response("Failed to get category insights", 500, {'error': str(e)})

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return create_error_response("Endpoint not found", 404)

@app.errorhandler(405)
def method_not_allowed(error):
    """Handle 405 errors"""
    return create_error_response("Method not allowed", 405)

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    logger.error(f"Internal server error: {error}")
    return create_error_response("Internal server error", 500)

def cleanup():
    """Cleanup resources on app shutdown"""
    global neo4j_service
    if neo4j_service:
        neo4j_service.close()
        logger.info("Neo4j service connection closed")

if __name__ == '__main__':
    try:
        # Initialize Neo4j service
        init_neo4j()
        
        # Get configuration from environment
        port = int(os.getenv('FLASK_PORT', 8000))
        debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
        host = os.getenv('FLASK_HOST', '0.0.0.0')
        
        logger.info(f"Starting Flask API server on {host}:{port}")
        
        # Register cleanup function
        import atexit
        atexit.register(cleanup)
        
        # Run the application
        app.run(host=host, port=port, debug=debug)
        
    except Exception as e:
        logger.error(f"Failed to start application: {e}")
        logger.error(traceback.format_exc())
    finally:
        cleanup()