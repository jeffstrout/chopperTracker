import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import axios from 'axios';
import flightAPI from '../../services/api';

// Mock axios
vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => ({
      get: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    })),
  },
}));

describe('FlightTrackerAPI', () => {
  let mockAxiosInstance: any;

  beforeEach(() => {
    vi.clearAllMocks();
    mockAxiosInstance = axios.create();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('API configuration', () => {
    it('uses environment variable for base URL', () => {
      expect(axios.create).toHaveBeenCalledWith(
        expect.objectContaining({
          baseURL: expect.any(String),
          timeout: 10000,
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
          }),
        })
      );
    });

    it('adds timestamp to requests to prevent caching', () => {
      const requestInterceptor = mockAxiosInstance.interceptors.request.use.mock.calls[0][0];
      const config = { params: {} };
      
      const modifiedConfig = requestInterceptor(config);
      
      expect(modifiedConfig.params._t).toBeDefined();
      expect(typeof modifiedConfig.params._t).toBe('number');
    });
  });

  describe('API methods', () => {
    it('getFlights returns aircraft array', async () => {
      const mockAircraft = [
        { hex: 'ABC123', lat: 32.5, lon: -95.5 },
        { hex: 'DEF456', lat: 32.6, lon: -95.6 },
      ];
      
      mockAxiosInstance.get.mockResolvedValue({ data: mockAircraft });
      
      const result = await flightAPI.getFlights('etex');
      
      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/api/v1/etex/flights');
      expect(result).toEqual(mockAircraft);
    });

    it('getFlights handles object response with aircraft array', async () => {
      const mockAircraft = [
        { hex: 'ABC123', lat: 32.5, lon: -95.5 },
      ];
      
      mockAxiosInstance.get.mockResolvedValue({ 
        data: { aircraft: mockAircraft, count: 1 } 
      });
      
      const result = await flightAPI.getFlights('etex');
      
      expect(result).toEqual(mockAircraft);
    });

    it('getHelicopters filters helicopter data', async () => {
      const mockHelicopters = [
        { hex: 'HEL001', lat: 32.5, lon: -95.5, icao_aircraft_class: 'H1T' },
      ];
      
      mockAxiosInstance.get.mockResolvedValue({ data: mockHelicopters });
      
      const result = await flightAPI.getHelicopters('etex');
      
      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/api/v1/etex/choppers');
      expect(result).toEqual(mockHelicopters);
    });

    it('getSystemStatus returns status object', async () => {
      const mockStatus = {
        collectors: { total: 2, active: 2 },
        cache: { status: 'connected' },
        uptime_seconds: 1000,
      };
      
      mockAxiosInstance.get.mockResolvedValue({ data: mockStatus });
      
      const result = await flightAPI.getSystemStatus();
      
      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/api/v1/status');
      expect(result).toEqual(mockStatus);
    });

    it('checkConnection returns true when API is reachable', async () => {
      mockAxiosInstance.get.mockResolvedValue({ 
        data: { status: 'ok', timestamp: new Date().toISOString() } 
      });
      
      const result = await flightAPI.checkConnection();
      
      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/health');
      expect(result).toBe(true);
    });

    it('checkConnection returns false when API is not reachable', async () => {
      mockAxiosInstance.get.mockRejectedValue(new Error('Network error'));
      
      const result = await flightAPI.checkConnection();
      
      expect(result).toBe(false);
    });
  });

  describe('Error handling', () => {
    it('transforms axios errors to APIError format', async () => {
      const responseInterceptor = mockAxiosInstance.interceptors.response.use.mock.calls[0][1];
      
      const axiosError = {
        message: 'Request failed',
        response: { status: 500 },
        config: { url: '/api/v1/etex/flights' },
      };
      
      try {
        await responseInterceptor(axiosError);
      } catch (error: any) {
        expect(error).toEqual({
          message: 'Request failed',
          status: 500,
          timestamp: expect.any(String),
          endpoint: '/api/v1/etex/flights',
        });
      }
    });

    it('handles errors without response object', async () => {
      const responseInterceptor = mockAxiosInstance.interceptors.response.use.mock.calls[0][1];
      
      const axiosError = {
        message: 'Network Error',
        config: { url: '/api/v1/etex/flights' },
      };
      
      try {
        await responseInterceptor(axiosError);
      } catch (error: any) {
        expect(error.status).toBeUndefined();
        expect(error.message).toBe('Network Error');
      }
    });
  });
});