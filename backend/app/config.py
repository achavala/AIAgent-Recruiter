import os
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "sqlite:///./jobs.db"
    
    # OpenAI API
    OPENAI_API_KEY: Optional[str] = None
    
    # Email Configuration
    EMAIL_HOST: str = "smtp.gmail.com"
    EMAIL_PORT: int = 587
    EMAIL_USERNAME: Optional[str] = None
    EMAIL_PASSWORD: Optional[str] = None
    
    # Job Scraping Configuration
    SCRAPING_INTERVAL_HOURS: int = 1
    JOB_RELEVANCE_THRESHOLD: float = 0.7
    
    # Geographic Settings
    TARGET_COUNTRIES: list = ["USA", "United States"]
    
    # Corp-to-Corp Keywords
    CORP_TO_CORP_KEYWORDS: list = [
        "corp to corp", "c2c", "contract", "contractor", 
        "consulting", "1099", "w2", "independent contractor"
    ]
    
    # API Settings
    API_HOST: str = "localhost"
    API_PORT: int = 8000
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()