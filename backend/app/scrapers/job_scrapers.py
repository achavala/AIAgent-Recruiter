import requests
import time
import json
from bs4 import BeautifulSoup
from datetime import datetime, timedelta
from typing import List, Dict, Optional
from urllib.parse import urlencode, quote
from app.config import settings

class BaseScraper:
    def __init__(self, name: str):
        self.name = name
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        self.session = requests.Session()
        self.session.headers.update(self.headers)
    
    def scrape_jobs(self, keywords: str = "", location: str = "USA") -> List[Dict]:
        """
        Base method to be implemented by each scraper
        """
        raise NotImplementedError("Each scraper must implement scrape_jobs method")
    
    def is_corp_to_corp(self, job_description: str) -> bool:
        """
        Check if job description indicates corp-to-corp opportunity
        """
        description_lower = job_description.lower()
        return any(keyword.lower() in description_lower for keyword in settings.CORP_TO_CORP_KEYWORDS)
    
    def is_recent_job(self, posted_date: datetime, hours: int = 24) -> bool:
        """
        Check if job was posted within the specified hours
        """
        if not posted_date:
            return False
        cutoff_date = datetime.utcnow() - timedelta(hours=hours)
        return posted_date >= cutoff_date
    
    def clean_text(self, text: str) -> str:
        """
        Clean HTML and extra whitespace from text
        """
        if not text:
            return ""
        # Remove HTML tags
        soup = BeautifulSoup(text, 'html.parser')
        cleaned = soup.get_text()
        # Remove extra whitespace
        cleaned = ' '.join(cleaned.split())
        return cleaned
    
    def parse_posted_date(self, date_str: str) -> Optional[datetime]:
        """
        Parse various date formats commonly used in job postings
        """
        if not date_str:
            return None
        
        date_str = date_str.strip().lower()
        now = datetime.utcnow()
        
        try:
            # Handle relative dates
            if "today" in date_str or "just posted" in date_str:
                return now
            elif "yesterday" in date_str:
                return now - timedelta(days=1)
            elif "hour" in date_str:
                hours = int(''.join(filter(str.isdigit, date_str)))
                return now - timedelta(hours=hours)
            elif "day" in date_str:
                days = int(''.join(filter(str.isdigit, date_str)))
                return now - timedelta(days=days)
            elif "week" in date_str:
                weeks = int(''.join(filter(str.isdigit, date_str)))
                return now - timedelta(weeks=weeks)
            elif "month" in date_str:
                months = int(''.join(filter(str.isdigit, date_str)))
                return now - timedelta(days=months * 30)
            else:
                # Try to parse as actual date
                from dateutil import parser
                return parser.parse(date_str)
        except:
            return None

class IndeedScraper(BaseScraper):
    def __init__(self):
        super().__init__("indeed")
        self.base_url = "https://www.indeed.com"
    
    def scrape_jobs(self, keywords: str = "software developer", location: str = "USA") -> List[Dict]:
        """
        Scrape jobs from Indeed
        """
        jobs = []
        
        # Build search URL
        params = {
            'q': f"{keywords} corp to corp",
            'l': location,
            'sort': 'date',
            'fromage': '1',  # Last 24 hours
            'limit': 50
        }
        
        url = f"{self.base_url}/jobs?{urlencode(params)}"
        
        try:
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find job cards (Indeed's structure may change)
            job_cards = soup.find_all('div', class_='job_seen_beacon')
            
            for card in job_cards[:20]:  # Limit to first 20 jobs
                try:
                    job_data = self._extract_job_data(card)
                    if job_data:
                        jobs.append(job_data)
                except Exception as e:
                    print(f"Error extracting job data: {e}")
                    continue
                
                # Add delay to avoid rate limiting
                time.sleep(1)
            
        except Exception as e:
            print(f"Error scraping Indeed: {e}")
        
        return jobs
    
    def _extract_job_data(self, card) -> Optional[Dict]:
        """
        Extract job data from Indeed job card
        """
        try:
            # Extract basic info
            title_elem = card.find('h2', class_='jobTitle')
            if not title_elem:
                return None
            
            title = self.clean_text(title_elem.get_text())
            
            # Company
            company_elem = card.find('span', class_='companyName')
            company = self.clean_text(company_elem.get_text()) if company_elem else "Unknown"
            
            # Location
            location_elem = card.find('div', class_='companyLocation')
            location = self.clean_text(location_elem.get_text()) if location_elem else "Unknown"
            
            # Job link
            link_elem = title_elem.find('a')
            job_url = f"{self.base_url}{link_elem['href']}" if link_elem else ""
            
            # Posted date
            date_elem = card.find('span', class_='date')
            posted_date = self.parse_posted_date(date_elem.get_text()) if date_elem else datetime.utcnow()
            
            # Get job description by following the link
            description = self._get_job_description(job_url)
            
            return {
                'title': title,
                'company': company,
                'location': location,
                'description': description,
                'requirements': "",
                'source': self.name,
                'source_url': job_url,
                'posted_date': posted_date,
                'job_type': 'contract'
            }
            
        except Exception as e:
            print(f"Error extracting job data from card: {e}")
            return None
    
    def _get_job_description(self, job_url: str) -> str:
        """
        Get full job description from job detail page
        """
        try:
            if not job_url:
                return ""
            
            response = self.session.get(job_url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            desc_elem = soup.find('div', class_='jobsearch-jobDescriptionText')
            
            if desc_elem:
                return self.clean_text(desc_elem.get_text())
            
        except Exception as e:
            print(f"Error getting job description: {e}")
        
        return ""

class DiceScraper(BaseScraper):
    def __init__(self):
        super().__init__("dice")
        self.base_url = "https://www.dice.com"
    
    def scrape_jobs(self, keywords: str = "software developer", location: str = "USA") -> List[Dict]:
        """
        Scrape jobs from Dice
        """
        jobs = []
        
        # Build search URL
        params = {
            'q': f"{keywords} contract",
            'location': location,
            'radius': '30',
            'radiusUnit': 'mi',
            'filters.postedDate': 'ONE',  # Last 24 hours
            'filters.employmentType': 'CONTRACTS',
            'page': '1',
            'pageSize': '20'
        }
        
        url = f"{self.base_url}/jobs?{urlencode(params)}"
        
        try:
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find job cards
            job_cards = soup.find_all('div', class_='card-body')
            
            for card in job_cards:
                try:
                    job_data = self._extract_dice_job_data(card)
                    if job_data:
                        jobs.append(job_data)
                except Exception as e:
                    print(f"Error extracting Dice job data: {e}")
                    continue
                
                time.sleep(1)
            
        except Exception as e:
            print(f"Error scraping Dice: {e}")
        
        return jobs
    
    def _extract_dice_job_data(self, card) -> Optional[Dict]:
        """
        Extract job data from Dice job card
        """
        try:
            # Extract basic info
            title_elem = card.find('h5', class_='card-title-link')
            if not title_elem:
                return None
            
            title = self.clean_text(title_elem.get_text())
            
            # Company
            company_elem = card.find('div', class_='card-company')
            company = self.clean_text(company_elem.get_text()) if company_elem else "Unknown"
            
            # Location
            location_elem = card.find('div', class_='card-location')
            location = self.clean_text(location_elem.get_text()) if location_elem else "Unknown"
            
            # Job link
            link_elem = title_elem.find('a')
            job_url = f"{self.base_url}{link_elem['href']}" if link_elem else ""
            
            # Description
            desc_elem = card.find('div', class_='card-description')
            description = self.clean_text(desc_elem.get_text()) if desc_elem else ""
            
            return {
                'title': title,
                'company': company,
                'location': location,
                'description': description,
                'requirements': "",
                'source': self.name,
                'source_url': job_url,
                'posted_date': datetime.utcnow(),  # Dice doesn't always show exact date
                'job_type': 'contract'
            }
            
        except Exception as e:
            print(f"Error extracting Dice job data from card: {e}")
            return None

# Mock scrapers for other sources (LinkedIn, CyberSeek would require API keys)
class LinkedInScraper(BaseScraper):
    def __init__(self):
        super().__init__("linkedin")
    
    def scrape_jobs(self, keywords: str = "software developer", location: str = "USA") -> List[Dict]:
        """
        Mock LinkedIn scraper - in real implementation, would use LinkedIn API
        """
        # LinkedIn requires API access or more sophisticated scraping
        # For now, return empty list
        return []

class CyberSeekScraper(BaseScraper):
    def __init__(self):
        super().__init__("cyberseek")
    
    def scrape_jobs(self, keywords: str = "software developer", location: str = "USA") -> List[Dict]:
        """
        Mock CyberSeek scraper
        """
        return []