import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Box,
  Button,
  Paper,
  TextField,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Snackbar,
  Chip
} from '@mui/material';
import { Add, Delete, Edit, Email } from '@mui/icons-material';
import { alertService } from '../services/api';

const AlertsPage = () => {
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  const [newAlert, setNewAlert] = useState({
    keywords: '',
    location: '',
    min_salary: '',
    email: ''
  });

  useEffect(() => {
    fetchAlerts();
  }, []);

  const fetchAlerts = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const response = await alertService.getAlerts();
      setAlerts(response.data);
    } catch (err) {
      setError('Failed to fetch alerts');
      console.error('Error fetching alerts:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateAlert = async () => {
    try {
      if (!newAlert.keywords || !newAlert.email) {
        setSnackbar({
          open: true,
          message: 'Keywords and email are required',
          severity: 'error'
        });
        return;
      }

      const alertData = {
        ...newAlert,
        min_salary: newAlert.min_salary ? parseFloat(newAlert.min_salary) : null
      };

      await alertService.createAlert(alertData);
      
      setSnackbar({
        open: true,
        message: 'Alert created successfully!',
        severity: 'success'
      });
      
      setDialogOpen(false);
      setNewAlert({ keywords: '', location: '', min_salary: '', email: '' });
      fetchAlerts();
    } catch (err) {
      setSnackbar({
        open: true,
        message: 'Failed to create alert',
        severity: 'error'
      });
    }
  };

  const handleDeleteAlert = async (alertId) => {
    try {
      await alertService.deleteAlert(alertId);
      
      setSnackbar({
        open: true,
        message: 'Alert deleted successfully!',
        severity: 'success'
      });
      
      fetchAlerts();
    } catch (err) {
      setSnackbar({
        open: true,
        message: 'Failed to delete alert',
        severity: 'error'
      });
    }
  };

  const handleSnackbarClose = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  if (loading) {
    return (
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="50vh">
          <Typography>Loading...</Typography>
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Box mb={4}>
        <Typography variant="h4" component="h1" gutterBottom>
          Job Alerts
        </Typography>
        <Typography variant="subtitle1" color="text.secondary">
          Manage your job alert subscriptions
        </Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      <Paper elevation={2} sx={{ p: 2, mb: 3 }}>
        <Box display="flex" justifyContent="space-between" alignItems="center">
          <Typography variant="h6">
            Your Alerts ({alerts.length})
          </Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => setDialogOpen(true)}
          >
            Create Alert
          </Button>
        </Box>
      </Paper>

      {alerts.length === 0 ? (
        <Paper elevation={1} sx={{ p: 4, textAlign: 'center' }}>
          <Email sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
          <Typography variant="h6" color="text.secondary">
            No job alerts yet
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
            Create your first alert to get notified about new job opportunities
          </Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => setDialogOpen(true)}
            sx={{ mt: 2 }}
          >
            Create Your First Alert
          </Button>
        </Paper>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Keywords</TableCell>
                <TableCell>Location</TableCell>
                <TableCell>Min Salary</TableCell>
                <TableCell>Email</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Created</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {alerts.map((alert) => (
                <TableRow key={alert.id}>
                  <TableCell>{alert.keywords}</TableCell>
                  <TableCell>{alert.location || 'Any'}</TableCell>
                  <TableCell>
                    {alert.min_salary ? `$${alert.min_salary.toLocaleString()}` : 'Any'}
                  </TableCell>
                  <TableCell>{alert.email}</TableCell>
                  <TableCell>
                    <Chip 
                      label={alert.is_active ? 'Active' : 'Inactive'}
                      color={alert.is_active ? 'success' : 'default'}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    {new Date(alert.created_date).toLocaleDateString()}
                  </TableCell>
                  <TableCell>
                    <IconButton
                      color="error"
                      onClick={() => handleDeleteAlert(alert.id)}
                      title="Delete Alert"
                    >
                      <Delete />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Create Alert Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create New Job Alert</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2, display: 'flex', flexDirection: 'column', gap: 2 }}>
            <TextField
              label="Keywords"
              value={newAlert.keywords}
              onChange={(e) => setNewAlert({ ...newAlert, keywords: e.target.value })}
              placeholder="e.g., Python, React, Data Science"
              fullWidth
              required
            />
            
            <TextField
              label="Location"
              value={newAlert.location}
              onChange={(e) => setNewAlert({ ...newAlert, location: e.target.value })}
              placeholder="e.g., New York, Remote, USA"
              fullWidth
            />
            
            <TextField
              label="Minimum Salary"
              type="number"
              value={newAlert.min_salary}
              onChange={(e) => setNewAlert({ ...newAlert, min_salary: e.target.value })}
              placeholder="e.g., 80000"
              fullWidth
            />
            
            <TextField
              label="Email"
              type="email"
              value={newAlert.email}
              onChange={(e) => setNewAlert({ ...newAlert, email: e.target.value })}
              placeholder="your@email.com"
              fullWidth
              required
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleCreateAlert} variant="contained">
            Create Alert
          </Button>
        </DialogActions>
      </Dialog>

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

export default AlertsPage;