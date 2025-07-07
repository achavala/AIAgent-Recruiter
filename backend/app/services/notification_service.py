import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import List, Dict
from sqlalchemy.orm import Session
from app.models import Job, JobAlert, get_db
from app.config import settings
from datetime import datetime, timedelta
import json

class NotificationService:
    def __init__(self):
        self.smtp_server = settings.EMAIL_HOST
        self.smtp_port = settings.EMAIL_PORT
        self.username = settings.EMAIL_USERNAME
        self.password = settings.EMAIL_PASSWORD
    
    def send_job_alert(self, job: Job, email: str, alert_keywords: str) -> bool:
        """
        Send job alert email
        """
        try:
            if not self.username or not self.password:
                print("Email credentials not configured")
                return False
            
            # Create message
            msg = MIMEMultipart('alternative')
            msg['Subject'] = f"New Job Alert: {job.title} at {job.company}"
            msg['From'] = self.username
            msg['To'] = email
            
            # Parse AI analysis
            ai_analysis = {}
            if job.ai_analysis:
                try:
                    ai_analysis = json.loads(job.ai_analysis)
                except:
                    pass
            
            # Create email content
            text_content = self._create_text_email(job, ai_analysis, alert_keywords)
            html_content = self._create_html_email(job, ai_analysis, alert_keywords)
            
            # Attach parts
            text_part = MIMEText(text_content, 'plain')
            html_part = MIMEText(html_content, 'html')
            
            msg.attach(text_part)
            msg.attach(html_part)
            
            # Send email
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.username, self.password)
            server.send_message(msg)
            server.quit()
            
            return True
            
        except Exception as e:
            print(f"Error sending email: {e}")
            return False
    
    def _create_text_email(self, job: Job, ai_analysis: Dict, alert_keywords: str) -> str:
        """
        Create plain text email content
        """
        salary_info = ""
        if job.salary_min and job.salary_max:
            salary_info = f"Salary: ${job.salary_min:,.0f} - ${job.salary_max:,.0f}"
        elif job.salary_min:
            salary_info = f"Salary: ${job.salary_min:,.0f}+"
        
        relevance_score = f"{job.relevance_score:.1%}" if job.relevance_score else "N/A"
        
        content = f"""
New Job Alert - {alert_keywords}

Job Title: {job.title}
Company: {job.company}
Location: {job.location}
{salary_info}
Job Type: {job.job_type}
Corp-to-Corp: {'Yes' if job.is_corp_to_corp else 'No'}
Relevance Score: {relevance_score}
Posted: {job.posted_date.strftime('%Y-%m-%d %H:%M')}
Source: {job.source}

Description:
{job.description[:500]}...

Key Skills: {', '.join(ai_analysis.get('key_skills', []))}
Experience Level: {ai_analysis.get('experience_level', 'N/A')}
Remote Friendly: {'Yes' if ai_analysis.get('remote_friendly', False) else 'No'}

View Full Job: {job.source_url}

---
This alert was sent because the job matches your keywords: {alert_keywords}
"""
        return content
    
    def _create_html_email(self, job: Job, ai_analysis: Dict, alert_keywords: str) -> str:
        """
        Create HTML email content
        """
        salary_info = ""
        if job.salary_min and job.salary_max:
            salary_info = f"<p><strong>Salary:</strong> ${job.salary_min:,.0f} - ${job.salary_max:,.0f}</p>"
        elif job.salary_min:
            salary_info = f"<p><strong>Salary:</strong> ${job.salary_min:,.0f}+</p>"
        
        relevance_score = f"{job.relevance_score:.1%}" if job.relevance_score else "N/A"
        
        content = f"""
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .header {{ background-color: #f4f4f4; padding: 20px; border-radius: 5px; }}
        .job-info {{ margin: 20px 0; }}
        .highlight {{ background-color: #e8f5e8; padding: 10px; border-radius: 5px; }}
        .button {{ background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; }}
    </style>
</head>
<body>
    <div class="header">
        <h2>New Job Alert - {alert_keywords}</h2>
    </div>
    
    <div class="job-info">
        <h3>{job.title}</h3>
        <p><strong>Company:</strong> {job.company}</p>
        <p><strong>Location:</strong> {job.location}</p>
        {salary_info}
        <p><strong>Job Type:</strong> {job.job_type}</p>
        <p><strong>Corp-to-Corp:</strong> {'Yes' if job.is_corp_to_corp else 'No'}</p>
        <p><strong>Relevance Score:</strong> {relevance_score}</p>
        <p><strong>Posted:</strong> {job.posted_date.strftime('%Y-%m-%d %H:%M')}</p>
        <p><strong>Source:</strong> {job.source}</p>
    </div>
    
    <div class="highlight">
        <h4>AI Analysis:</h4>
        <p><strong>Key Skills:</strong> {', '.join(ai_analysis.get('key_skills', []))}</p>
        <p><strong>Experience Level:</strong> {ai_analysis.get('experience_level', 'N/A')}</p>
        <p><strong>Remote Friendly:</strong> {'Yes' if ai_analysis.get('remote_friendly', False) else 'No'}</p>
        <p><strong>Summary:</strong> {ai_analysis.get('summary', 'No summary available')}</p>
    </div>
    
    <h4>Job Description:</h4>
    <p>{job.description[:500]}...</p>
    
    <p><a href="{job.source_url}" class="button">View Full Job</a></p>
    
    <hr>
    <p><small>This alert was sent because the job matches your keywords: {alert_keywords}</small></p>
</body>
</html>
"""
        return content
    
    def check_and_send_alerts(self) -> Dict[str, int]:
        """
        Check for new jobs and send alerts to subscribers
        """
        results = {
            'alerts_checked': 0,
            'emails_sent': 0,
            'errors': 0
        }
        
        db = next(get_db())
        
        try:
            # Get all active job alerts
            alerts = db.query(JobAlert).filter(JobAlert.is_active == True).all()
            results['alerts_checked'] = len(alerts)
            
            # Get jobs from last 24 hours
            last_24h = datetime.utcnow() - timedelta(hours=24)
            recent_jobs = db.query(Job).filter(Job.posted_date >= last_24h).all()
            
            for alert in alerts:
                try:
                    # Find matching jobs
                    matching_jobs = self._find_matching_jobs(recent_jobs, alert)
                    
                    # Send email for each matching job
                    for job in matching_jobs:
                        if self.send_job_alert(job, alert.email, alert.keywords):
                            results['emails_sent'] += 1
                        else:
                            results['errors'] += 1
                            
                except Exception as e:
                    print(f"Error processing alert {alert.id}: {e}")
                    results['errors'] += 1
        
        finally:
            db.close()
        
        return results
    
    def _find_matching_jobs(self, jobs: List[Job], alert: JobAlert) -> List[Job]:
        """
        Find jobs that match the alert criteria
        """
        matching_jobs = []
        keywords = alert.keywords.lower().split()
        
        for job in jobs:
            # Check if job matches keywords
            job_text = f"{job.title} {job.description} {job.requirements}".lower()
            if any(keyword in job_text for keyword in keywords):
                # Check location if specified
                if alert.location and alert.location.lower() not in job.location.lower():
                    continue
                
                # Check minimum salary if specified
                if alert.min_salary and job.salary_min and job.salary_min < alert.min_salary:
                    continue
                
                # Only include high-relevance jobs
                if job.relevance_score >= settings.JOB_RELEVANCE_THRESHOLD:
                    matching_jobs.append(job)
        
        return matching_jobs
    
    def create_job_alert(self, db: Session, keywords: str, location: str, min_salary: float, email: str) -> JobAlert:
        """
        Create a new job alert
        """
        alert = JobAlert(
            keywords=keywords,
            location=location,
            min_salary=min_salary,
            email=email
        )
        
        db.add(alert)
        db.commit()
        db.refresh(alert)
        
        return alert
    
    def get_job_alerts(self, db: Session, email: str = None) -> List[JobAlert]:
        """
        Get job alerts, optionally filtered by email
        """
        query = db.query(JobAlert)
        
        if email:
            query = query.filter(JobAlert.email == email)
        
        return query.filter(JobAlert.is_active == True).all()
    
    def deactivate_job_alert(self, db: Session, alert_id: int) -> bool:
        """
        Deactivate a job alert
        """
        alert = db.query(JobAlert).filter(JobAlert.id == alert_id).first()
        if alert:
            alert.is_active = False
            db.commit()
            return True
        return False

# Create singleton instance
notification_service = NotificationService()