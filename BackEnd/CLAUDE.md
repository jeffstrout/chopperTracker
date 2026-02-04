# Flight Tracker Collector - Backend

## Overview
Python FastAPI backend that collects, blends, and serves real-time aircraft data from multiple sources.

## Project Structure
```
BackEnd/
├── src/
│   ├── main.py                    # FastAPI app entry point
│   ├── cli.py                     # CLI collector mode
│   ├── version.py                 # Version info
│   ├── api/
│   │   └── endpoints.py           # API route handlers
│   ├── config/
│   │   └── loader.py              # YAML config loader
│   ├── services/
│   │   ├── collector_service.py   # Data collection orchestrator
│   │   ├── redis_service.py       # Redis operations
│   │   ├── data_blender.py        # Multi-source data merging
│   │   └── aircraft_db.py         # Aircraft database lookups
│   ├── collectors/
│   │   ├── opensky.py             # OpenSky Network collector
│   │   ├── dump1090.py            # Local ADS-B collector
│   │   └── base.py                # Base collector class
│   ├── middleware/
│   │   └── security.py            # Rate limiting, security headers
│   └── utils/
│       └── logging_config.py      # Logging setup
├── config/
│   ├── collectors.yaml            # Production config
│   ├── collectors-local.yaml      # Local dev config
│   └── collectors-dev.yaml        # Docker dev config
├── run.py                         # Entry point (api or cli mode)
├── Dockerfile                     # Production Docker image
├── docker-compose.yml             # Local dev (app + Redis)
├── docker-compose.prod.yml        # Production (app + Redis)
├── requirements.txt               # Python dependencies
└── .env.example                   # Environment variable template
```

## Key Services

### CollectorService
Orchestrates data collection from all sources. Runs collectors concurrently via asyncio.gather().

### DataBlender
Merges data from multiple sources with priority: Pi Stations > dump1090 > OpenSky.
Deduplicates by ICAO hex code. Enriches with aircraft database.

### RedisService
Manages Redis cache. Keys:
- `{region}:flights` - All flights (5-min TTL)
- `{region}:choppers` - Helicopters only
- `pi_data:{region}:{station_id}` - Pi station data
- `aircraft_live:{hex}` - Individual aircraft

### SecurityMiddleware
Rate limiting per client IP. Configurable per-endpoint limits. Security headers. Suspicious request detection.

## Running

```bash
# API server
python run.py --mode api --reload

# Collector only (no web server)
python run.py --mode cli

# Docker
docker-compose up
```

## Environment Variables
See `.env.example` for all options. Key vars:
- `REDIS_HOST`, `REDIS_PORT`, `REDIS_DB`
- `API_BASE_URL` - Used in /config.js endpoint
- `FRONTEND_URL` - Used for root redirect
- `ENV` - "development" or "production"
- `CONFIG_FILE` - YAML config filename
