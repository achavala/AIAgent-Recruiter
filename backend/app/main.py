from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import uvicorn
import os

# Import models and services
from app.models import Job, JobAlert, get_db, create_tables
from app.models.schemas import (
    JobResponse, JobSearchRequest, JobStats, 
    JobAlertCreate, JobAlertResponse, JobCreate, JobUpdate
)
from app.services.job_service import job_service
from app.services.notification_service import notification_service
from app.utils.scheduler import job_scheduler
from app.config import settings

# Create FastAPI app
app = FastAPI(
    title="AI Agent Recruiter",
    description="Comprehensive AI-powered job scraping and analysis system for corp-to-corp opportunities",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create database tables on startup
@app.on_event("startup")
async def startup_event():
    create_tables()
    job_scheduler.start()

@app.on_event("shutdown")
async def shutdown_event():
    job_scheduler.stop()

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

# Job endpoints
@app.get("/api/jobs/stats", response_model=JobStats)
async def get_job_stats(db: Session = Depends(get_db)):
    """
    Get job statistics
    """
    return job_service.get_job_stats(db)

@app.get("/api/jobs", response_model=List[JobResponse])
async def get_jobs(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Get all jobs with pagination
    """
    jobs = db.query(Job).offset(skip).limit(limit).all()
    return jobs

@app.post("/api/jobs/search", response_model=List[JobResponse])
async def search_jobs(
    search_params: JobSearchRequest,
    db: Session = Depends(get_db)
):
    """
    Search jobs with filters
    """
    jobs = job_service.search_jobs(db, search_params)
    return jobs

@app.get("/api/jobs/{job_id}", response_model=JobResponse)
async def get_job(
    job_id: int,
    db: Session = Depends(get_db)
):
    """
    Get a specific job by ID
    """
    job = job_service.get_job_by_id(db, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    return job

@app.patch("/api/jobs/{job_id}", response_model=JobResponse)
async def update_job(
    job_id: int,
    job_update: JobUpdate,
    db: Session = Depends(get_db)
):
    """
    Update job status (applied, favorited)
    """
    job = job_service.update_job(
        db, job_id, 
        job_update.is_applied, 
        job_update.is_favorited
    )
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    return job

@app.get("/api/jobs/stats", response_model=JobStats)
async def get_job_stats(db: Session = Depends(get_db)):
    """
    Get job statistics
    """
    return job_service.get_job_stats(db)

# Job scraping endpoints
@app.post("/api/scrape")
async def trigger_job_scraping(
    background_tasks: BackgroundTasks,
    keywords: str = "software developer",
    location: str = "USA"
):
    """
    Manually trigger job scraping
    """
    background_tasks.add_task(
        job_service.scrape_and_store_jobs,
        keywords,
        location
    )
    return {"message": "Job scraping started in background"}

@app.get("/api/scrape/status")
async def get_scraping_status():
    """
    Get current scraping/scheduling status
    """
    return job_scheduler.get_job_status()

# Job alert endpoints
@app.post("/api/alerts", response_model=JobAlertResponse)
async def create_job_alert(
    alert_data: JobAlertCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new job alert
    """
    alert = notification_service.create_job_alert(
        db,
        alert_data.keywords,
        alert_data.location,
        alert_data.min_salary,
        alert_data.email
    )
    return alert

@app.get("/api/alerts", response_model=List[JobAlertResponse])
async def get_job_alerts(
    email: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Get job alerts, optionally filtered by email
    """
    alerts = notification_service.get_job_alerts(db, email)
    return alerts

@app.delete("/api/alerts/{alert_id}")
async def delete_job_alert(
    alert_id: int,
    db: Session = Depends(get_db)
):
    """
    Deactivate a job alert
    """
    success = notification_service.deactivate_job_alert(db, alert_id)
    if not success:
        raise HTTPException(status_code=404, detail="Alert not found")
    return {"message": "Alert deactivated"}

# Export endpoints
@app.get("/api/export/jobs")
async def export_jobs(
    format: str = "json",
    db: Session = Depends(get_db)
):
    """
    Export jobs in JSON or CSV format
    """
    jobs = db.query(Job).all()
    
    if format.lower() == "csv":
        import csv
        import io
        
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Write header
        writer.writerow([
            'ID', 'Title', 'Company', 'Location', 'Job Type', 'Source',
            'Posted Date', 'Salary Min', 'Salary Max', 'Is Corp to Corp',
            'Relevance Score', 'Is Applied', 'Is Favorited', 'Source URL'
        ])
        
        # Write data
        for job in jobs:
            writer.writerow([
                job.id, job.title, job.company, job.location, job.job_type,
                job.source, job.posted_date, job.salary_min, job.salary_max,
                job.is_corp_to_corp, job.relevance_score, job.is_applied,
                job.is_favorited, job.source_url
            ])
        
        output.seek(0)
        return {"data": output.getvalue(), "format": "csv"}
    
    else:
        # JSON export
        job_data = []
        for job in jobs:
            job_data.append({
                "id": job.id,
                "title": job.title,
                "company": job.company,
                "location": job.location,
                "description": job.description,
                "job_type": job.job_type,
                "source": job.source,
                "posted_date": job.posted_date.isoformat(),
                "salary_min": job.salary_min,
                "salary_max": job.salary_max,
                "is_corp_to_corp": job.is_corp_to_corp,
                "relevance_score": job.relevance_score,
                "is_applied": job.is_applied,
                "is_favorited": job.is_favorited,
                "source_url": job.source_url
            })
        
        return {"data": job_data, "format": "json"}

# Analytics endpoints
@app.get("/api/analytics/trending")
async def get_trending_jobs(
    db: Session = Depends(get_db)
):
    """
    Get trending job titles and companies
    """
    from sqlalchemy import func
    
    # Top job titles in last 7 days
    from datetime import timedelta
    recent_date = datetime.utcnow() - timedelta(days=7)
    
    trending_titles = db.query(
        Job.title,
        func.count(Job.id).label('count')
    ).filter(
        Job.posted_date >= recent_date
    ).group_by(Job.title).order_by(func.count(Job.id).desc()).limit(10).all()
    
    # Top companies
    trending_companies = db.query(
        Job.company,
        func.count(Job.id).label('count')
    ).filter(
        Job.posted_date >= recent_date
    ).group_by(Job.company).order_by(func.count(Job.id).desc()).limit(10).all()
    
    return {
        "trending_titles": [{"title": title, "count": count} for title, count in trending_titles],
        "trending_companies": [{"company": company, "count": count} for company, count in trending_companies]
    }

@app.get("/api/analytics/salary")
async def get_salary_analytics(
    db: Session = Depends(get_db)
):
    """
    Get salary analytics
    """
    from sqlalchemy import func
    
    # Average salary by job type
    salary_by_type = db.query(
        Job.job_type,
        func.avg(Job.salary_min).label('avg_min'),
        func.avg(Job.salary_max).label('avg_max')
    ).filter(
        Job.salary_min.isnot(None)
    ).group_by(Job.job_type).all()
    
    # Salary distribution
    salary_ranges = db.query(
        func.count(Job.id).label('count')
    ).filter(
        Job.salary_min.isnot(None)
    ).group_by(
        func.case(
            [(Job.salary_min < 60000, 'Under $60k'),
             (Job.salary_min < 80000, '$60k-$80k'),
             (Job.salary_min < 100000, '$80k-$100k'),
             (Job.salary_min < 120000, '$100k-$120k')],
            else_='$120k+'
        )
    ).all()
    
    return {
        "salary_by_type": [
            {
                "job_type": job_type,
                "avg_min": float(avg_min) if avg_min else None,
                "avg_max": float(avg_max) if avg_max else None
            }
            for job_type, avg_min, avg_max in salary_by_type
        ],
        "salary_distribution": [{"range": range_name, "count": count} for count in salary_ranges]
    }

# Serve static files (frontend)
if os.path.exists("frontend/build"):
    app.mount("/", StaticFiles(directory="frontend/build", html=True), name="static")

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=True
    )