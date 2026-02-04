# Flight Tracker Web UI

## Purpose
Responsive web interface for real-time flight visualization. Interactive map with advanced filtering, search, and 3-second auto-refresh. Helicopter-first design branded as "Chopper Tracker".

## Technology Stack
- **Framework**: Vite + React 18 (TypeScript)
- **Mapping**: Leaflet.js with OpenStreetMap tiles (react-leaflet)
- **Styling**: Tailwind CSS with auto dark mode
- **HTTP Client**: Axios
- **State Management**: React Context + useReducer
- **Icons**: Lucide React
- **Testing**: Vitest

## Project Structure
```
FrontEnd/
├── src/
│   ├── App.tsx                    # Main app with state management
│   ├── main.tsx                   # Entry point
│   ├── components/
│   │   ├── Map/
│   │   │   ├── FlightMap.tsx      # Main map container
│   │   │   ├── AircraftMarker.tsx # Aircraft markers with SVG icons
│   │   │   └── SafeMapContainer.tsx
│   │   ├── UI/
│   │   │   ├── Header.tsx         # Header with settings
│   │   │   ├── Sidebar.tsx        # Flight list + helicopter toggle
│   │   │   ├── StatusBar.tsx      # Connection status + stats
│   │   │   └── FilterPanel.tsx    # Filter controls
│   │   └── Aircraft/
│   │       ├── AircraftList.tsx   # Table view
│   │       └── AircraftCard.tsx   # Detail card
│   ├── hooks/
│   │   ├── useFlightData.ts       # Data fetching (3s refresh)
│   │   ├── useFilters.ts          # Filter state
│   │   ├── usePWA.ts              # PWA functionality
│   │   └── useVersion.ts          # Version info
│   ├── services/
│   │   ├── api.ts                 # API client
│   │   └── types.ts               # TypeScript types
│   └── styles/
│       └── globals.css            # Global styles + dark mode
├── .env.development               # Local dev API URL
├── .env.production                # Production API URL
├── .env.example                   # Template
├── vite.config.ts                 # Vite config with dev proxy
├── tailwind.config.js             # Tailwind configuration
├── tsconfig.json                  # TypeScript config
└── package.json
```

## API Connection
The API client (`src/services/api.ts`) resolves the backend URL in this priority:
1. `VITE_API_BASE_URL` env var
2. `window.FLIGHT_TRACKER_CONFIG.API_BASE_URL` (from backend /config.js)
3. Fallback: `http://localhost:8000/api/v1`

## Development
```bash
npm install
npm run dev        # Dev server on http://localhost:5173
npm run build      # Production build to dist/
npm run preview    # Preview production build
npm run test       # Run Vitest tests
```

Vite dev server proxies `/api` requests to `http://localhost:8000`.

## Key Design Decisions
- **Leaflet + OpenStreetMap**: Free, no API keys, lightweight
- **Ground aircraft filtering**: Reduces displayed data by 30-40%
- **3-second auto-refresh**: Balances freshness with API load
- **SVG aircraft icons**: Custom helicopters (X-shaped rotors) and airplanes, rotated by heading
- **Mobile-first responsive**: Breakpoints at sm/md/lg/xl
