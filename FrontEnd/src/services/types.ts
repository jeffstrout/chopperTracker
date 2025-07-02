// Aircraft data structure from Flight Tracker Collector API
export interface Aircraft {
  hex: string;                    // ICAO24 hex code
  flight?: string;                // Callsign/flight number
  lat: number;                    // Latitude
  lon: number;                    // Longitude
  alt_baro?: number;              // Barometric altitude (feet)
  alt_geom?: number;              // Geometric altitude (feet)
  gs?: number;                    // Ground speed (knots)
  track?: number;                 // True track (degrees)
  baro_rate?: number;             // Vertical rate (ft/min)
  squawk?: string;                // Squawk code
  on_ground: boolean;             // Ground status
  seen: number;                   // Seconds since last update
  rssi?: number;                  // Signal strength (dump1090 only)
  messages?: number;              // Message count (dump1090 only)
  distance_miles?: number;        // Distance from region center
  data_source: string;            // dump1090/opensky/blended
  registration?: string;          // Aircraft registration
  model?: string;                 // Aircraft model
  operator?: string;              // Airline/operator
  manufacturer?: string;          // Aircraft manufacturer
  typecode?: string;              // ICAO type code
  owner?: string;                 // Aircraft owner
  aircraft_type?: string;         // Full aircraft type description
  icao_aircraft_class?: string;   // ICAO aircraft class (e.g., L2J)
}

// API response structure
export interface FlightData {
  aircraft: Aircraft[];
  timestamp: string;
  region: string;
  total_aircraft: number;
}

// Collector configuration
export interface RegionCollector {
  type: string;
  enabled: boolean;
  url: string;
  name?: string | null;
}

// Region information
export interface Region {
  name: string;
  enabled: boolean;
  center: {
    lat: number;
    lon: number;
  };
  radius_miles: number;
  collectors: RegionCollector[];
}

// System status
export interface SystemStatus {
  status: 'healthy' | 'degraded' | 'offline';
  collectors: Record<string, CollectorStatus>;
  api_credits?: {
    opensky_remaining?: number;
    opensky_limit?: number;
    opensky_reset_time?: string;
  };
  uptime: number;
  version: string;
}

export interface CollectorStatus {
  enabled: boolean;
  last_successful_collection?: string;
  last_error?: string;
  error_count: number;
  aircraft_count: number;
  status: 'active' | 'error' | 'rate_limited' | 'disabled';
}

// Filter options
export interface FlightFilters {
  search?: string;                // Search by callsign or registration
  aircraft_type?: string[];       // Filter by aircraft types
  altitude_min?: number;          // Minimum altitude
  altitude_max?: number;          // Maximum altitude
  speed_min?: number;             // Minimum ground speed
  speed_max?: number;             // Maximum ground speed
  distance_max?: number;          // Maximum distance from center
  on_ground?: boolean;            // Ground status filter
  data_source?: string[];         // Data source filter
  helicopters_only?: boolean;     // Show only helicopters
  military_only?: boolean;        // Show only military aircraft
}

// UI state
export interface UIState {
  selectedAircraft?: string;      // Selected aircraft hex
  mapCenter: [number, number];    // Map center coordinates
  mapZoom: number;                // Map zoom level
  sidebarOpen: boolean;           // Sidebar visibility
  autoRefresh: boolean;           // Auto-refresh enabled
  refreshInterval: number;        // Refresh interval in milliseconds
}

// Chart/visualization data
export interface AircraftStats {
  total: number;
  helicopters: number;
  military: number;
  commercial: number;
  by_altitude: Record<string, number>;
  by_manufacturer: Record<string, number>;
  by_data_source: Record<string, number>;
}

// Error handling
export interface APIError {
  message: string;
  status?: number;
  timestamp: string;
  endpoint?: string;
}

// WebSocket message types (for future real-time updates)
export interface WebSocketMessage {
  type: 'aircraft_update' | 'status_update' | 'error';
  data: Aircraft[] | SystemStatus | APIError;
  timestamp: string;
  region: string;
}