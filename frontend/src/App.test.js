import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { BrowserRouter } from 'react-router-dom';
import App from './App';

// Mock the components to avoid complex testing setup
jest.mock('./pages/JobListPage', () => {
  return function MockJobListPage() {
    return <div data-testid="job-list-page">Job List Page</div>;
  };
});

jest.mock('./pages/Dashboard', () => {
  return function MockDashboard() {
    return <div data-testid="dashboard-page">Dashboard Page</div>;
  };
});

jest.mock('./pages/AlertsPage', () => {
  return function MockAlertsPage() {
    return <div data-testid="alerts-page">Alerts Page</div>;
  };
});

// Mock the API service
jest.mock('./services/api', () => ({
  jobService: {
    getJobs: jest.fn(),
    searchJobs: jest.fn(),
    updateJob: jest.fn(),
    getJobStats: jest.fn(),
    triggerScraping: jest.fn(),
  },
  analyticsService: {
    getTrendingJobs: jest.fn(),
    getSalaryAnalytics: jest.fn(),
  },
}));

test('renders AI Agent Recruiter navigation', () => {
  render(
    <BrowserRouter>
      <App />
    </BrowserRouter>
  );
  
  const titleElement = screen.getByText(/AI Agent Recruiter/i);
  expect(titleElement).toBeInTheDocument();
});

test('renders navigation buttons', () => {
  render(
    <BrowserRouter>
      <App />
    </BrowserRouter>
  );
  
  const jobsButton = screen.getByText(/Jobs/i);
  const dashboardButton = screen.getByText(/Dashboard/i);
  const alertsButton = screen.getByText(/Alerts/i);
  
  expect(jobsButton).toBeInTheDocument();
  expect(dashboardButton).toBeInTheDocument();
  expect(alertsButton).toBeInTheDocument();
});

test('renders job list page by default', () => {
  render(
    <BrowserRouter>
      <App />
    </BrowserRouter>
  );
  
  const jobListPage = screen.getByTestId('job-list-page');
  expect(jobListPage).toBeInTheDocument();
});