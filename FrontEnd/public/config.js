// Flight Tracker Web UI Configuration (static fallback)
// In production, the backend serves a dynamic /config.js endpoint
window.FLIGHT_TRACKER_CONFIG = {
  API_BASE_URL: 'http://localhost:8001/api/v1',
  ENV: 'development',
  CACHE_BUST: Date.now()
};
