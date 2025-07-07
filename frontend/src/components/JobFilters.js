import React, { useState } from 'react';
import {
  Paper,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Box,
  Typography,
  Chip,
  Slider,
  Switch,
  FormControlLabel,
  Grid,
  Accordion,
  AccordionSummary,
  AccordionDetails
} from '@mui/material';
import { ExpandMore, Search, Clear } from '@mui/icons-material';

const JobFilters = ({ onFiltersChange, onClearFilters }) => {
  const [filters, setFilters] = useState({
    keywords: '',
    location: '',
    min_salary: 0,
    max_salary: 200000,
    job_type: '',
    source: '',
    is_corp_to_corp: null,
    min_relevance_score: 0,
    posted_within_hours: 24
  });

  const handleFilterChange = (key, value) => {
    const newFilters = { ...filters, [key]: value };
    setFilters(newFilters);
    onFiltersChange(newFilters);
  };

  const handleClearFilters = () => {
    const clearedFilters = {
      keywords: '',
      location: '',
      min_salary: 0,
      max_salary: 200000,
      job_type: '',
      source: '',
      is_corp_to_corp: null,
      min_relevance_score: 0,
      posted_within_hours: 24
    };
    setFilters(clearedFilters);
    onClearFilters();
  };

  const jobTypes = [
    { value: 'contract', label: 'Contract' },
    { value: 'full-time', label: 'Full-time' },
    { value: 'part-time', label: 'Part-time' },
    { value: 'temporary', label: 'Temporary' }
  ];

  const sources = [
    { value: 'indeed', label: 'Indeed' },
    { value: 'dice', label: 'Dice' },
    { value: 'linkedin', label: 'LinkedIn' },
    { value: 'cyberseek', label: 'CyberSeek' }
  ];

  const timeRanges = [
    { value: 1, label: 'Last hour' },
    { value: 24, label: 'Last 24 hours' },
    { value: 168, label: 'Last week' },
    { value: 720, label: 'Last month' }
  ];

  return (
    <Paper elevation={2} sx={{ p: 2, mb: 3 }}>
      <Typography variant="h6" gutterBottom>
        Job Filters
      </Typography>
      
      <Grid container spacing={2}>
        {/* Keywords and Location */}
        <Grid item xs={12} md={6}>
          <TextField
            fullWidth
            label="Keywords"
            value={filters.keywords}
            onChange={(e) => handleFilterChange('keywords', e.target.value)}
            placeholder="e.g., Python, React, Data Science"
            variant="outlined"
            size="small"
          />
        </Grid>
        
        <Grid item xs={12} md={6}>
          <TextField
            fullWidth
            label="Location"
            value={filters.location}
            onChange={(e) => handleFilterChange('location', e.target.value)}
            placeholder="e.g., New York, Remote, USA"
            variant="outlined"
            size="small"
          />
        </Grid>
        
        {/* Job Type and Source */}
        <Grid item xs={12} md={6}>
          <FormControl fullWidth size="small">
            <InputLabel>Job Type</InputLabel>
            <Select
              value={filters.job_type}
              onChange={(e) => handleFilterChange('job_type', e.target.value)}
              label="Job Type"
            >
              <MenuItem value="">All Types</MenuItem>
              {jobTypes.map((type) => (
                <MenuItem key={type.value} value={type.value}>
                  {type.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Grid>
        
        <Grid item xs={12} md={6}>
          <FormControl fullWidth size="small">
            <InputLabel>Source</InputLabel>
            <Select
              value={filters.source}
              onChange={(e) => handleFilterChange('source', e.target.value)}
              label="Source"
            >
              <MenuItem value="">All Sources</MenuItem>
              {sources.map((source) => (
                <MenuItem key={source.value} value={source.value}>
                  {source.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Grid>
        
        {/* Time Range */}
        <Grid item xs={12} md={6}>
          <FormControl fullWidth size="small">
            <InputLabel>Posted Within</InputLabel>
            <Select
              value={filters.posted_within_hours}
              onChange={(e) => handleFilterChange('posted_within_hours', e.target.value)}
              label="Posted Within"
            >
              {timeRanges.map((range) => (
                <MenuItem key={range.value} value={range.value}>
                  {range.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Grid>
        
        {/* Corp-to-Corp Switch */}
        <Grid item xs={12} md={6}>
          <FormControlLabel
            control={
              <Switch
                checked={filters.is_corp_to_corp === true}
                onChange={(e) => handleFilterChange('is_corp_to_corp', e.target.checked ? true : null)}
              />
            }
            label="Corp-to-Corp Only"
          />
        </Grid>
      </Grid>

      {/* Advanced Filters */}
      <Accordion sx={{ mt: 2 }}>
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Typography>Advanced Filters</Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Grid container spacing={3}>
            {/* Salary Range */}
            <Grid item xs={12}>
              <Typography gutterBottom>
                Salary Range: ${filters.min_salary.toLocaleString()} - ${filters.max_salary.toLocaleString()}
              </Typography>
              <Slider
                value={[filters.min_salary, filters.max_salary]}
                onChange={(e, newValue) => {
                  handleFilterChange('min_salary', newValue[0]);
                  handleFilterChange('max_salary', newValue[1]);
                }}
                min={0}
                max={300000}
                step={5000}
                valueLabelDisplay="auto"
                valueLabelFormat={(value) => `$${value.toLocaleString()}`}
              />
            </Grid>
            
            {/* Relevance Score */}
            <Grid item xs={12}>
              <Typography gutterBottom>
                Minimum Relevance Score: {filters.min_relevance_score.toFixed(1)}
              </Typography>
              <Slider
                value={filters.min_relevance_score}
                onChange={(e, newValue) => handleFilterChange('min_relevance_score', newValue)}
                min={0}
                max={1}
                step={0.1}
                valueLabelDisplay="auto"
                marks={[
                  { value: 0, label: '0' },
                  { value: 0.5, label: '0.5' },
                  { value: 1, label: '1.0' }
                ]}
              />
            </Grid>
          </Grid>
        </AccordionDetails>
      </Accordion>
      
      {/* Action Buttons */}
      <Box display="flex" gap={2} mt={2}>
        <Button
          variant="contained"
          startIcon={<Search />}
          onClick={() => onFiltersChange(filters)}
        >
          Apply Filters
        </Button>
        
        <Button
          variant="outlined"
          startIcon={<Clear />}
          onClick={handleClearFilters}
        >
          Clear Filters
        </Button>
      </Box>
      
      {/* Active Filters */}
      <Box mt={2}>
        <Typography variant="subtitle2" gutterBottom>
          Active Filters:
        </Typography>
        <Box display="flex" gap={1} flexWrap="wrap">
          {filters.keywords && (
            <Chip
              label={`Keywords: ${filters.keywords}`}
              size="small"
              onDelete={() => handleFilterChange('keywords', '')}
            />
          )}
          {filters.location && (
            <Chip
              label={`Location: ${filters.location}`}
              size="small"
              onDelete={() => handleFilterChange('location', '')}
            />
          )}
          {filters.job_type && (
            <Chip
              label={`Type: ${filters.job_type}`}
              size="small"
              onDelete={() => handleFilterChange('job_type', '')}
            />
          )}
          {filters.source && (
            <Chip
              label={`Source: ${filters.source}`}
              size="small"
              onDelete={() => handleFilterChange('source', '')}
            />
          )}
          {filters.is_corp_to_corp === true && (
            <Chip
              label="Corp-to-Corp"
              size="small"
              onDelete={() => handleFilterChange('is_corp_to_corp', null)}
            />
          )}
          {filters.min_relevance_score > 0 && (
            <Chip
              label={`Min Relevance: ${filters.min_relevance_score.toFixed(1)}`}
              size="small"
              onDelete={() => handleFilterChange('min_relevance_score', 0)}
            />
          )}
          {(filters.min_salary > 0 || filters.max_salary < 200000) && (
            <Chip
              label={`Salary: $${filters.min_salary.toLocaleString()}-$${filters.max_salary.toLocaleString()}`}
              size="small"
              onDelete={() => {
                handleFilterChange('min_salary', 0);
                handleFilterChange('max_salary', 200000);
              }}
            />
          )}
        </Box>
      </Box>
    </Paper>
  );
};

export default JobFilters;