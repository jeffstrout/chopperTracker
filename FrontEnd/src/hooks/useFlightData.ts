import { useState, useEffect, useCallback, useRef } from 'react';
import flightAPI from '../services/api';
import type { Aircraft, SystemStatus, APIError, Region } from '../services/types';

interface UseFlightDataReturn {
  aircraft: Aircraft[];
  region: string;
  regionData: Region | null;
  setRegion: (region: string) => void;
  loading: boolean;
  error: APIError | null;
  lastUpdate: Date | null;
  systemStatus: SystemStatus | null;
  refetch: () => Promise<void>;
}

export function useFlightData(
  autoRefresh: boolean = true,
  refreshInterval: number = 3000
): UseFlightDataReturn {
  const [aircraft, setAircraft] = useState<Aircraft[]>([]);
  const [region, setRegion] = useState<string>(
    import.meta.env.VITE_DEFAULT_REGION || 'etex'
  );
  const [regionData, setRegionData] = useState<Region | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<APIError | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);
  const [systemStatus, setSystemStatus] = useState<SystemStatus | null>(null);
  
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const systemIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const abortControllerRef = useRef<AbortController | null>(null);
  const retryAttemptRef = useRef<number>(0);
  const backoffTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Fetch flight data (fast updates)
  const fetchFlightData = useCallback(async (signal?: AbortSignal) => {
    const fetchStartTime = Date.now();
    // Fetching flight data
    
    try {
      setError(null);
      
      // Only fetch flights for fast updates
      const flightData = await flightAPI.getFlights(region);

      // Check if request was aborted
      if (signal?.aborted) return;

      setAircraft(flightData);
      setLoading(false);
      setLastUpdate(new Date());

      const fetchTime = Date.now() - fetchStartTime;
      // Successfully loaded flight data
      // Reset retry attempt on success
      retryAttemptRef.current = 0;
    } catch (err: any) {
      // Don't set error if request was aborted
      if (signal?.aborted) return;

      const apiError = err as APIError;
      
      // Check if it's a rate limit error (429)
      if (err.response?.status === 429 || err.status === 429) {
        // Calculate exponential backoff: 2^attempt * 1000ms (1s, 2s, 4s, 8s, etc.)
        const backoffTime = Math.min(Math.pow(2, retryAttemptRef.current) * 1000, 60000); // Max 60s
        retryAttemptRef.current += 1;
        
        setError({
          ...apiError,
          message: `Rate limit exceeded. Retrying in ${backoffTime / 1000}s...`,
          timestamp: new Date().toISOString(),
        });
        setLoading(false);
        
        // Clear any existing backoff timeout
        if (backoffTimeoutRef.current) {
          clearTimeout(backoffTimeoutRef.current);
        }
        
        // Schedule retry with exponential backoff
        backoffTimeoutRef.current = setTimeout(() => {
          fetchFlightData(signal);
        }, backoffTime);
      } else {
        // For other errors, set error normally
        setError(apiError);
        setLoading(false);
        // Reset retry attempts for non-429 errors
        retryAttemptRef.current = 0;
      }
    }
  }, [region]);

  // Fetch system data (slow updates)
  const fetchSystemData = useCallback(async () => {
    try {
      const [statusData, regionsResponse] = await Promise.all([
        flightAPI.getSystemStatus(),
        flightAPI.getRegions()
      ]);

      // Find current region data
      const currentRegionData = regionsResponse.regions?.find(r => 
        r.name?.toLowerCase().includes('texas') || 
        r.name?.toLowerCase().includes('etex') ||
        region === 'etex'
      ) || regionsResponse.regions?.[0] || null;

      setSystemStatus(statusData);
      setRegionData(currentRegionData);
    } catch (err) {
      // System data errors don't need to stop flight updates
      console.warn('System data fetch failed:', err);
    }
  }, [region]);

  // Manual refetch function
  const refetch = useCallback(async () => {
    // Cancel any existing request
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    // Create new abort controller
    const controller = new AbortController();
    abortControllerRef.current = controller;

    setLoading(true);
    await fetchFlightData(controller.signal);
    await fetchSystemData(); // Also fetch system data on manual refresh
  }, [fetchFlightData, fetchSystemData]);

  // Set up auto-refresh interval
  useEffect(() => {
    // Setting up refresh interval
    
    // Clear any existing intervals
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
    if (systemIntervalRef.current) {
      clearInterval(systemIntervalRef.current);
    }

    // Initial fetch - start fast, then load system data
    fetchFlightData();
    fetchSystemData();

    // Set up auto-refresh if enabled
    if (autoRefresh && refreshInterval > 0) {
      // Starting refresh interval for flight data only
      console.log('Setting up flight interval:', refreshInterval);
      intervalRef.current = setInterval(() => {
        console.log('Flight data fetch triggered at:', new Date().toLocaleTimeString());
        fetchFlightData();
      }, refreshInterval);
    }

    // Set up slower interval for system data (every 30 seconds)
    systemIntervalRef.current = setInterval(() => {
      fetchSystemData();
    }, 30000);

    // Cleanup function
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
      if (systemIntervalRef.current) {
        clearInterval(systemIntervalRef.current);
      }
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
      if (backoffTimeoutRef.current) {
        clearTimeout(backoffTimeoutRef.current);
      }
    };
  }, [autoRefresh, refreshInterval, region, fetchFlightData, fetchSystemData]); // Only re-run when these change

  // Handle region changes
  const handleRegionChange = useCallback((newRegion: string) => {
    setRegion(newRegion);
    setLoading(true);
    setError(null);
    setAircraft([]);
  }, []);

  // Handle visibility change (pause/resume when tab is hidden/visible)
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // Tab hidden - pausing auto-refresh
        // Tab is hidden, pause auto-refresh
        if (intervalRef.current) {
          clearInterval(intervalRef.current);
        }
      } else {
        // Tab visible - resuming auto-refresh
        // Tab is visible, resume auto-refresh
        if (autoRefresh && refreshInterval > 0) {
          // Immediate fetch when tab becomes visible
          fetchFlightData();
          
          intervalRef.current = setInterval(() => {
            fetchFlightData();
          }, refreshInterval);
        }
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [autoRefresh, refreshInterval, fetchFlightData]);

  // Handle online/offline status
  useEffect(() => {
    const handleOnline = () => {
      // Connection restored, resuming flight data updates
      if (autoRefresh) {
        refetch();
      }
    };

    const handleOffline = () => {
      // Connection lost, pausing flight data updates
      setError({
        message: 'Connection lost. Flight data updates paused.',
        timestamp: new Date().toISOString(),
      });
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [autoRefresh, refetch]);

  return {
    aircraft,
    region,
    regionData,
    setRegion: handleRegionChange,
    loading,
    error,
    lastUpdate,
    systemStatus,
    refetch,
  };
}