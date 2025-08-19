# Neo4j Feedback Integration API

🌍 **UN Environmental Governance App - Feedback Analytics System**

A comprehensive feedback collection and analytics system that integrates Flutter mobile app with Neo4j graph database through a Flask REST API, designed for environmental governance applications.

## 📋 Table of Contents

- [System Architecture](#system-architecture)
- [Components Overview](#components-overview)
- [Features](#features)
- [Installation & Setup](#installation--setup)
- [Configuration](#configuration)
- [API Documentation](#api-documentation)
- [Database Schema](#database-schema)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🏗️ System Architecture

```
┌─────────────────┐    HTTP/JSON     ┌─────────────────┐    Bolt Protocol    ┌─────────────────┐
│                 │    (Port 8000)   │                 │    (Port 7687)      │                 │
│  Flutter App    │ ◄──────────────► │   Flask API     │ ◄─────────────────► │   Neo4j DB      │
│  (Mobile/Web)   │                  │  (Python REST)  │                     │  (Graph Store)  │
│                 │                  │                 │                     │                 │
└─────────────────┘                  └─────────────────┘                     └─────────────────┘
        │                                      │                                      │
        │                                      │                                      │
        ▼                                      ▼                                      ▼
┌─────────────────┐                  ┌─────────────────┐                     ┌─────────────────┐
│ User Feedback   │                  │ Data Processing │                     │ Analytics Store │
│ • Star Rating   │                  │ • Validation    │                     │ • Feedback Nodes│
│ • Comments      │                  │ • Logging       │                     │ • Relationships │
│ • Categories    │                  │ • Error Handle  │                     │ • Indexes       │
└─────────────────┘                  └─────────────────┘                     └─────────────────┘
```

## 🧩 Components Overview

### 1. **Flask API Server** (`Flask_api.py`)
- **Purpose**: RESTful API backend for handling feedback operations
- **Port**: 8000 (configurable)
- **Key Features**:
  - Data validation using Marshmallow schemas
  - Comprehensive error handling and logging
  - CORS support for cross-origin requests
  - Real-time feedback processing

### 2. **Neo4j Service Layer** (`neo4j_service.py`)
- **Purpose**: Database abstraction layer for Neo4j operations
- **Key Features**:
  - Connection management and health checks
  - Transaction-based operations
  - Query optimization with indexes
  - Analytics computation

### 3. **Application Runner** (`app.py`)
- **Purpose**: Main entry point and configuration manager
- **Key Features**:
  - Environment variable validation
  - Logging configuration
  - Graceful startup/shutdown
  - Service initialization

### 4. **Flutter Integration**
- **Purpose**: Mobile/web frontend for user interactions
- **Key Features**:
  - Star rating system (1-5 stars)
  - Comment collection
  - Category selection
  - Real-time feedback submission

## ✨ Features

### 📊 Analytics & Reporting
- **Overall Analytics**: Total feedback, satisfaction rates, positive/negative ratios
- **Trend Analysis**: Time-based feedback trends (daily, weekly, monthly)
- **Intent Performance**: AI intent recognition success rates
- **User Engagement**: User interaction patterns and metrics
- **Category Insights**: Feedback categorization analysis

### 🔒 Data Management
- **Simplified Storage**: Clean, focused data model without unnecessary IDs
- **Real-time Processing**: Immediate feedback storage and retrieval
- **Data Validation**: Schema-based input validation
- **Error Recovery**: Robust error handling and logging

### 🚀 Performance
- **Indexed Queries**: Optimized database indexes for fast retrieval
- **Connection Pooling**: Efficient database connection management
- **Caching**: Optimized query patterns
- **Scalable Architecture**: Designed for high-volume feedback processing

## 🛠️ Installation & Setup

### Prerequisites
- Python 3.8+
- Neo4j Database 4.4+
- Git

### Step 1: Clone Repository
```bash
git clone <repository-url>
cd Neo4j_Integration
```

### Step 2: Create Virtual Environment
```bash
python -m venv env
# Windows
env\Scripts\activate
# Linux/Mac
source env/bin/activate
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 4: Neo4j Setup
1. Install Neo4j Desktop or Neo4j Community Server
2. Create a new database or use existing one
3. Start the Neo4j service
4. Note down connection details (URI, username, password)

### Step 5: Environment Configuration
Create a `.env` file in the project root:
```env
# Neo4j Configuration
NEO4J_URI=bolt://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=your_password_here

# Flask Configuration
FLASK_HOST=0.0.0.0
FLASK_PORT=8000
FLASK_DEBUG=True

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE=logs/feedback_api.log
```

### Step 6: Start the Application
```bash
python app.py
```

You should see:
```
🚀 Neo4j Feedback Integration API
🌍 UN Environmental Governance App
============================================================
✅ Neo4j connection verified successfully
✅ Neo4j service initialized successfully
🌐 Flask server starting on 0.0.0.0:8000
```

## ⚙️ Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NEO4J_URI` | No | `bolt://localhost:7687` | Neo4j connection URI |
| `NEO4J_USERNAME` | No | `neo4j` | Neo4j username |
| `NEO4J_PASSWORD` | Yes | - | Neo4j password |
| `FLASK_HOST` | No | `0.0.0.0` | Flask server host |
| `FLASK_PORT` | No | `8000` | Flask server port |
| `FLASK_DEBUG` | No | `True` | Enable debug mode |
| `LOG_LEVEL` | No | `INFO` | Logging level |
| `LOG_FILE` | No | - | Log file path (optional) |

### Neo4j Configuration
- **Database**: `neo4j` (default)
- **Protocol**: Bolt
- **Indexes**: Automatically created for `timestamp`, `feedback_type`, and `rating_stars`

## 📡 API Documentation

### Base URL
```
http://localhost:8000/api
```

### Endpoints

#### 1. Health Check
```http
GET /api/health
```
**Response:**
```json
{
  "status": "healthy",
  "service": "Neo4j Feedback Integration API",
  "database": "connected",
  "timestamp": "2025-08-03T12:00:00"
}
```

#### 2. Store Feedback
```http
POST /api/feedback
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_query": "How can I reduce my carbon footprint?",
  "bot_response": "Here are some ways to reduce your carbon footprint...",
  "feedback_type": "positive",
  "user_comment": "Very helpful information!",
  "rating_stars": 5,
  "timestamp": "2025-08-03T12:00:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Feedback stored successfully",
  "timestamp": "2025-08-03T12:00:00"
}
```

#### 3. Get Analytics
```http
GET /api/feedback/analytics
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total_feedback": 150,
    "positive_count": 120,
    "negative_count": 30,
    "satisfaction_rate": 80.0
  }
}
```

#### 4. Get Trends
```http
GET /api/feedback/trends?days=7
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "feedback_date": "2025-08-03",
      "feedback_type": "positive",
      "count": 15
    },
    {
      "feedback_date": "2025-08-03",
      "feedback_type": "negative",
      "count": 3
    }
  ]
}
```

#### 5. Get Intent Performance
```http
GET /api/feedback/intents
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "intent_name": "carbon_reduction_inquiry",
      "total_feedback": 25,
      "positive_count": 20,
      "negative_count": 5,
      "satisfaction_rate": 80.0,
      "avg_confidence": 0.85
    }
  ]
}
```

#### 6. Get User Engagement
```http
GET /api/feedback/engagement?limit=10
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "user_id": "user_123",
      "total_feedback": 5,
      "positive_feedback": 4,
      "first_feedback": "2025-07-01T10:00:00Z",
      "last_feedback": "2025-08-03T15:30:00Z"
    }
  ]
}
```

#### 7. Get Category Insights
```http
GET /api/feedback/categories
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "category": "helpful",
      "feedback_type": "positive",
      "count": 45
    },
    {
      "category": "confusing",
      "feedback_type": "negative",
      "count": 12
    }
  ]
}
```

## 🗄️ Database Schema

### Neo4j Node Structure

#### Feedback Node
```cypher
(:Feedback {
  // Core feedback data
  user_query: String,           // User's original question
  bot_response: String,         // Bot's response text
  feedback_type: String,        // "positive" or "negative"
  user_comment: String,         // User's detailed feedback
  rating_stars: Integer,        // 1-5 star rating
  
  // Metadata
  timestamp: DateTime,          // When feedback was given
  created_at: DateTime          // When record was created
})
```

### Indexes
- `feedback_timestamp_idx` on `timestamp`
- `feedback_type_idx` on `feedback_type`
- `feedback_rating_idx` on `rating_stars`

## 🧪 Usage Examples

### Testing the API
```bash
# Run the test suite
python test_api.py --test

# Test specific endpoint
curl -X GET http://localhost:8000/api/health

# Submit feedback
curl -X POST http://localhost:8000/api/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "user_query": "Test query",
    "bot_response": "Test response",
    "feedback_type": "positive",
    "user_comment": "Great!",
    "rating_stars": 5,
    "timestamp": "2025-08-03T12:00:00Z"
  }'
```

### Flutter Integration Example
```dart
// Submit feedback from Flutter app
final feedbackData = {
  "user_query": widget.userQuery,
  "bot_response": widget.botResponse,
  "feedback_type": _starRating >= 4 ? 'positive' : 'negative',
  "user_comment": _commentController.text.trim(),
  "rating_stars": _starRating,
  "timestamp": DateTime.now().toUtc().toIso8601String(),
};

final response = await http.post(
  Uri.parse('http://localhost:8000/api/feedback'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode(feedbackData),
);
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Neo4j Connection Failed
```
Error: The client is unauthorized due to authentication failure
```
**Solution:**
- Verify Neo4j credentials in `.env` file
- Ensure Neo4j service is running
- Check firewall settings for port 7687

#### 2. Schema Validation Error
```
Error: Unknown field 'field_name'
```
**Solution:**
- Check request body matches API schema
- Ensure all required fields are present
- Verify field names and data types

#### 3. Flask Server Won't Start
```
Error: Address already in use
```
**Solution:**
- Change `FLASK_PORT` in `.env` file
- Kill existing process using the port
- Use `netstat -ano | findstr :8000` to find process

#### 4. Import Errors
```
Error: No module named 'flask_api'
```
**Solution:**
- Activate virtual environment
- Run `pip install -r requirements.txt`
- Check Python path configuration

### Logging
Logs are available in:
- Console output (real-time)
- Log file (if `LOG_FILE` is configured)
- Neo4j browser for database queries

### Debug Mode
Enable detailed logging by setting:
```env
FLASK_DEBUG=True
LOG_LEVEL=DEBUG
```

## 📈 Performance Optimization

### Database Optimization
- Indexes are automatically created for frequently queried fields
- Use parameterized queries to prevent injection attacks
- Connection pooling for concurrent requests

### API Optimization
- Request validation to prevent malformed data
- Error caching to reduce repeated failures
- Graceful degradation for database unavailability

## 🔮 Future Enhancements

1. **LLM Integration**: Enhance bot responses with LLM processing
2. **Real-time Dashboards**: Live analytics visualization
3. **Multi-language Support**: International feedback collection
4. **Advanced Analytics**: ML-based sentiment analysis
5. **Bulk Operations**: Batch feedback processing
6. **Data Export**: CSV/JSON export functionality

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review API documentation

---

**Built with ❤️ for Environmental Governance**

*Last updated: August 2025*
