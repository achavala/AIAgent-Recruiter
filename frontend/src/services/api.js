import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://localhost:8000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

// Job services
export const jobService = {
  // Get all jobs
  getJobs: (skip = 0, limit = 100) => 
    api.get(`/jobs?skip=${skip}&limit=${limit}`),
  
  // Search jobs
  searchJobs: (searchParams) => 
    api.post('/jobs/search', searchParams),
  
  // Get job by ID
  getJob: (jobId) => 
    api.get(`/jobs/${jobId}`),
  
  // Update job status
  updateJob: (jobId, updates) => 
    api.patch(`/jobs/${jobId}`, updates),
  
  // Get job statistics
  getJobStats: () => 
    api.get('/jobs/stats'),
  
  // Export jobs
  exportJobs: (format = 'json') => 
    api.get(`/export/jobs?format=${format}`),
  
  // Trigger job scraping
  triggerScraping: (keywords = 'software developer', location = 'USA') => 
    api.post('/scrape', null, { params: { keywords, location } }),
  
  // Get scraping status
  getScrapingStatus: () => 
    api.get('/scrape/status'),
};

// Job alert services
export const alertService = {
  // Create job alert
  createAlert: (alertData) => 
    api.post('/alerts', alertData),
  
  // Get job alerts
  getAlerts: (email = null) => 
    api.get('/alerts', { params: email ? { email } : {} }),
  
  // Delete job alert
  deleteAlert: (alertId) => 
    api.delete(`/alerts/${alertId}`),
};

// Analytics services
export const analyticsService = {
  // Get trending jobs
  getTrendingJobs: () => 
    api.get('/analytics/trending'),
  
  // Get salary analytics
  getSalaryAnalytics: () => 
    api.get('/analytics/salary'),
};

// Health check
export const healthService = {
  checkHealth: () => 
    api.get('/health'),
};

export default api;