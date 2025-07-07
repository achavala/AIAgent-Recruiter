#!/usr/bin/env python3

"""
Demo script to populate the database with sample job data for testing
"""

import sys
import os

# Add the backend directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app.models import Job, JobAlert, get_db, create_tables
from app.services.ai_analysis import ai_service
from datetime import datetime, timedelta
import json

def create_sample_jobs():
    """Create sample job data for demonstration"""
    
    # Create database tables
    create_tables()
    
    db = next(get_db())
    
    sample_jobs = [
        {
            "title": "Senior Python Developer",
            "company": "TechCorp Solutions",
            "location": "San Francisco, CA",
            "description": "We are looking for a skilled Python developer to join our team. The ideal candidate will have experience with FastAPI, Django, and machine learning frameworks. This is a corp-to-corp contract position with competitive rates. Remote work is available.",
            "requirements": "5+ years Python experience, FastAPI, Django, SQL, AWS",
            "salary_min": 120000,
            "salary_max": 150000,
            "job_type": "contract",
            "source": "indeed",
            "source_url": "https://indeed.com/job/python-developer-123",
            "posted_date": datetime.utcnow() - timedelta(hours=2),
            "contact_email": "hiring@techcorp.com",
            "is_corp_to_corp": True
        },
        {
            "title": "React Frontend Developer",
            "company": "StartupXYZ",
            "location": "New York, NY",
            "description": "Join our dynamic startup as a frontend developer. We're building cutting-edge web applications using React, TypeScript, and modern tools. This is a contract position with potential for extension.",
            "requirements": "3+ years React, TypeScript, Material-UI, Redux",
            "salary_min": 90000,
            "salary_max": 120000,
            "job_type": "contract",
            "source": "dice",
            "source_url": "https://dice.com/job/react-developer-456",
            "posted_date": datetime.utcnow() - timedelta(hours=5),
            "contact_email": "careers@startupxyz.com",
            "is_corp_to_corp": False
        },
        {
            "title": "Data Scientist - Machine Learning",
            "company": "DataTech Industries",
            "location": "Austin, TX",
            "description": "We're seeking a data scientist to work on machine learning projects. Experience with Python, TensorFlow, and statistical analysis required. Corp-to-corp contractors welcome. Hybrid work model available.",
            "requirements": "PhD in Data Science, Python, TensorFlow, Statistics, R",
            "salary_min": 130000,
            "salary_max": 160000,
            "job_type": "contract",
            "source": "linkedin",
            "source_url": "https://linkedin.com/jobs/data-scientist-789",
            "posted_date": datetime.utcnow() - timedelta(hours=8),
            "contact_email": "ml-jobs@datatech.com",
            "is_corp_to_corp": True
        },
        {
            "title": "DevOps Engineer",
            "company": "CloudFirst Corp",
            "location": "Seattle, WA",
            "description": "Looking for a DevOps engineer to manage our cloud infrastructure. Must have experience with AWS, Docker, Kubernetes, and CI/CD pipelines. Contract position with immediate start.",
            "requirements": "AWS certification, Docker, Kubernetes, Jenkins, Terraform",
            "salary_min": 110000,
            "salary_max": 140000,
            "job_type": "contract",
            "source": "dice",
            "source_url": "https://dice.com/job/devops-engineer-101",
            "posted_date": datetime.utcnow() - timedelta(hours=12),
            "contact_email": "devops@cloudfirst.com",
            "is_corp_to_corp": True
        },
        {
            "title": "Full Stack Developer",
            "company": "Enterprise Solutions LLC",
            "location": "Remote, USA",
            "description": "We need a full-stack developer for our enterprise applications. Experience with Node.js, React, and PostgreSQL required. This is a remote contract position with flexible hours.",
            "requirements": "Node.js, React, PostgreSQL, REST APIs, Git",
            "salary_min": 95000,
            "salary_max": 125000,
            "job_type": "contract",
            "source": "indeed",
            "source_url": "https://indeed.com/job/fullstack-developer-202",
            "posted_date": datetime.utcnow() - timedelta(hours=18),
            "contact_email": "remote-jobs@enterprisesolutions.com",
            "is_corp_to_corp": False
        }
    ]
    
    try:
        for job_data in sample_jobs:
            # Use AI analysis service to get relevance score
            ai_analysis = ai_service.analyze_job_description(
                job_data["title"],
                job_data["description"],
                job_data["requirements"]
            )
            
            # Create job record
            job = Job(
                title=job_data["title"],
                company=job_data["company"],
                location=job_data["location"],
                description=job_data["description"],
                requirements=job_data["requirements"],
                salary_min=job_data["salary_min"],
                salary_max=job_data["salary_max"],
                job_type=job_data["job_type"],
                source=job_data["source"],
                source_url=job_data["source_url"],
                posted_date=job_data["posted_date"],
                is_corp_to_corp=job_data["is_corp_to_corp"],
                relevance_score=ai_analysis.get("relevance_score", 0.8),
                ai_analysis=json.dumps(ai_analysis),
                contact_email=job_data["contact_email"]
            )
            
            db.add(job)
            print(f"Added job: {job.title} at {job.company}")
        
        # Create a sample job alert
        alert = JobAlert(
            keywords="Python, React, Data Science",
            location="USA",
            min_salary=100000,
            email="demo@example.com"
        )
        db.add(alert)
        print("Added sample job alert")
        
        db.commit()
        print(f"\nSuccessfully created {len(sample_jobs)} sample jobs!")
        
        # Show statistics
        total_jobs = db.query(Job).count()
        corp_jobs = db.query(Job).filter(Job.is_corp_to_corp == True).count()
        
        print(f"Total jobs in database: {total_jobs}")
        print(f"Corp-to-corp jobs: {corp_jobs}")
        
    except Exception as e:
        print(f"Error creating sample data: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_sample_jobs()