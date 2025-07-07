import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline, AppBar, Toolbar, Typography, Button, Box } from '@mui/material';
import { Work, Dashboard, Notifications } from '@mui/icons-material';
import JobListPage from './pages/JobListPage';
import DashboardPage from './pages/Dashboard';
import AlertsPage from './pages/AlertsPage';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

const Navigation = () => {
  return (
    <AppBar position="static">
      <Toolbar>
        <Work sx={{ mr: 2 }} />
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
          AI Agent Recruiter
        </Typography>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button color="inherit" href="/" startIcon={<Work />}>
            Jobs
          </Button>
          <Button color="inherit" href="/dashboard" startIcon={<Dashboard />}>
            Dashboard
          </Button>
          <Button color="inherit" href="/alerts" startIcon={<Notifications />}>
            Alerts
          </Button>
        </Box>
      </Toolbar>
    </AppBar>
  );
};

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Navigation />
        <Routes>
          <Route path="/" element={<JobListPage />} />
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/alerts" element={<AlertsPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </ThemeProvider>
  );
}

export default App;