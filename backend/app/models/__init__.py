from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean, Text, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from app.config import settings

Base = declarative_base()

class Job(Base):
    __tablename__ = "jobs"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    company = Column(String, index=True)
    location = Column(String, index=True)
    description = Column(Text)
    requirements = Column(Text)
    salary_min = Column(Float, nullable=True)
    salary_max = Column(Float, nullable=True)
    job_type = Column(String)  # contract, full-time, etc.
    source = Column(String)  # indeed, linkedin, dice, etc.
    source_url = Column(String)
    posted_date = Column(DateTime)
    scraped_date = Column(DateTime, default=datetime.utcnow)
    is_corp_to_corp = Column(Boolean, default=False)
    relevance_score = Column(Float, default=0.0)
    ai_analysis = Column(Text, nullable=True)
    is_applied = Column(Boolean, default=False)
    is_favorited = Column(Boolean, default=False)
    contact_email = Column(String, nullable=True)
    contact_phone = Column(String, nullable=True)
    
    def __repr__(self):
        return f"<Job(title='{self.title}', company='{self.company}', location='{self.location}')>"

class JobAlert(Base):
    __tablename__ = "job_alerts"
    
    id = Column(Integer, primary_key=True, index=True)
    keywords = Column(String)
    location = Column(String)
    min_salary = Column(Float, nullable=True)
    email = Column(String)
    is_active = Column(Boolean, default=True)
    created_date = Column(DateTime, default=datetime.utcnow)
    
# Database setup
engine = create_engine(settings.DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def create_tables():
    Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()