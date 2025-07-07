from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

class JobBase(BaseModel):
    title: str
    company: str
    location: str
    description: str
    requirements: Optional[str] = None
    salary_min: Optional[float] = None
    salary_max: Optional[float] = None
    job_type: Optional[str] = None
    source: str
    source_url: str
    posted_date: datetime
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None

class JobCreate(JobBase):
    pass

class JobUpdate(BaseModel):
    is_applied: Optional[bool] = None
    is_favorited: Optional[bool] = None

class JobResponse(JobBase):
    id: int
    scraped_date: datetime
    is_corp_to_corp: bool
    relevance_score: float
    ai_analysis: Optional[str] = None
    is_applied: bool
    is_favorited: bool
    
    class Config:
        from_attributes = True

class JobSearchRequest(BaseModel):
    keywords: Optional[str] = None
    location: Optional[str] = None
    min_salary: Optional[float] = None
    max_salary: Optional[float] = None
    job_type: Optional[str] = None
    source: Optional[str] = None
    is_corp_to_corp: Optional[bool] = None
    min_relevance_score: Optional[float] = None
    posted_within_hours: Optional[int] = 24

class JobAlertCreate(BaseModel):
    keywords: str
    location: str
    min_salary: Optional[float] = None
    email: EmailStr

class JobAlertResponse(BaseModel):
    id: int
    keywords: str
    location: str
    min_salary: Optional[float] = None
    email: str
    is_active: bool
    created_date: datetime
    
    class Config:
        from_attributes = True

class JobStats(BaseModel):
    total_jobs: int
    corp_to_corp_jobs: int
    jobs_last_24h: int
    avg_relevance_score: float
    top_companies: List[dict]
    top_locations: List[dict]