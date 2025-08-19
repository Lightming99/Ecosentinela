from neo4j import GraphDatabase
from neo4j.exceptions import ServiceUnavailable, TransientError
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
import logging
import json

logger = logging.getLogger(__name__)

class Neo4jService:
    def __init__(self, uri: str, username: str, password: str, database: str = "neo4j"):
        """Initialize Neo4j connection"""
        self.driver = GraphDatabase.driver(uri, auth=(username, password))
        self.database = database
        self._verify_connection()
        self._create_constraints_and_indexes()
    
    def close(self):
        """Close the Neo4j driver connection"""
        if self.driver:
            self.driver.close()
    
    def _verify_connection(self):
        """Verify Neo4j connection is working"""
        try:
            with self.driver.session(database=self.database) as session:
                session.run("RETURN 1")
            logger.info("Neo4j connection verified successfully")
        except ServiceUnavailable as e:
            logger.error(f"Neo4j connection failed: {e}")
            raise
    
    def _create_constraints_and_indexes(self):
        """Create necessary constraints and indexes for performance"""
        constraints_and_indexes = [
            # Indexes for performance - no unique constraints needed since we removed IDs
            "CREATE INDEX feedback_timestamp_idx IF NOT EXISTS FOR (f:Feedback) ON (f.timestamp)",
            "CREATE INDEX feedback_type_idx IF NOT EXISTS FOR (f:Feedback) ON (f.feedback_type)",
            "CREATE INDEX feedback_rating_idx IF NOT EXISTS FOR (f:Feedback) ON (f.rating_stars)"
        ]
        
        with self.driver.session(database=self.database) as session:
            for constraint_or_index in constraints_and_indexes:
                try:
                    session.run(constraint_or_index)
                except Exception as e:
                    logger.warning(f"Constraint/Index creation warning: {e}")
        
        logger.info("Neo4j constraints and indexes created/verified")
    
    def store_feedback(self, feedback_data: Dict[str, Any]) -> bool:
        """
        Store simplified feedback data in Neo4j with comprehensive logging

        Args:
            feedback_data: Dictionary containing feedback information
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            logger.info("🗄️ NEO4J STORAGE PROCESS STARTED")
            logger.info(f"   Target Database: {self.database}")
            logger.info(f"   Feedback Type: {feedback_data.get('feedback_type')}")
            logger.info(f"   Rating: {feedback_data.get('rating_stars', 0)}/5 stars")

            with self.driver.session(database=self.database) as session:
                logger.info("✅ Neo4j session established successfully")
                result = session.execute_write(self._create_feedback_transaction, feedback_data)

                if result:
                    logger.info("✅ FEEDBACK SUCCESSFULLY WRITTEN TO NEO4J!")
                    logger.info(f"   Database: {self.database}")
                    logger.info("🎯 DATA TRANSFER COMPLETE: Flutter → Neo4j")
                else:
                    logger.error("❌ Neo4j write transaction returned False")

                return result

        except Exception as e:
            logger.error("💥 NEO4J STORAGE ERROR:")
            logger.error(f"   Database: {self.database}")
            logger.error(f"   Error: {e}")
            return False
    
    def _create_feedback_transaction(self, tx, feedback_data: Dict[str, Any]) -> bool:
        """Transaction to create a simple feedback record with only essential information"""
        try:
            # Extract essential feedback data - no IDs needed
            user_query = feedback_data['user_query']
            bot_response = feedback_data['bot_response']
            feedback_type = feedback_data['feedback_type']
            user_comment = feedback_data.get('user_comment', '')
            rating_stars = feedback_data.get('rating_stars', 0)
            timestamp = feedback_data['timestamp']

            logger.info("🔄 CREATING SIMPLE FEEDBACK RECORD:")
            logger.info(f"   User Query: {user_query[:50]}...")
            logger.info(f"   Bot Response: {bot_response[:50]}...")
            logger.info(f"   Feedback Type: {feedback_type}")
            logger.info(f"   User Comment: {user_comment}")
            logger.info(f"   Rating Stars: {rating_stars}/5")

            # Create a simple feedback record with only the essential data you want
            query = """
            CREATE (f:Feedback {
                // Core feedback data - exactly what you want to store
                user_query: $user_query,
                bot_response: $bot_response,
                feedback_type: $feedback_type,
                user_comment: $user_comment,
                rating_stars: $rating_stars,
                
                // Essential metadata
                timestamp: datetime($timestamp),
                created_at: datetime()
            })
            RETURN id(f) as node_id
            """

            result = tx.run(query, {
                'user_query': user_query,
                'bot_response': bot_response,
                'feedback_type': feedback_type,
                'user_comment': user_comment,
                'rating_stars': rating_stars,
                'timestamp': timestamp
            })

            stored_record = result.single()
            if stored_record:
                logger.info("✅ SIMPLE FEEDBACK RECORD CREATED SUCCESSFULLY!")
                logger.info(f"   Node ID: {stored_record['node_id']}")
                return True
            else:
                logger.error("❌ Failed to create feedback record")
                return False

        except Exception as e:
            logger.error(f"❌ Transaction error while creating feedback: {e}")
            raise
    
    def get_overall_analytics(self) -> Dict[str, Any]:
        """Get overall feedback analytics"""
        try:
            with self.driver.session(database=self.database) as session:
                result = session.execute_read(self._get_overall_analytics_query)
                return result
        except Exception as e:
            logger.error(f"Error getting overall analytics: {e}")
            return {}
    
    def _get_overall_analytics_query(self, tx) -> Dict[str, Any]:
        """Query for overall analytics"""
        query = """
        MATCH (f:Feedback)
        WITH 
            count(f) as total_feedback,
            sum(CASE WHEN f.feedback_type = 'positive' THEN 1 ELSE 0 END) as positive_count,
            sum(CASE WHEN f.feedback_type = 'negative' THEN 1 ELSE 0 END) as negative_count
        RETURN 
            total_feedback,
            positive_count,
            negative_count,
            CASE WHEN total_feedback > 0 
                 THEN round((positive_count * 100.0) / total_feedback, 2) 
                 ELSE 0 END as satisfaction_rate
        """
        
        result = tx.run(query)
        record = result.single()
        
        if record:
            return {
                'total_feedback': record['total_feedback'],
                'positive_count': record['positive_count'],
                'negative_count': record['negative_count'],
                'satisfaction_rate': record['satisfaction_rate']
            }
        return {}
    
    def get_intent_performance(self) -> List[Dict[str, Any]]:
        """Get intent performance analytics"""
        try:
            with self.driver.session(database=self.database) as session:
                result = session.execute_read(self._get_intent_performance_query)
                return result
        except Exception as e:
            logger.error(f"Error getting intent performance: {e}")
            return []
    
    def _get_intent_performance_query(self, tx) -> List[Dict[str, Any]]:
        """Query for intent performance using the comprehensive feedback model"""
        query = """
        MATCH (f:Feedback)
        WHERE f.detected_intent IS NOT NULL AND f.detected_intent <> ''
        WITH 
            f.detected_intent as intent_name,
            count(f) as total_feedback,
            sum(CASE WHEN f.feedback_type = 'positive' THEN 1 ELSE 0 END) as positive_count,
            sum(CASE WHEN f.feedback_type = 'negative' THEN 1 ELSE 0 END) as negative_count,
            avg(f.confidence_score) as avg_confidence
        WHERE total_feedback > 0
        RETURN 
            intent_name,
            total_feedback,
            positive_count,
            negative_count,
            round((positive_count * 100.0) / total_feedback, 2) as satisfaction_rate,
            round(avg_confidence, 3) as avg_confidence
        ORDER BY satisfaction_rate ASC, total_feedback DESC
        """
        
        result = tx.run(query)
        return [dict(record) for record in result]
    
    def get_feedback_trends(self, days: int = 30) -> List[Dict[str, Any]]:
        """Get feedback trends over time"""
        try:
            with self.driver.session(database=self.database) as session:
                result = session.execute_read(self._get_feedback_trends_query, days)
                return result
        except Exception as e:
            logger.error(f"Error getting feedback trends: {e}")
            return []
    
    def _get_feedback_trends_query(self, tx, days: int) -> List[Dict[str, Any]]:
        """Query for feedback trends"""
        query = """
        MATCH (f:Feedback)
        WHERE f.timestamp >= datetime() - duration({days: $days})
        WITH 
            date(f.timestamp) as feedback_date,
            f.feedback_type as feedback_type,
            count(f) as count
        RETURN 
            feedback_date,
            feedback_type,
            count
        ORDER BY feedback_date DESC, feedback_type
        """
        
        result = tx.run(query, days=days)
        # Convert Neo4j Date objects to strings for JSON serialization
        return [
            {
                'feedback_date': record['feedback_date'].isoformat() if record['feedback_date'] else None,
                'feedback_type': record['feedback_type'],
                'count': record['count']
            }
            for record in result
        ]

    def get_user_engagement(self, limit: int = 20) -> List[Dict[str, Any]]:
        """Get user engagement metrics"""
        try:
            with self.driver.session(database=self.database) as session:
                result = session.execute_read(self._get_user_engagement_query, limit)
                return result
        except Exception as e:
            logger.error(f"Error getting user engagement: {e}")
            return []
    
    def _get_user_engagement_query(self, tx, limit: int) -> List[Dict[str, Any]]:
        """Query for user engagement using the comprehensive feedback model"""
        query = """
        MATCH (f:Feedback)
        WITH 
            f.user_id as user_id,
            count(f) as total_feedback,
            sum(CASE WHEN f.feedback_type = 'positive' THEN 1 ELSE 0 END) as positive_feedback,
            min(f.timestamp) as first_feedback,
            max(f.timestamp) as last_feedback
        RETURN 
            user_id,
            total_feedback,
            positive_feedback,
            first_feedback,
            last_feedback
        ORDER BY total_feedback DESC
        LIMIT $limit
        """
        
        result = tx.run(query, limit=limit)
        # Convert Neo4j DateTime objects to strings for JSON serialization
        return [
            {
                'user_id': record['user_id'],
                'total_feedback': record['total_feedback'],
                'positive_feedback': record['positive_feedback'],
                'first_feedback': record['first_feedback'].isoformat() if record['first_feedback'] else None,
                'last_feedback': record['last_feedback'].isoformat() if record['last_feedback'] else None
            }
            for record in result
        ]

    def get_category_insights(self) -> List[Dict[str, Any]]:
        """Get feedback category insights"""
        try:
            with self.driver.session(database=self.database) as session:
                result = session.execute_read(self._get_category_insights_query)
                return result
        except Exception as e:
            logger.error(f"Error getting category insights: {e}")
            return []
    
    def _get_category_insights_query(self, tx) -> List[Dict[str, Any]]:
        """Query for category insights"""
        query = """
        MATCH (f:Feedback)
        WHERE size(f.categories) > 0
        UNWIND f.categories as category
        WITH 
            category,
            f.feedback_type as feedback_type,
            count(f) as count
        RETURN 
            category,
            feedback_type,
            count
        ORDER BY category, feedback_type
        """
        
        result = tx.run(query)
        return [dict(record) for record in result]
    
    def health_check(self) -> Dict[str, Any]:
        """Check Neo4j service health"""
        try:
            with self.driver.session(database=self.database) as session:
                result = session.run("RETURN 1 as status")
                record = result.single()
                
                if record and record['status'] == 1:
                    return {
                        'status': 'healthy',
                        'database': 'connected',
                        'database_name': self.database,
                        'timestamp': datetime.now().isoformat()
                    }
                else:
                    return {
                        'status': 'unhealthy',
                        'database': 'disconnected',
                        'database_name': self.database,
                        'timestamp': datetime.now().isoformat()
                    }
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return {
                'status': 'unhealthy',
                'database': 'error',
                'database_name': self.database,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }