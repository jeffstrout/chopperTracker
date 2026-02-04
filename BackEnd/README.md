# Flight Tracker Collector

A Python application that collects flight data from multiple sources (Pi stations, OpenSky API, dump1090), blends the data using priority-based merging, and provides API endpoints for real-time aircraft tracking.

## Architecture

- **Backend**: FastAPI application with async data collectors
- **Data Store**: Redis for caching and data blending
- **Data Sources**: Pi Station Network + OpenSky API + dump1090 ADS-B receivers
- **Deployment**: Docker + Docker Compose, Digital Ocean

## Features

- **Real-time flight tracking** for configured regions
- **Multi-source data blending** with priority (Pi stations > dump1090 > OpenSky)
- **Aircraft database enrichment** (registration, model, operator, manufacturer)
- **Helicopter identification** using ICAO aircraft classification
- **Pi Station Network** support for distributed ADS-B receivers
- **RESTful API** with automatic Swagger documentation
- **Rate limiting, security & caching**

## Quick Start

### Docker (recommended)
```bash
docker-compose up -d
# API at http://localhost:8000
# Docs at http://localhost:8000/docs
```

### Manual
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Requires Redis running on localhost:6379
python run.py --mode api --reload
```

## API Endpoints

- `GET /health` - Health check
- `GET /api/v1/status` - System status
- `GET /api/v1/regions` - Available regions
- `GET /api/v1/{region}/flights` - All flights (blended data)
- `GET /api/v1/{region}/choppers` - Helicopters only
- `POST /api/v1/aircraft/bulk` - Pi Station data submission
- `GET /docs` - Swagger API documentation

## Configuration

YAML config files in `config/`:
- `collectors.yaml` - Production
- `collectors-local.yaml` - Local development
- `collectors-dev.yaml` - Docker development

## Development

```bash
python run.py --mode api --reload   # API server with auto-reload
python run.py --mode cli            # Collector only (no web server)
python -m pytest                    # Run tests
python -m black .                   # Format code
```

## Production Deployment

```bash
docker-compose -f docker-compose.prod.yml up -d
```

Set env vars: `API_BASE_URL`, `ENV=production`, `FRONTEND_URL`
