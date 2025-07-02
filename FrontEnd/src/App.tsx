import React, { useState, useEffect } from 'react';
import { Plane, Settings, Menu, X } from 'lucide-react';
import FlightMap from './components/Map/FlightMap';
import Header from './components/UI/Header';
import Sidebar from './components/UI/Sidebar';
import StatusBar from './components/UI/StatusBar';
import { useFlightData } from './hooks/useFlightData';
import { useFilters } from './hooks/useFilters';
import type { UIState } from './services/types';
import ErrorBoundary from './components/ErrorBoundary';
import APIErrorBoundary from './components/APIErrorBoundary';
import MapErrorBoundary from './components/Map/MapErrorBoundary';

function App() {
  // Check if mobile on initial load
  const isMobile = window.innerWidth < 1024; // lg breakpoint

  // Safe coordinate parsing with validation
  const getInitialCenter = (): [number, number] => {
    const lat = parseFloat(import.meta.env.VITE_MAP_CENTER_LAT || '32.3513');
    const lon = parseFloat(import.meta.env.VITE_MAP_CENTER_LON || '-95.3011');
    return [
      (typeof lat === 'number' && !isNaN(lat) && isFinite(lat)) ? lat : 32.3513,
      (typeof lon === 'number' && !isNaN(lon) && isFinite(lon)) ? lon : -95.3011
    ];
  };

  // UI state management
  const [uiState, setUIState] = useState<UIState>({
    selectedAircraft: undefined,
    mapCenter: getInitialCenter(),
    mapZoom: parseInt(import.meta.env.VITE_MAP_DEFAULT_ZOOM || '8', 10) || 8,
    sidebarOpen: !isMobile, // Start closed on mobile, open on desktop
    autoRefresh: true,
    refreshInterval: parseInt(import.meta.env.VITE_REFRESH_INTERVAL || '3000', 10),
  });

  // Flight data and filtering
  const { 
    aircraft, 
    region, 
    regionData,
    setRegion, 
    loading, 
    error, 
    lastUpdate,
    systemStatus 
  } = useFlightData(uiState.autoRefresh, uiState.refreshInterval);
  
  const { filters, filteredAircraft, setFilters } = useFilters(aircraft);

  // Dark mode follows system preference automatically
  useEffect(() => {
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');
    const updateDarkMode = (isDark: boolean) => {
      document.documentElement.classList.toggle('dark', isDark);
    };

    // Initialize dark mode
    updateDarkMode(prefersDark.matches);

    // Listen for system theme changes
    const handleChange = (e: MediaQueryListEvent) => updateDarkMode(e.matches);
    prefersDark.addEventListener('change', handleChange);

    return () => prefersDark.removeEventListener('change', handleChange);
  }, []);

  // Handle aircraft selection
  const handleAircraftSelect = (hex?: string) => {
    setUIState(prev => ({ ...prev, selectedAircraft: hex }));
  };

  // Handle map state changes
  const handleMapStateChange = (center: [number, number], zoom: number) => {
    setUIState(prev => ({ ...prev, mapCenter: center, mapZoom: zoom }));
  };

  // Toggle sidebar
  const toggleSidebar = () => {
    setUIState(prev => ({ ...prev, sidebarOpen: !prev.sidebarOpen }));
  };


  // Selected aircraft data
  const selectedAircraftData = filteredAircraft.find(
    ac => ac.hex === uiState.selectedAircraft
  );

  return (
    <ErrorBoundary>
      <APIErrorBoundary onConnectionRestored={() => window.location.reload()}>
        <div className="h-screen flex flex-col bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <Header
        region={region}
        onRegionChange={setRegion}
        onToggleSidebar={toggleSidebar}
        systemStatus={systemStatus}
      />

      {/* Main content area */}
      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar */}
        <Sidebar
          isOpen={uiState.sidebarOpen}
          aircraft={filteredAircraft}
          totalAircraft={aircraft}
          selectedAircraft={uiState.selectedAircraft}
          onAircraftSelect={handleAircraftSelect}
          filters={filters}
          onFiltersChange={setFilters}
          onClose={() => setUIState(prev => ({ ...prev, sidebarOpen: false }))}
        />

        {/* Map container */}
        <div className="flex-1 relative">
          <MapErrorBoundary>
            <FlightMap
              aircraft={filteredAircraft}
              selectedAircraft={selectedAircraftData}
              center={uiState.mapCenter}
              zoom={uiState.mapZoom}
              regionData={regionData}
              filters={filters}
              onAircraftSelect={handleAircraftSelect}
              onMapStateChange={handleMapStateChange as any}
            />
          </MapErrorBoundary>

          {/* Mobile sidebar toggle */}
          {!uiState.sidebarOpen && (
            <button
              onClick={toggleSidebar}
              className="lg:hidden absolute top-4 left-4 z-[80] bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg p-2 shadow-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              aria-label="Toggle flight list"
            >
              <Menu size={20} className="text-gray-700 dark:text-gray-300" />
            </button>
          )}

          {/* Loading overlay */}
          {loading && (
            <div className="absolute inset-0 bg-black/20 flex items-center justify-center z-1000">
              <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow-lg flex items-center space-x-3">
                <div className="spinner"></div>
                <span className="text-gray-700 dark:text-gray-300 font-medium">
                  Loading flight data...
                </span>
              </div>
            </div>
          )}

          {/* Error banner */}
          {error && (
            <div className="absolute top-4 right-4 z-1000 bg-red-100 dark:bg-red-900 border border-red-400 text-red-700 dark:text-red-300 px-4 py-3 rounded-lg shadow-lg max-w-md">
              <div className="flex items-start">
                <div className="flex-1">
                  <p className="font-medium">Connection Error</p>
                  <p className="text-sm mt-1">{error.message}</p>
                </div>
                <button
                  onClick={() => window.location.reload()}
                  className="ml-3 text-red-700 dark:text-red-300 hover:text-red-900 dark:hover:text-red-100"
                  aria-label="Retry"
                >
                  <Settings size={16} />
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Status bar */}
      <StatusBar
        aircraft={filteredAircraft}
        totalAircraft={aircraft}
        lastUpdate={lastUpdate}
        isOnline={!error}
        region={region}
        systemStatus={systemStatus}
      />

        </div>
      </APIErrorBoundary>
    </ErrorBoundary>
  );
}

export default App;