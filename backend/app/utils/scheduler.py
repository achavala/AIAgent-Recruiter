from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger
from datetime import datetime
from app.services.job_service import job_service
from app.services.notification_service import notification_service
from app.utils.job_utils import duplicate_detector, relevance_scorer
from app.models import get_db
from app.config import settings
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class JobScheduler:
    def __init__(self):
        self.scheduler = BackgroundScheduler()
        self.is_running = False
    
    def start(self):
        """
        Start the job scheduler
        """
        if not self.is_running:
            # Schedule job scraping
            self.scheduler.add_job(
                func=self.scrape_jobs_task,
                trigger=IntervalTrigger(hours=settings.SCRAPING_INTERVAL_HOURS),
                id='scrape_jobs',
                name='Scrape jobs from all sources',
                replace_existing=True
            )
            
            # Schedule notification checking
            self.scheduler.add_job(
                func=self.check_notifications_task,
                trigger=IntervalTrigger(hours=1),
                id='check_notifications',
                name='Check and send job notifications',
                replace_existing=True
            )
            
            # Schedule duplicate removal
            self.scheduler.add_job(
                func=self.remove_duplicates_task,
                trigger=IntervalTrigger(hours=6),
                id='remove_duplicates',
                name='Remove duplicate jobs',
                replace_existing=True
            )
            
            # Schedule relevance score updates
            self.scheduler.add_job(
                func=self.update_relevance_scores_task,
                trigger=IntervalTrigger(hours=12),
                id='update_scores',
                name='Update job relevance scores',
                replace_existing=True
            )
            
            # Schedule old job cleanup
            self.scheduler.add_job(
                func=self.cleanup_old_jobs_task,
                trigger=IntervalTrigger(days=1),
                id='cleanup_old_jobs',
                name='Clean up old jobs',
                replace_existing=True
            )
            
            self.scheduler.start()
            self.is_running = True
            logger.info("Job scheduler started")
    
    def stop(self):
        """
        Stop the job scheduler
        """
        if self.is_running:
            self.scheduler.shutdown()
            self.is_running = False
            logger.info("Job scheduler stopped")
    
    def scrape_jobs_task(self):
        """
        Scheduled task to scrape jobs from all sources
        """
        try:
            logger.info("Starting scheduled job scraping...")
            
            # Scrape jobs with different search terms
            search_terms = [
                "software developer",
                "software engineer",
                "python developer",
                "java developer",
                "full stack developer",
                "data scientist",
                "devops engineer",
                "cloud engineer"
            ]
            
            total_results = {
                'total_scraped': 0,
                'new_jobs': 0,
                'duplicates_filtered': 0,
                'corp_to_corp_jobs': 0
            }
            
            for term in search_terms:
                try:
                    results = job_service.scrape_and_store_jobs(term)
                    for key in total_results:
                        total_results[key] += results.get(key, 0)
                    
                    logger.info(f"Scraped {results.get('new_jobs', 0)} new jobs for '{term}'")
                    
                except Exception as e:
                    logger.error(f"Error scraping jobs for '{term}': {e}")
            
            logger.info(f"Job scraping completed. Total new jobs: {total_results['new_jobs']}")
            
        except Exception as e:
            logger.error(f"Error in scrape_jobs_task: {e}")
    
    def check_notifications_task(self):
        """
        Scheduled task to check and send job notifications
        """
        try:
            logger.info("Checking job notifications...")
            
            results = notification_service.check_and_send_alerts()
            
            logger.info(f"Notification check completed. Emails sent: {results.get('emails_sent', 0)}")
            
        except Exception as e:
            logger.error(f"Error in check_notifications_task: {e}")
    
    def remove_duplicates_task(self):
        """
        Scheduled task to remove duplicate jobs
        """
        try:
            logger.info("Removing duplicate jobs...")
            
            db = next(get_db())
            try:
                removed_count = duplicate_detector.remove_duplicates(db)
                logger.info(f"Removed {removed_count} duplicate jobs")
            finally:
                db.close()
            
        except Exception as e:
            logger.error(f"Error in remove_duplicates_task: {e}")
    
    def update_relevance_scores_task(self):
        """
        Scheduled task to update job relevance scores
        """
        try:
            logger.info("Updating job relevance scores...")
            
            db = next(get_db())
            try:
                updated_count = relevance_scorer.update_all_job_scores(db)
                logger.info(f"Updated relevance scores for {updated_count} jobs")
            finally:
                db.close()
            
        except Exception as e:
            logger.error(f"Error in update_relevance_scores_task: {e}")
    
    def cleanup_old_jobs_task(self):
        """
        Scheduled task to clean up old jobs
        """
        try:
            logger.info("Cleaning up old jobs...")
            
            db = next(get_db())
            try:
                deleted_count = job_service.delete_old_jobs(db, days_old=30)
                logger.info(f"Deleted {deleted_count} old jobs")
            finally:
                db.close()
            
        except Exception as e:
            logger.error(f"Error in cleanup_old_jobs_task: {e}")
    
    def get_job_status(self):
        """
        Get current status of scheduled jobs
        """
        if not self.is_running:
            return {"status": "stopped", "jobs": []}
        
        jobs = []
        for job in self.scheduler.get_jobs():
            jobs.append({
                "id": job.id,
                "name": job.name,
                "next_run": job.next_run_time.isoformat() if job.next_run_time else None,
                "trigger": str(job.trigger)
            })
        
        return {
            "status": "running",
            "jobs": jobs
        }

# Create singleton instance
job_scheduler = JobScheduler()