import openai
import re
import json
from typing import Optional, Dict, Any
from app.config import settings
from datetime import datetime, timedelta

class AIAnalysisService:
    def __init__(self):
        if settings.OPENAI_API_KEY:
            openai.api_key = settings.OPENAI_API_KEY
            self.client = openai.OpenAI(api_key=settings.OPENAI_API_KEY)
        else:
            self.client = None
        
    def analyze_job_description(self, job_title: str, job_description: str, requirements: str = "") -> Dict[str, Any]:
        """
        Analyze job description using OpenAI to extract relevant information
        and score job relevance for corp-to-corp opportunities
        """
        try:
            prompt = f"""
            Analyze this job posting for a corp-to-corp opportunity:
            
            Title: {job_title}
            Description: {job_description}
            Requirements: {requirements}
            
            Please provide a JSON response with the following analysis:
            1. relevance_score (0-1): How relevant is this job for corp-to-corp work?
            2. is_corp_to_corp (boolean): Does this explicitly mention corp-to-corp/contract work?
            3. key_skills: List of main technical skills required
            4. experience_level: junior/mid/senior/expert
            5. remote_friendly: boolean indicating if remote work is mentioned
            6. urgency_level: low/medium/high based on posting language
            7. salary_indication: estimated salary range if mentioned
            8. summary: Brief 2-sentence summary of the role
            
            Return only valid JSON format.
            """
            
            if not self.client:
                # Fallback analysis without OpenAI
                return self._fallback_analysis(job_title, job_description, requirements)
            
            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are an expert job analyst specializing in corp-to-corp contract opportunities."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=500,
                temperature=0.3
            )
            
            analysis_text = response.choices[0].message.content
            try:
                analysis = json.loads(analysis_text)
                return analysis
            except json.JSONDecodeError:
                return self._fallback_analysis(job_title, job_description, requirements)
                
        except Exception as e:
            print(f"Error in AI analysis: {str(e)}")
            return self._fallback_analysis(job_title, job_description, requirements)
    
    def _fallback_analysis(self, job_title: str, job_description: str, requirements: str = "") -> Dict[str, Any]:
        """
        Fallback analysis without OpenAI API
        """
        combined_text = f"{job_title} {job_description} {requirements}".lower()
        
        # Check for corp-to-corp keywords
        corp_keywords = [kw.lower() for kw in settings.CORP_TO_CORP_KEYWORDS]
        is_corp_to_corp = any(keyword in combined_text for keyword in corp_keywords)
        
        # Basic relevance scoring
        tech_keywords = [
            "python", "java", "javascript", "react", "nodejs", "sql", "aws", "azure",
            "docker", "kubernetes", "machine learning", "data science", "api", "rest",
            "microservices", "cloud", "devops", "ci/cd", "agile", "scrum"
        ]
        
        tech_score = sum(1 for keyword in tech_keywords if keyword in combined_text)
        relevance_score = min(1.0, tech_score / 10.0)
        
        if is_corp_to_corp:
            relevance_score += 0.3
        
        # Extract basic skills
        found_skills = [skill for skill in tech_keywords if skill in combined_text]
        
        # Determine experience level
        if any(level in combined_text for level in ["senior", "lead", "principal", "architect"]):
            experience_level = "senior"
        elif any(level in combined_text for level in ["junior", "entry", "graduate"]):
            experience_level = "junior"
        else:
            experience_level = "mid"
        
        # Check for remote work
        remote_keywords = ["remote", "work from home", "wfh", "telecommute", "distributed"]
        remote_friendly = any(keyword in combined_text for keyword in remote_keywords)
        
        # Urgency detection
        urgency_keywords = ["urgent", "asap", "immediate", "quickly", "fast"]
        urgency_level = "high" if any(keyword in combined_text for keyword in urgency_keywords) else "medium"
        
        return {
            "relevance_score": min(1.0, relevance_score),
            "is_corp_to_corp": is_corp_to_corp,
            "key_skills": found_skills[:5],  # Top 5 skills
            "experience_level": experience_level,
            "remote_friendly": remote_friendly,
            "urgency_level": urgency_level,
            "salary_indication": "Not specified",
            "summary": f"This is a {experience_level} level position for {job_title}. {'Remote work mentioned.' if remote_friendly else 'Location-based role.'}"
        }
    
    def extract_salary_range(self, text: str) -> tuple:
        """
        Extract salary range from job description text
        """
        # Common salary patterns
        patterns = [
            r'\$(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*-\s*\$(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)',
            r'(\d{1,3}(?:,\d{3})*)\s*-\s*(\d{1,3}(?:,\d{3})*)\s*(?:k|thousand)',
            r'\$(\d{1,3}(?:,\d{3})*)\s*per\s*hour',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                try:
                    if "hour" in pattern:
                        # Convert hourly to annual (assume 40 hours/week, 52 weeks/year)
                        hourly_rate = float(match.group(1).replace(',', ''))
                        annual_salary = hourly_rate * 40 * 52
                        return (annual_salary, annual_salary)
                    else:
                        min_salary = float(match.group(1).replace(',', ''))
                        max_salary = float(match.group(2).replace(',', ''))
                        
                        # If values are in thousands (k), multiply by 1000
                        if 'k' in text.lower() or 'thousand' in text.lower():
                            min_salary *= 1000
                            max_salary *= 1000
                        
                        return (min_salary, max_salary)
                except (ValueError, IndexError):
                    continue
        
        return (None, None)

# Create singleton instance
ai_service = AIAnalysisService()