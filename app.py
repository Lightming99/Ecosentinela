#!/usr/bin/env python3
"""
Main application file for Neo4j Feedback Integration
UN Environmental Governance App - Feedback Analytics API

Usage:
    python app.py
    
Environment Variables:
    NEO4J_URI - Neo4j database URI (default: bolt://localhost:7687)
    NEO4J_USERNAME - Neo4j username (default: neo4j)
    NEO4J_PASSWORD - Neo4j password (required)
    FLASK_HOST - Flask host (default: 0.0.0.0)
    FLASK_PORT - Flask port (default: 8000)
    FLASK_DEBUG - Enable debug mode (default: True)
"""

import os
import sys
import logging
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Add current directory to path for imports
sys.path.append(str(Path(__file__).parent))

# Import Flask app
try:
    from Flask_api import app, init_neo4j, cleanup
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Make sure all required packages are installed:")
    print("pip install -r requirements.txt")
    sys.exit(1)

def setup_logging():
    """Configure application logging"""
    log_level = os.getenv('LOG_LEVEL', 'INFO').upper()
    log_file = os.getenv('LOG_FILE', None)
    
    # Create logs directory if it doesn't exist
    if log_file:
        log_path = Path(log_file)
        log_path.parent.mkdir(exist_ok=True)
    
    # Configure logging
    logging_config = {
        'level': getattr(logging, log_level, logging.INFO),
        'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        'datefmt': '%Y-%m-%d %H:%M:%S'
    }
    
    if log_file:
        logging_config['filename'] = log_file
        logging_config['filemode'] = 'a'
    
    logging.basicConfig(**logging_config)
    
    # Set specific loggers
    logging.getLogger('neo4j').setLevel(logging.WARNING)
    logging.getLogger('urllib3').setLevel(logging.WARNING)

def validate_environment():
    """Validate required environment variables"""
    required_vars = ['NEO4J_PASSWORD']
    optional_vars = {
        'NEO4J_URI': 'bolt://localhost:7687',
        'NEO4J_USERNAME': 'neo4j',
        'FLASK_HOST': '0.0.0.0',
        'FLASK_PORT': '8000',
        'FLASK_DEBUG': 'True'
    }
    
    # Check required variables
    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        print("❌ Missing required environment variables:")
        for var in missing_vars:
            print(f"   - {var}")
        print("\nPlease set these variables in your .env file or environment")
        return False
    
    # Set defaults for optional variables
    for var, default in optional_vars.items():
        if not os.getenv(var):
            os.environ[var] = default
    
    return True

def print_startup_info():
    """Print application startup information"""
    print("=" * 60)
    print("🚀 Neo4j Feedback Integration API")
    print("🌍 UN Environmental Governance App")
    print("=" * 60)
    
    print(f"🗄️ Neo4j URI: {os.getenv('NEO4J_URI')}")
    print(f"👤 Neo4j User: {os.getenv('NEO4J_USERNAME')}")
    print(f"🌐 Flask Host: {os.getenv('FLASK_HOST')}")
    print(f"🚪 Flask Port: {os.getenv('FLASK_PORT')}")
    print(f"🐛 Debug Mode: {os.getenv('FLASK_DEBUG')}")
    
    print("\n📡 Available Endpoints:")
    print("   GET  /api/health              - Service health check")
    print("   POST /api/feedback            - Store user feedback")
    print("   GET  /api/feedback/analytics  - Overall analytics")
    print("   GET  /api/feedback/trends     - Feedback trends")
    print("   GET  /api/feedback/intents    - Intent performance")
    print("   GET  /api/feedback/engagement - User engagement")
    print("   GET  /api/feedback/categories - Category insights")
    
    print("\n🧪 Test the API:")
    print("   python test_api.py --test")
    print("=" * 60)

def main():
    """Main application entry point"""
    try:
        # Setup logging
        setup_logging()
        logger = logging.getLogger(__name__)
        
        # Validate environment
        if not validate_environment():
            sys.exit(1)
        
        # Print startup information
        print_startup_info()
        
        # Initialize Neo4j service
        logger.info("Initializing Neo4j service...")
        init_neo4j()
        logger.info("Neo4j service initialized successfully")
        
        # Get Flask configuration
        host = os.getenv('FLASK_HOST', '0.0.0.0')
        port = int(os.getenv('FLASK_PORT', 8000))
        debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
        
        # Register cleanup function
        import atexit
        atexit.register(cleanup)
        
        # Start the Flask application
        logger.info(f"Starting Flask server on {host}:{port}")
        app.run(host=host, port=port, debug=debug, threaded=True)
        
    except KeyboardInterrupt:
        print("\n\n🛑 Shutting down gracefully...")
        logger.info("Application shutdown requested by user")
    except Exception as e:
        logger.error(f"Application startup failed: {e}")
        print(f"❌ Failed to start application: {e}")
        print("\n🔧 Troubleshooting:")
        print("1. Check your .env file configuration")
        print("2. Ensure Neo4j is running and accessible")
        print("3. Verify all dependencies are installed")
        print("4. Check the logs for detailed error information")
        sys.exit(1)
    finally:
        cleanup()
        logger.info("Application cleanup completed")

if __name__ == "__main__":
    main()