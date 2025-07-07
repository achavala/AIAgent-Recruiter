from typing import List, Dict, Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func, desc
from datetime import datetime, timedelta
from app.models import Job, JobAlert, get_db
from app.models.schemas import JobCreate, JobSearchRequest, JobStats
from app.services.ai_analysis import ai_service
from app.scrapers.job_scrapers import IndeedScraper, DiceScraper, LinkedInScraper, CyberSeekScraper
from app.config import settings
import hashlib
import json

class JobService:
    def __init__(self):
        self.scrapers = {
            'indeed': IndeedScraper(),
            'dice': DiceScraper(),
            'linkedin': LinkedInScraper(),
            'cyberseek': CyberSeekScraper()
        }
    
    def scrape_and_store_jobs(self, keywords: str = "software developer", location: str = "USA") -> Dict[str, int]:
        """
        Scrape jobs from all sources and store in database
        """
        results = {
            'total_scraped': 0,
            'new_jobs': 0,
            'duplicates_filtered': 0,
            'corp_to_corp_jobs': 0
        }
        
        db = next(get_db())
        
        try:
            all_jobs = []
            
            # Scrape from all sources
            for scraper_name, scraper in self.scrapers.items():
                try:
                    jobs = scraper.scrape_jobs(keywords, location)
                    all_jobs.extend(jobs)
                    results['total_scraped'] += len(jobs)
                    print(f"Scraped {len(jobs)} jobs from {scraper_name}")
                except Exception as e:
                    print(f"Error scraping from {scraper_name}: {e}")
                    continue
            
            # Process and store jobs
            for job_data in all_jobs:
                try:
                    # Check for duplicates
                    if self._is_duplicate_job(db, job_data):
                        results['duplicates_filtered'] += 1
                        continue
                    
                    # AI analysis
                    ai_analysis = ai_service.analyze_job_description(
                        job_data['title'],
                        job_data['description'],
                        job_data.get('requirements', '')
                    )
                    
                    # Extract salary range
                    salary_min, salary_max = ai_service.extract_salary_range(job_data['description'])
                    
                    # Create job record
                    job = Job(
                        title=job_data['title'],
                        company=job_data['company'],
                        location=job_data['location'],
                        description=job_data['description'],
                        requirements=job_data.get('requirements', ''),
                        salary_min=salary_min,
                        salary_max=salary_max,
                        job_type=job_data.get('job_type', 'contract'),
                        source=job_data['source'],
                        source_url=job_data['source_url'],
                        posted_date=job_data['posted_date'],
                        is_corp_to_corp=ai_analysis.get('is_corp_to_corp', False),
                        relevance_score=ai_analysis.get('relevance_score', 0.0),
                        ai_analysis=json.dumps(ai_analysis),
                        contact_email=job_data.get('contact_email'),
                        contact_phone=job_data.get('contact_phone')
                    )
                    
                    db.add(job)
                    db.commit()
                    
                    results['new_jobs'] += 1
                    if job.is_corp_to_corp:
                        results['corp_to_corp_jobs'] += 1
                    
                except Exception as e:
                    print(f"Error processing job: {e}")
                    db.rollback()
                    continue
        
        finally:
            db.close()
        
        return results
    
    def _is_duplicate_job(self, db: Session, job_data: Dict) -> bool:
        """
        Check if job already exists in database
        """
        # Create a hash of key job attributes
        job_hash = hashlib.md5(
            f"{job_data['title']}{job_data['company']}{job_data['location']}{job_data['source_url']}".encode()
        ).hexdigest()
        
        # Check if similar job exists
        existing_job = db.query(Job).filter(
            and_(
                Job.title == job_data['title'],
                Job.company == job_data['company'],
                Job.location == job_data['location'],
                Job.source_url == job_data['source_url']
            )
        ).first()
        
        return existing_job is not None
    
    def search_jobs(self, db: Session, search_params: JobSearchRequest) -> List[Job]:
        """
        Search jobs with various filters
        """
        query = db.query(Job)
        
        # Apply filters
        if search_params.keywords:
            keywords = search_params.keywords.lower()
            query = query.filter(
                or_(
                    Job.title.ilike(f'%{keywords}%'),
                    Job.description.ilike(f'%{keywords}%'),
                    Job.requirements.ilike(f'%{keywords}%')
                )
            )
        
        if search_params.location:
            query = query.filter(Job.location.ilike(f'%{search_params.location}%'))
        
        if search_params.min_salary:
            query = query.filter(Job.salary_min >= search_params.min_salary)
        
        if search_params.max_salary:
            query = query.filter(Job.salary_max <= search_params.max_salary)
        
        if search_params.job_type:
            query = query.filter(Job.job_type == search_params.job_type)
        
        if search_params.source:
            query = query.filter(Job.source == search_params.source)
        
        if search_params.is_corp_to_corp is not None:
            query = query.filter(Job.is_corp_to_corp == search_params.is_corp_to_corp)
        
        if search_params.min_relevance_score:
            query = query.filter(Job.relevance_score >= search_params.min_relevance_score)
        
        if search_params.posted_within_hours:
            cutoff_date = datetime.utcnow() - timedelta(hours=search_params.posted_within_hours)
            query = query.filter(Job.posted_date >= cutoff_date)
        
        # Order by relevance score and posted date
        query = query.order_by(desc(Job.relevance_score), desc(Job.posted_date))
        
        return query.limit(100).all()
    
    def get_job_stats(self, db: Session) -> JobStats:
        """
        Get job statistics
        """
        # Total jobs
        total_jobs = db.query(Job).count()
        
        # Corp-to-corp jobs
        corp_to_corp_jobs = db.query(Job).filter(Job.is_corp_to_corp == True).count()
        
        # Jobs in last 24 hours
        last_24h = datetime.utcnow() - timedelta(hours=24)
        jobs_last_24h = db.query(Job).filter(Job.posted_date >= last_24h).count()
        
        # Average relevance score
        avg_relevance = db.query(func.avg(Job.relevance_score)).scalar() or 0.0
        
        # Top companies
        top_companies = db.query(
            Job.company,
            func.count(Job.id).label('job_count')
        ).group_by(Job.company).order_by(desc('job_count')).limit(10).all()
        
        # Top locations
        top_locations = db.query(
            Job.location,
            func.count(Job.id).label('job_count')
        ).group_by(Job.location).order_by(desc('job_count')).limit(10).all()
        
        return JobStats(
            total_jobs=total_jobs,
            corp_to_corp_jobs=corp_to_corp_jobs,
            jobs_last_24h=jobs_last_24h,
            avg_relevance_score=round(avg_relevance, 2),
            top_companies=[{'company': company, 'count': count} for company, count in top_companies],
            top_locations=[{'location': location, 'count': count} for location, count in top_locations]
        )
    
    def update_job(self, db: Session, job_id: int, is_applied: bool = None, is_favorited: bool = None) -> Optional[Job]:
        """
        Update job status
        """
        job = db.query(Job).filter(Job.id == job_id).first()
        if not job:
            return None
        
        if is_applied is not None:
            job.is_applied = is_applied
        
        if is_favorited is not None:
            job.is_favorited = is_favorited
        
        db.commit()
        db.refresh(job)
        return job
    
    def get_job_by_id(self, db: Session, job_id: int) -> Optional[Job]:
        """
        Get job by ID
        """
        return db.query(Job).filter(Job.id == job_id).first()
    
    def delete_old_jobs(self, db: Session, days_old: int = 30) -> int:
        """
        Delete jobs older than specified days
        """
        cutoff_date = datetime.utcnow() - timedelta(days=days_old)
        deleted_count = db.query(Job).filter(Job.posted_date < cutoff_date).delete()
        db.commit()
        return deleted_count

# Create singleton instance
job_service = JobService()