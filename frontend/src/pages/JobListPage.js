import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Box,
  Button,
  Alert,
  CircularProgress,
  Pagination,
  Grid,
  Paper,
  Fab,
  Snackbar
} from '@mui/material';
import { Refresh, Add } from '@mui/icons-material';
import JobCard from '../components/JobCard';
import JobFilters from '../components/JobFilters';
import { jobService } from '../services/api';

const JobListPage = () => {
  const [jobs, setJobs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [filters, setFilters] = useState({});
  const [scraping, setScraping] = useState(false);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });

  const jobsPerPage = 10;

  useEffect(() => {
    fetchJobs();
  }, [page, filters]);

  const fetchJobs = async () => {
    try {
      setLoading(true);
      setError(null);
      
      let response;
      if (Object.keys(filters).length > 0) {
        response = await jobService.searchJobs(filters);
      } else {
        response = await jobService.getJobs((page - 1) * jobsPerPage, jobsPerPage);
      }
      
      setJobs(response.data);
      setTotalPages(Math.ceil(response.data.length / jobsPerPage));
    } catch (err) {
      setError('Failed to fetch jobs. Please try again.');
      console.error('Error fetching jobs:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleFiltersChange = (newFilters) => {
    setFilters(newFilters);
    setPage(1);
  };

  const handleClearFilters = () => {
    setFilters({});
    setPage(1);
  };

  const handleJobUpdate = async (jobId, updates) => {
    try {
      await jobService.updateJob(jobId, updates);
      setSnackbar({
        open: true,
        message: 'Job updated successfully!',
        severity: 'success'
      });
      // Refresh the job list
      fetchJobs();
    } catch (err) {
      setSnackbar({
        open: true,
        message: 'Failed to update job.',
        severity: 'error'
      });
    }
  };

  const handleTriggerScraping = async () => {
    try {
      setScraping(true);
      await jobService.triggerScraping();
      setSnackbar({
        open: true,
        message: 'Job scraping started! New jobs will appear shortly.',
        severity: 'success'
      });
    } catch (err) {
      setSnackbar({
        open: true,
        message: 'Failed to start job scraping.',
        severity: 'error'
      });
    } finally {
      setScraping(false);
    }
  };

  const handlePageChange = (event, newPage) => {
    setPage(newPage);
  };

  const handleSnackbarClose = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  if (loading) {
    return (
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="50vh">
          <CircularProgress />
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Box mb={4}>
        <Typography variant="h4" component="h1" gutterBottom>
          Job Opportunities
        </Typography>
        <Typography variant="subtitle1" color="text.secondary">
          Corp-to-Corp and Contract Positions
        </Typography>
      </Box>

      <JobFilters 
        onFiltersChange={handleFiltersChange}
        onClearFilters={handleClearFilters}
      />

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Paper elevation={1} sx={{ p: 2, mb: 3 }}>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="h6">
                {jobs.length} jobs found
              </Typography>
              <Button
                variant="outlined"
                startIcon={<Refresh />}
                onClick={fetchJobs}
                disabled={loading}
              >
                Refresh
              </Button>
            </Box>
          </Paper>

          {jobs.length === 0 ? (
            <Paper elevation={1} sx={{ p: 4, textAlign: 'center' }}>
              <Typography variant="h6" color="text.secondary">
                No jobs found matching your criteria
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Try adjusting your filters or trigger a new job scraping session
              </Typography>
            </Paper>
          ) : (
            <>
              {jobs.map((job) => (
                <JobCard
                  key={job.id}
                  job={job}
                  onUpdate={handleJobUpdate}
                />
              ))}
              
              <Box display="flex" justifyContent="center" mt={4}>
                <Pagination
                  count={totalPages}
                  page={page}
                  onChange={handlePageChange}
                  color="primary"
                />
              </Box>
            </>
          )}
        </Grid>

        <Grid item xs={12} md={4}>
          <Paper elevation={2} sx={{ p: 2, mb: 3 }}>
            <Typography variant="h6" gutterBottom>
              Quick Actions
            </Typography>
            
            <Button
              variant="contained"
              fullWidth
              startIcon={<Add />}
              onClick={handleTriggerScraping}
              disabled={scraping}
              sx={{ mb: 2 }}
            >
              {scraping ? 'Scraping...' : 'Scrape New Jobs'}
            </Button>
            
            <Button
              variant="outlined"
              fullWidth
              onClick={() => window.location.href = '/analytics'}
              sx={{ mb: 2 }}
            >
              View Analytics
            </Button>
            
            <Button
              variant="outlined"
              fullWidth
              onClick={() => window.location.href = '/alerts'}
            >
              Manage Alerts
            </Button>
          </Paper>

          <Paper elevation={2} sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Tips
            </Typography>
            <Typography variant="body2" color="text.secondary" paragraph>
              • Use specific keywords like "Python", "React", or "Data Science"
            </Typography>
            <Typography variant="body2" color="text.secondary" paragraph>
              • Filter by Corp-to-Corp for contract opportunities
            </Typography>
            <Typography variant="body2" color="text.secondary" paragraph>
              • Set up job alerts to get notified of new opportunities
            </Typography>
          </Paper>
        </Grid>
      </Grid>

      <Fab
        color="primary"
        aria-label="refresh"
        onClick={fetchJobs}
        sx={{ position: 'fixed', bottom: 16, right: 16 }}
      >
        <Refresh />
      </Fab>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={handleSnackbarClose}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
      >
        <Alert severity={snackbar.severity} onClose={handleSnackbarClose}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Container>
  );
};

export default JobListPage;