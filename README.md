# AI Agent Recruiter

A comprehensive AI-powered job scraping and analysis system that automatically pulls and processes corp-to-corp (contract) job opportunities from multiple sources in the USA.

## Features

- **Multi-Source Job Scraping**: Integrates with Indeed, Dice, LinkedIn, and CyberSeek
- **AI-Powered Analysis**: Uses OpenAI API to analyze job descriptions and relevance
- **Corp-to-Corp Filtering**: Specifically identifies and filters contract positions
- **Real-time Monitoring**: Automated job scraping with customizable intervals
- **Smart Notifications**: Email alerts for matching opportunities
- **Web Interface**: Modern React-based frontend for job management
- **Analytics Dashboard**: Job market insights and trending data
- **Duplicate Detection**: Intelligent filtering of duplicate job postings
- **Export Functionality**: Export job data in JSON/CSV formats

## Tech Stack

### Backend
- **FastAPI** - Modern Python web framework
- **SQLAlchemy** - Database ORM
- **SQLite** - Database storage
- **OpenAI API** - Job analysis and relevance scoring
- **BeautifulSoup/Requests** - Web scraping
- **APScheduler** - Job scheduling
- **SMTP** - Email notifications

### Frontend
- **React** - Frontend framework
- **Material-UI** - UI components
- **Recharts** - Data visualization
- **Axios** - API client

### DevOps
- **Docker** - Containerization
- **Docker Compose** - Multi-container orchestration

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/achavala/AIAgent-Recruiter.git
cd AIAgent-Recruiter
```

### 2. Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env
```

### 3. Using Docker (Recommended)
```bash
# Build and start all services
docker-compose up --build

# Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:8000
# API Documentation: http://localhost:8000/docs
```

### 4. Manual Setup

#### Backend Setup
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

#### Frontend Setup
```bash
cd frontend
npm install
npm start
```

## Configuration

### Environment Variables
```bash
# OpenAI API Key (required for AI analysis)
OPENAI_API_KEY=your_openai_api_key

# Email configuration (for notifications)
EMAIL_USERNAME=your_email@gmail.com
EMAIL_PASSWORD=your_app_password

# Database
DATABASE_URL=sqlite:///./jobs.db

# Job scraping settings
SCRAPING_INTERVAL_HOURS=1
JOB_RELEVANCE_THRESHOLD=0.7
```

## Usage

### 1. Job Search and Management
- Browse jobs with advanced filtering options
- View detailed job descriptions with AI analysis
- Mark jobs as applied or favorited
- Export job data in multiple formats

### 2. Job Alerts
- Create custom job alerts with keywords and criteria
- Receive email notifications for matching opportunities
- Manage alert subscriptions

### 3. Analytics Dashboard
- View job market trends and statistics
- Analyze salary data by job type and location
- Track top companies and trending positions

### 4. Automated Scraping
- Jobs are automatically scraped every hour
- Duplicates are filtered out intelligently
- AI analysis provides relevance scoring

## API Endpoints

### Jobs
- `GET /api/jobs` - Get all jobs
- `POST /api/jobs/search` - Search jobs with filters
- `GET /api/jobs/{id}` - Get specific job
- `PATCH /api/jobs/{id}` - Update job status
- `GET /api/jobs/stats` - Get job statistics

### Job Alerts
- `POST /api/alerts` - Create job alert
- `GET /api/alerts` - Get user alerts
- `DELETE /api/alerts/{id}` - Delete alert

### Scraping
- `POST /api/scrape` - Trigger manual scraping
- `GET /api/scrape/status` - Get scraping status

### Analytics
- `GET /api/analytics/trending` - Get trending jobs
- `GET /api/analytics/salary` - Get salary analytics

## Architecture

```
├── backend/
│   ├── app/
│   │   ├── models/          # Database models
│   │   ├── services/        # Business logic
│   │   ├── scrapers/        # Job scraping modules
│   │   ├── utils/           # Utility functions
│   │   └── main.py          # FastAPI application
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── pages/           # Page components
│   │   └── services/        # API services
│   ├── package.json
│   └── Dockerfile
└── docker-compose.yml
```

## Development

### Adding New Job Sources
1. Create a new scraper class in `backend/app/scrapers/`
2. Implement the `scrape_jobs` method
3. Add the scraper to the `JobService` class
4. Update the source filter in the frontend

### Customizing AI Analysis
1. Modify the analysis prompt in `backend/app/services/ai_analysis.py`
2. Update the analysis fields in the database model
3. Adjust the relevance scoring algorithm

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Open an issue on GitHub
- Check the API documentation at `/docs`
- Review the configuration guide above

## Roadmap

- [ ] Additional job board integrations
- [ ] Enhanced AI analysis with job matching
- [ ] Mobile app development
- [ ] Advanced analytics and reporting
- [ ] Integration with ATS systems
- [ ] Slack/Teams notifications
- [ ] Resume parsing and matching