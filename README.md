# ChopperTracker

Real-time helicopter and aircraft tracking system with a helicopter-first web interface, Python backend, and distributed ADS-B data collection via Raspberry Pi stations.

## Quick Start (Local Development)

### Backend
```bash
cd BackEnd
docker-compose up
```
This starts the FastAPI backend + Redis on `http://localhost:8000`.

### Frontend
```bash
cd FrontEnd
npm install
npm run dev
```
Opens the web UI on `http://localhost:5173`, connecting to the local backend.

### Pi Forwarder
Runs on a Raspberry Pi with an ADS-B receiver and dump1090. See `pi_forwarder/` for setup.

## Architecture

```
Raspberry Pi (ADS-B) --> Backend API --> Redis --> Frontend Map
     dump1090              FastAPI       Cache     React + Leaflet
```

**Data sources**: Local dump1090, OpenSky Network, Pi station forwarders

## Project Structure

```
ChopperTracker/
  BackEnd/         Python FastAPI backend + Redis
  FrontEnd/        React + Vite + TypeScript web UI
  pi_forwarder/    Raspberry Pi ADS-B data forwarder
```

## Deployment

- **Local dev**: docker-compose (BackEnd) + npm run dev (FrontEnd)
- **Production**: Digital Ocean with Docker

See `BackEnd/docker-compose.prod.yml` for production Docker configuration.
