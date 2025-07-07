import hashlib
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from sqlalchemy.orm import Session
from app.models import Job, get_db

class JobDuplicateDetector:
    def __init__(self):
        self.similarity_threshold = 0.8
    
    def is_duplicate(self, db: Session, job_data: Dict) -> bool:
        """
        Check if job is a duplicate using multiple criteria
        """
        # Exact match check
        if self._exact_match_exists(db, job_data):
            return True
        
        # Similarity check
        if self._similar_job_exists(db, job_data):
            return True
        
        return False
    
    def _exact_match_exists(self, db: Session, job_data: Dict) -> bool:
        """
        Check for exact matches
        """
        existing_job = db.query(Job).filter(
            Job.title == job_data['title'],
            Job.company == job_data['company'],
            Job.location == job_data['location'],
            Job.source_url == job_data['source_url']
        ).first()
        
        return existing_job is not None
    
    def _similar_job_exists(self, db: Session, job_data: Dict) -> bool:
        """
        Check for similar jobs using fuzzy matching
        """
        # Get jobs from same company posted in last 7 days
        recent_date = datetime.utcnow() - timedelta(days=7)
        similar_jobs = db.query(Job).filter(
            Job.company == job_data['company'],
            Job.posted_date >= recent_date
        ).all()
        
        for job in similar_jobs:
            similarity = self._calculate_similarity(job_data, job)
            if similarity > self.similarity_threshold:
                return True
        
        return False
    
    def _calculate_similarity(self, job_data: Dict, existing_job: Job) -> float:
        """
        Calculate similarity score between two jobs
        """
        # Title similarity
        title_sim = self._text_similarity(job_data['title'], existing_job.title)
        
        # Location similarity
        location_sim = self._text_similarity(job_data['location'], existing_job.location)
        
        # Description similarity (first 200 chars)
        desc_sim = self._text_similarity(
            job_data['description'][:200], 
            existing_job.description[:200]
        )
        
        # Weighted average
        return (title_sim * 0.4 + location_sim * 0.2 + desc_sim * 0.4)
    
    def _text_similarity(self, text1: str, text2: str) -> float:
        """
        Calculate text similarity using simple word overlap
        """
        if not text1 or not text2:
            return 0.0
        
        words1 = set(text1.lower().split())
        words2 = set(text2.lower().split())
        
        if not words1 or not words2:
            return 0.0
        
        intersection = words1.intersection(words2)
        union = words1.union(words2)
        
        return len(intersection) / len(union)
    
    def remove_duplicates(self, db: Session) -> int:
        """
        Remove duplicate jobs from database
        """
        # Get all jobs ordered by date
        jobs = db.query(Job).order_by(Job.posted_date.desc()).all()
        
        seen_jobs = set()
        duplicates_removed = 0
        
        for job in jobs:
            job_signature = self._create_job_signature(job)
            
            if job_signature in seen_jobs:
                db.delete(job)
                duplicates_removed += 1
            else:
                seen_jobs.add(job_signature)
        
        db.commit()
        return duplicates_removed
    
    def _create_job_signature(self, job: Job) -> str:
        """
        Create a unique signature for a job
        """
        signature_text = f"{job.title.lower().strip()}{job.company.lower().strip()}{job.location.lower().strip()}"
        return hashlib.md5(signature_text.encode()).hexdigest()

class JobRelevanceScorer:
    def __init__(self):
        self.tech_skills = [
            'python', 'java', 'javascript', 'react', 'angular', 'vue', 'nodejs',
            'sql', 'mongodb', 'postgresql', 'mysql', 'redis', 'elasticsearch',
            'aws', 'azure', 'gcp', 'docker', 'kubernetes', 'terraform',
            'git', 'jenkins', 'ci/cd', 'microservices', 'api', 'rest', 'graphql',
            'machine learning', 'ai', 'data science', 'analytics', 'big data',
            'agile', 'scrum', 'devops', 'cloud', 'cybersecurity'
        ]
        
        self.experience_levels = {
            'junior': ['junior', 'entry', 'graduate', 'associate', 'trainee'],
            'mid': ['mid', 'intermediate', 'experienced', 'professional'],
            'senior': ['senior', 'lead', 'principal', 'architect', 'manager', 'director']
        }
        
        self.contract_keywords = [
            'contract', 'contractor', 'consulting', 'freelance', 'temporary',
            'corp to corp', 'c2c', '1099', 'w2', 'independent contractor'
        ]
    
    def score_job_relevance(self, job: Job, user_skills: List[str] = None) -> float:
        """
        Score job relevance based on multiple factors
        """
        if user_skills is None:
            user_skills = self.tech_skills[:10]  # Default to top 10 tech skills
        
        scores = {
            'skill_match': self._score_skill_match(job, user_skills),
            'contract_type': self._score_contract_type(job),
            'location_preference': self._score_location(job),
            'recency': self._score_recency(job),
            'salary_range': self._score_salary(job)
        }
        
        # Weighted average
        weights = {
            'skill_match': 0.4,
            'contract_type': 0.25,
            'location_preference': 0.15,
            'recency': 0.1,
            'salary_range': 0.1
        }
        
        total_score = sum(scores[key] * weights[key] for key in scores)
        return min(1.0, total_score)
    
    def _score_skill_match(self, job: Job, user_skills: List[str]) -> float:
        """
        Score based on skill match
        """
        job_text = f"{job.title} {job.description} {job.requirements}".lower()
        
        matched_skills = 0
        for skill in user_skills:
            if skill.lower() in job_text:
                matched_skills += 1
        
        return matched_skills / len(user_skills)
    
    def _score_contract_type(self, job: Job) -> float:
        """
        Score based on contract type preference
        """
        if job.is_corp_to_corp:
            return 1.0
        
        job_text = f"{job.title} {job.description}".lower()
        contract_mentions = sum(1 for keyword in self.contract_keywords if keyword in job_text)
        
        return min(1.0, contract_mentions / 3)
    
    def _score_location(self, job: Job) -> float:
        """
        Score based on location preference (USA focus)
        """
        location_text = job.location.lower()
        
        # Preferred locations
        if any(loc in location_text for loc in ['remote', 'anywhere', 'usa']):
            return 1.0
        
        # US states/cities
        us_indicators = ['ny', 'ca', 'tx', 'fl', 'il', 'pa', 'oh', 'ga', 'nc', 'mi']
        if any(state in location_text for state in us_indicators):
            return 0.8
        
        return 0.5
    
    def _score_recency(self, job: Job) -> float:
        """
        Score based on how recent the job posting is
        """
        if not job.posted_date:
            return 0.5
        
        days_old = (datetime.utcnow() - job.posted_date).days
        
        if days_old == 0:
            return 1.0
        elif days_old <= 3:
            return 0.8
        elif days_old <= 7:
            return 0.6
        elif days_old <= 14:
            return 0.4
        else:
            return 0.2
    
    def _score_salary(self, job: Job) -> float:
        """
        Score based on salary range
        """
        if not job.salary_min:
            return 0.5
        
        # Score based on salary ranges for contract work
        if job.salary_min >= 100000:
            return 1.0
        elif job.salary_min >= 80000:
            return 0.8
        elif job.salary_min >= 60000:
            return 0.6
        else:
            return 0.4
    
    def update_all_job_scores(self, db: Session) -> int:
        """
        Update relevance scores for all jobs
        """
        jobs = db.query(Job).all()
        updated_count = 0
        
        for job in jobs:
            new_score = self.score_job_relevance(job)
            if abs(job.relevance_score - new_score) > 0.1:  # Only update if significant change
                job.relevance_score = new_score
                updated_count += 1
        
        db.commit()
        return updated_count

# Create singleton instances
duplicate_detector = JobDuplicateDetector()
relevance_scorer = JobRelevanceScorer()