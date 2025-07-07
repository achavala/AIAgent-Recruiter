import React, { useState, useEffect } from 'react';
import {
  Card,
  CardContent,
  Typography,
  Chip,
  Button,
  Box,
  Rating,
  Divider,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Link
} from '@mui/material';
import {
  BookmarkBorder,
  Bookmark,
  CheckCircle,
  CheckCircleOutline,
  Launch,
  LocationOn,
  Business,
  Schedule,
  AttachMoney
} from '@mui/icons-material';
import { formatDistanceToNow } from 'date-fns';

const JobCard = ({ job, onUpdate, onViewDetails }) => {
  const [isApplied, setIsApplied] = useState(job.is_applied);
  const [isFavorited, setIsFavorited] = useState(job.is_favorited);
  const [showDetails, setShowDetails] = useState(false);

  const handleAppliedToggle = async () => {
    try {
      const newStatus = !isApplied;
      await onUpdate(job.id, { is_applied: newStatus });
      setIsApplied(newStatus);
    } catch (error) {
      console.error('Error updating applied status:', error);
    }
  };

  const handleFavoriteToggle = async () => {
    try {
      const newStatus = !isFavorited;
      await onUpdate(job.id, { is_favorited: newStatus });
      setIsFavorited(newStatus);
    } catch (error) {
      console.error('Error updating favorite status:', error);
    }
  };

  const formatSalary = (min, max) => {
    if (min && max) {
      return `$${min.toLocaleString()} - $${max.toLocaleString()}`;
    } else if (min) {
      return `$${min.toLocaleString()}+`;
    }
    return 'Salary not specified';
  };

  const getRelevanceColor = (score) => {
    if (score >= 0.8) return 'success';
    if (score >= 0.6) return 'warning';
    return 'error';
  };

  return (
    <>
      <Card 
        sx={{ 
          mb: 2, 
          '&:hover': { 
            boxShadow: 3,
            transform: 'translateY(-2px)',
            transition: 'all 0.3s ease'
          }
        }}
      >
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="flex-start">
            <Box flex={1}>
              <Typography variant="h6" component="h2" gutterBottom>
                {job.title}
              </Typography>
              
              <Box display="flex" alignItems="center" gap={1} mb={1}>
                <Business fontSize="small" color="action" />
                <Typography variant="body2" color="text.secondary">
                  {job.company}
                </Typography>
              </Box>
              
              <Box display="flex" alignItems="center" gap={1} mb={1}>
                <LocationOn fontSize="small" color="action" />
                <Typography variant="body2" color="text.secondary">
                  {job.location}
                </Typography>
              </Box>
              
              <Box display="flex" alignItems="center" gap={1} mb={1}>
                <Schedule fontSize="small" color="action" />
                <Typography variant="body2" color="text.secondary">
                  Posted {formatDistanceToNow(new Date(job.posted_date))} ago
                </Typography>
              </Box>
              
              {(job.salary_min || job.salary_max) && (
                <Box display="flex" alignItems="center" gap={1} mb={1}>
                  <AttachMoney fontSize="small" color="action" />
                  <Typography variant="body2" color="text.secondary">
                    {formatSalary(job.salary_min, job.salary_max)}
                  </Typography>
                </Box>
              )}
            </Box>
            
            <Box display="flex" flexDirection="column" alignItems="flex-end" gap={1}>
              <IconButton onClick={handleFavoriteToggle} color="primary">
                {isFavorited ? <Bookmark /> : <BookmarkBorder />}
              </IconButton>
              
              <IconButton onClick={handleAppliedToggle} color="success">
                {isApplied ? <CheckCircle /> : <CheckCircleOutline />}
              </IconButton>
            </Box>
          </Box>
          
          <Divider sx={{ my: 2 }} />
          
          <Box display="flex" gap={1} mb={2} flexWrap="wrap">
            <Chip 
              label={job.job_type || 'Contract'} 
              size="small" 
              color="primary" 
              variant="outlined"
            />
            {job.is_corp_to_corp && (
              <Chip 
                label="Corp-to-Corp" 
                size="small" 
                color="success" 
                variant="outlined"
              />
            )}
            <Chip 
              label={`${job.relevance_score.toFixed(1)}/1.0`} 
              size="small" 
              color={getRelevanceColor(job.relevance_score)}
              variant="outlined"
            />
            <Chip 
              label={job.source} 
              size="small" 
              variant="outlined"
            />
          </Box>
          
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            {job.description.substring(0, 200)}...
          </Typography>
          
          <Box display="flex" gap={1} justifyContent="space-between" alignItems="center">
            <Button 
              variant="outlined" 
              size="small" 
              onClick={() => setShowDetails(true)}
            >
              View Details
            </Button>
            
            <Button 
              variant="contained" 
              size="small" 
              endIcon={<Launch />}
              href={job.source_url}
              target="_blank"
              rel="noopener noreferrer"
            >
              Apply Now
            </Button>
          </Box>
        </CardContent>
      </Card>

      <Dialog open={showDetails} onClose={() => setShowDetails(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Typography variant="h6">{job.title}</Typography>
            <Rating value={job.relevance_score} max={1} precision={0.1} readOnly />
          </Box>
        </DialogTitle>
        <DialogContent>
          <Typography variant="subtitle1" gutterBottom>
            {job.company} • {job.location}
          </Typography>
          
          <Box display="flex" gap={1} mb={2}>
            <Chip label={job.job_type || 'Contract'} size="small" color="primary" />
            {job.is_corp_to_corp && (
              <Chip label="Corp-to-Corp" size="small" color="success" />
            )}
            <Chip label={job.source} size="small" />
          </Box>
          
          {(job.salary_min || job.salary_max) && (
            <Typography variant="body2" color="primary" gutterBottom>
              <strong>Salary:</strong> {formatSalary(job.salary_min, job.salary_max)}
            </Typography>
          )}
          
          <Typography variant="body2" color="text.secondary" gutterBottom>
            <strong>Posted:</strong> {formatDistanceToNow(new Date(job.posted_date))} ago
          </Typography>
          
          <Divider sx={{ my: 2 }} />
          
          <Typography variant="h6" gutterBottom>
            Job Description
          </Typography>
          <Typography variant="body2" paragraph>
            {job.description}
          </Typography>
          
          {job.requirements && (
            <>
              <Typography variant="h6" gutterBottom>
                Requirements
              </Typography>
              <Typography variant="body2" paragraph>
                {job.requirements}
              </Typography>
            </>
          )}
          
          {job.ai_analysis && (
            <>
              <Typography variant="h6" gutterBottom>
                AI Analysis
              </Typography>
              <Typography variant="body2" paragraph>
                {JSON.parse(job.ai_analysis).summary}
              </Typography>
            </>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowDetails(false)}>Close</Button>
          <Button 
            variant="contained" 
            href={job.source_url}
            target="_blank"
            rel="noopener noreferrer"
          >
            Apply Now
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default JobCard;