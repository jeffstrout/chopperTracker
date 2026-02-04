# ChopperTracker Project Overview

## Purpose
A real-time helicopter and aircraft tracking system with a responsive web interface, Python backend, and distributed ADS-B data collection. The web UI provides an interactive map-based dashboard with advanced filtering, search, and 3-second auto-refresh. Branded as "Chopper Tracker" with helicopters as the default view.

## Architecture

### Core Components
1. **Interactive Map**: OpenStreetMap-based flight visualization with custom aircraft markers
2. **Real-time Data**: Consumes Flight Tracker Collector API endpoints with 3-second auto-refresh
3. **Responsive UI**: Mobile-first design working on desktop, tablet, and mobile
4. **Smart Flight Filtering**: Advanced filtering with automatic ground aircraft exclusion
5. **Settings Menu**: Version info and app settings via gear icon
6. **Data Collectors**: Poll flight tracking APIs/sources (OpenSky, dump1090, Pi stations)
7. **Redis Cache**: Store and merge flight data from multiple sources
8. **API Endpoints**: JSON and tabular (CSV) format endpoints

### Technology Stack
- **Frontend**: Vite + React 18 (TypeScript), Leaflet.js, Tailwind CSS, Axios
- **Backend**: Python 3.11+, FastAPI, Redis, httpx, Pydantic
- **Pi Forwarder**: Python 3, requests library
- **Deployment**: Docker + Docker Compose, Digital Ocean

### Data Flow
1. **Multi-Source Data Collection**: Collectors run concurrently via asyncio
   - **Pi Stations**: Real-time ADS-B data from Raspberry Pi receivers (every 15 seconds)
   - **dump1090**: Local ADS-B receiver data (every 15 seconds)
   - **OpenSky**: Global network data with smart rate limiting (5-minute backoff on 429 errors)
2. **Data Blending**: Priority-based merging (Pi > dump1090 > OpenSky)
   - Deduplication based on ICAO hex codes with source priority override
3. **Aircraft Database Enrichment**: Registration, model, operator, manufacturer lookups
4. **Helicopter Identification**: Uses ICAO aircraft class starting with 'H'
5. **Redis Storage**: Pipeline operations with pre-serialized data
   - `{region}:flights`: All flights (5-minute TTL)
   - `{region}:choppers`: Helicopters only
   - `pi_data:{region}:{station_id}`: Pi station raw data
   - `aircraft_live:{hex}`: Individual aircraft lookups
6. Web interface queries Redis via API endpoints

### API Endpoints
- `GET /health` - Health check
- `GET /api/v1/{region}/flights` - All flights for region (airborne only)
- `GET /api/v1/{region}/choppers` - Helicopters only
- `GET /api/v1/{region}/stats` - Region statistics
- `GET /api/v1/{region}/flights/tabular` - Flights as CSV
- `GET /api/v1/{region}/choppers/tabular` - Helicopters as CSV
- `GET /api/v1/regions` - Available regions
- `GET /api/v1/status` - System health and collector status
- `POST /api/v1/aircraft/bulk` - Pi Station API: receive bulk aircraft data
- `GET /docs` - Swagger UI API documentation

### Aircraft Data Format
```typescript
interface Aircraft {
  hex: string;              // ICAO24 hex code
  flight?: string;          // Callsign/flight number
  lat: number;              // Latitude
  lon: number;              // Longitude
  alt_baro?: number;        // Barometric altitude (feet)
  alt_geom?: number;        // Geometric altitude (feet)
  gs?: number;              // Ground speed (knots)
  track?: number;           // True track (degrees)
  baro_rate?: number;       // Vertical rate (ft/min)
  squawk?: string;          // Squawk code
  on_ground: boolean;       // Ground status (filtered out)
  seen: number;             // Seconds since last update
  rssi?: number;            // Signal strength (dump1090 only)
  distance_miles?: number;  // Distance from region center
  data_source: string;      // dump1090/opensky/blended
  registration?: string;    // Aircraft registration
  model?: string;           // Aircraft model
  operator?: string;        // Airline/operator
  icao_aircraft_class?: string; // ICAO aircraft class
}
```

## Frontend Component Architecture

```
src/
├── App.tsx                        # Main app with state management
├── main.tsx                       # Entry point
├── components/
│   ├── Map/
│   │   ├── FlightMap.tsx          # Main map container
│   │   ├── AircraftMarker.tsx     # Aircraft markers with icons
│   │   └── SafeMapContainer.tsx   # Error boundary for Leaflet
│   ├── UI/
│   │   ├── Header.tsx             # Header with settings
│   │   ├── Sidebar.tsx            # Flight list with helicopter toggle
│   │   ├── StatusBar.tsx          # Connection status and stats
│   │   └── FilterPanel.tsx        # Filter controls
│   └── Aircraft/
│       ├── AircraftList.tsx       # Table/list view
│       └── AircraftCard.tsx       # Aircraft details
├── hooks/
│   ├── useFlightData.ts           # Data fetching with 3s auto-refresh
│   ├── useFilters.ts              # Filter state with ground exclusion
│   ├── usePWA.ts                  # Progressive Web App
│   └── useVersion.ts              # Version info
├── services/
│   ├── api.ts                     # API client
│   └── types.ts                   # TypeScript types
└── styles/
    └── globals.css                # Global styles with dark mode
```

## Configuration

### Frontend Environment Variables
```bash
VITE_API_BASE_URL=http://localhost:8000/api/v1   # Backend API URL
VITE_DEFAULT_REGION=etex                          # Default region
```

### Backend Environment Variables
```bash
REDIS_HOST=localhost        # Redis host
REDIS_PORT=6379             # Redis port
REDIS_DB=0                  # Redis database
LOG_LEVEL=INFO              # Log level
CONFIG_FILE=collectors.yaml # Collector config file
API_BASE_URL=http://localhost:8000/api/v1  # API URL for config.js
ENV=development             # Environment name
FRONTEND_URL=http://localhost:5173  # Frontend redirect URL
```

## Development

### Local Setup
```bash
# Backend (starts API + Redis)
cd BackEnd
docker-compose up

# Frontend (separate terminal)
cd FrontEnd
npm install
npm run dev
```

Frontend runs on `http://localhost:5173` with Vite proxy to `http://localhost:8000`.

### Production Build
```bash
# Frontend
cd FrontEnd
npm run build    # outputs to dist/

# Backend Docker image
cd BackEnd
docker build -t choppertracker-backend .
```

### Production Deployment (Digital Ocean)
```bash
cd BackEnd
docker-compose -f docker-compose.prod.yml up -d
```

Set environment variables for production:
- `API_BASE_URL=https://api.choppertracker.com/api/v1`
- `ENV=production`
- `FRONTEND_URL=https://choppertracker.com`

## Raspberry Pi ADS-B Forwarder

### Overview
The Pi forwarder (`pi_forwarder/pi_forwarder/aircraft_forwarder.py`) collects aircraft data from a local dump1090 instance and forwards it to the backend API.

### Configuration
- `API_ENDPOINT`: Backend bulk API URL (env var or CLI arg `--api-endpoint`)
- `API_KEY`: Station-specific API key (e.g., "etex.abc123def456ghi789jkl012")
- `STATION_ID`: Unique station identifier (e.g., "ETEX01")
- `DUMP1090_URL`: Local dump1090 endpoint (default: http://localhost:8080/data/aircraft.json)

### Running as a Systemd Service
```bash
sudo nano /etc/systemd/system/aircraft-forwarder.service
```

```ini
[Unit]
Description=Aircraft Data Forwarder for dump1090
After=network.target dump1090-fa.service
Wants=dump1090-fa.service

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=/home/pi/aircraft-forwarder
ExecStart=/usr/bin/python3 /home/pi/aircraft-forwarder/aircraft_forwarder.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable aircraft-forwarder.service
sudo systemctl start aircraft-forwarder.service
```

### Service Management
```bash
sudo systemctl status aircraft-forwarder.service    # Check status
sudo journalctl -u aircraft-forwarder.service -f    # Follow logs
sudo systemctl restart aircraft-forwarder.service   # Restart
```

## Collector Configuration

The backend collector config is in `BackEnd/config/collectors.yaml`. Key sections:
- **global**: Redis connection, polling intervals, logging
- **regions**: Region definitions with center coordinates, radius, and data sources
- **pi_stations**: API keys for Pi station authentication
- **helicopter_patterns**: Identification patterns for helicopters

## Troubleshooting

### Performance Issues
- Check Redis connectivity: `redis-cli ping`
- Check collector logs for API rate limiting
- Verify OpenSky API credits (400/day anonymous, 4000/day authenticated)
- Monitor Redis memory: `redis-cli info memory`

### Helicopter Identification
- Only uses ICAO aircraft class starting with 'H'
- Requires aircraftDatabase.csv to be loaded for enrichment
- Check `BackEnd/config/collectors.yaml` helicopter_patterns section
