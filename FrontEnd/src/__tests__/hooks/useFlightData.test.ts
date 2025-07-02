import { renderHook, act, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { useFlightData } from '../../hooks/useFlightData';
import flightAPI from '../../services/api';

// Mock the API module
vi.mock('../../services/api', () => ({
  default: {
    getFlights: vi.fn(),
    getHelicopters: vi.fn(),
    getRegions: vi.fn(),
    getSystemStatus: vi.fn(),
    checkConnection: vi.fn(),
  },
}));

describe('useFlightData', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('initializes with default values', () => {
    const { result } = renderHook(() => useFlightData());

    expect(result.current.aircraft).toEqual([]);
    expect(result.current.loading).toBe(true);
    expect(result.current.error).toBeNull();
    expect(result.current.lastUpdate).toBeNull();
    expect(result.current.region).toBe('etex');
  });

  it('fetches flight data on mount', async () => {
    const mockFlights = [
      { hex: 'ABC123', lat: 32.5, lon: -95.5, flight: 'TEST001' },
      { hex: 'DEF456', lat: 32.6, lon: -95.6, flight: 'TEST002' },
    ];

    const mockRegions = {
      regions: [
        { name: 'etex', lat: 32.5, lon: -95.5, radius_miles: 50 },
      ],
      total_regions: 1,
    };

    const mockStatus = {
      collectors: { total: 2, active: 2 },
      cache: { status: 'connected' },
      uptime_seconds: 1000,
      last_collection: new Date().toISOString(),
    };

    vi.mocked(flightAPI.getFlights).mockResolvedValue(mockFlights);
    vi.mocked(flightAPI.getRegions).mockResolvedValue(mockRegions);
    vi.mocked(flightAPI.getSystemStatus).mockResolvedValue(mockStatus);

    const { result } = renderHook(() => useFlightData());

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.aircraft).toEqual(mockFlights);
    expect(result.current.error).toBeNull();
    expect(result.current.lastUpdate).toBeInstanceOf(Date);
    expect(result.current.regionData).toEqual(mockRegions.regions[0]);
  });

  it('handles API errors gracefully', async () => {
    const mockError = {
      message: 'Network error',
      status: 500,
      timestamp: new Date().toISOString(),
      endpoint: '/api/v1/etex/flights',
    };

    vi.mocked(flightAPI.getFlights).mockRejectedValue(mockError);
    vi.mocked(flightAPI.getRegions).mockResolvedValue({ regions: [], total_regions: 0 });
    vi.mocked(flightAPI.getSystemStatus).mockResolvedValue(null);

    const { result } = renderHook(() => useFlightData());

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.aircraft).toEqual([]);
    expect(result.current.error).toEqual(mockError);
  });

  it('auto-refreshes at specified interval', async () => {
    const mockFlights = [{ hex: 'ABC123', lat: 32.5, lon: -95.5 }];
    vi.mocked(flightAPI.getFlights).mockResolvedValue(mockFlights);
    vi.mocked(flightAPI.getRegions).mockResolvedValue({ regions: [], total_regions: 0 });
    vi.mocked(flightAPI.getSystemStatus).mockResolvedValue(null);

    const { result } = renderHook(() => 
      useFlightData({ autoRefresh: true, refreshInterval: 3000 })
    );

    // Wait for initial load
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(vi.mocked(flightAPI.getFlights)).toHaveBeenCalledTimes(1);

    // Advance timer by refresh interval
    act(() => {
      vi.advanceTimersByTime(3000);
    });

    await waitFor(() => {
      expect(vi.mocked(flightAPI.getFlights)).toHaveBeenCalledTimes(2);
    });
  });

  it('pauses refresh when tab is hidden', async () => {
    const mockFlights = [{ hex: 'ABC123', lat: 32.5, lon: -95.5 }];
    vi.mocked(flightAPI.getFlights).mockResolvedValue(mockFlights);
    vi.mocked(flightAPI.getRegions).mockResolvedValue({ regions: [], total_regions: 0 });
    vi.mocked(flightAPI.getSystemStatus).mockResolvedValue(null);

    renderHook(() => useFlightData({ autoRefresh: true, refreshInterval: 3000 }));

    // Wait for initial load
    await waitFor(() => {
      expect(vi.mocked(flightAPI.getFlights)).toHaveBeenCalledTimes(1);
    });

    // Simulate tab becoming hidden
    act(() => {
      Object.defineProperty(document, 'hidden', {
        configurable: true,
        value: true,
      });
      document.dispatchEvent(new Event('visibilitychange'));
    });

    // Advance timer
    act(() => {
      vi.advanceTimersByTime(3000);
    });

    // Should not have made another call
    expect(vi.mocked(flightAPI.getFlights)).toHaveBeenCalledTimes(1);

    // Simulate tab becoming visible again
    act(() => {
      Object.defineProperty(document, 'hidden', {
        configurable: true,
        value: false,
      });
      document.dispatchEvent(new Event('visibilitychange'));
    });

    // Should immediately fetch when tab becomes visible
    await waitFor(() => {
      expect(vi.mocked(flightAPI.getFlights)).toHaveBeenCalledTimes(2);
    });
  });

  it('changes region and fetches new data', async () => {
    const mockFlights = [{ hex: 'ABC123', lat: 32.5, lon: -95.5 }];
    vi.mocked(flightAPI.getFlights).mockResolvedValue(mockFlights);
    vi.mocked(flightAPI.getRegions).mockResolvedValue({ regions: [], total_regions: 0 });
    vi.mocked(flightAPI.getSystemStatus).mockResolvedValue(null);

    const { result } = renderHook(() => useFlightData());

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    // Change region
    act(() => {
      result.current.setRegion('wtex');
    });

    expect(result.current.region).toBe('wtex');
    expect(result.current.loading).toBe(true);

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(vi.mocked(flightAPI.getFlights)).toHaveBeenCalledWith('wtex');
  });
});