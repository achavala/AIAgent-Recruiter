"""
Test configuration for the AI Agent Recruiter backend
"""
import os
import sys
from pathlib import Path

# Add the app directory to the Python path
sys.path.insert(0, str(Path(__file__).parent / 'app'))

# Set test environment variables
os.environ['DATABASE_URL'] = 'sqlite:///./test_jobs.db'
os.environ['OPENAI_API_KEY'] = 'test_key'
os.environ['EMAIL_USERNAME'] = 'test@example.com'
os.environ['EMAIL_PASSWORD'] = 'test_password'