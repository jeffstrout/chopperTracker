# Flight Tracker Web UI (Chopper Tracker)

A responsive web interface for visualizing real-time flight data collected by the Flight Tracker Collector service. Built with React, TypeScript, and Leaflet for interactive mapping with advanced filtering and real-time updates. Now featuring helicopter-first design with enhanced map controls.

## 🚀 Production Deployment

**Live Application**: http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com  
**Backend API**: https://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com

## ✨ Features

🗺️ **Interactive Map** - OpenStreetMap-based flight visualization with custom aircraft markers  
🔄 **Real-time Updates** - Auto-refreshing flight data every 3 seconds  
📱 **Responsive Design** - Seamless experience on desktop, tablet, and mobile devices  
🚁 **Helicopter-First** - Default view shows helicopters with easy toggle for all aircraft  
🔍 **Flight Search** - Search and filter flights by callsign, registration, and more  
📊 **Unified Statistics** - Total aircraft counts always visible regardless of active filter  
⚙️ **Enhanced Settings** - Version info and app settings accessible via gear icon  
🌙 **Auto Dark Mode** - Follows system theme preferences  
📍 **Fit All Button** - New map control to show all aircraft in region at once  

## 🛠️ Technology Stack

- **Frontend**: React 18 + TypeScript + Vite
- **Mapping**: Leaflet.js with OpenStreetMap tiles  
- **Styling**: Tailwind CSS for responsive design
- **HTTP Client**: Axios for API communication
- **State Management**: React Context + useReducer
- **Icons**: Lucide React for consistent iconography
- **Deployment**: AWS S3 + CloudFront with GitHub Actions CI/CD

## 🏗️ AWS Infrastructure

### Production Architecture
- **Frontend**: S3 static website hosting + CloudFront CDN
- **Backend**: ECS Fargate with Application Load Balancer
- **Cache**: ElastiCache Redis for performance
- **Cost Optimization**: Fargate Spot instances, scheduled start/stop (7AM-11PM)
- **Monitoring**: AWS Budgets with alerts at $50/month

### Deployment Pipeline
- **GitHub Actions**: Automatic deployment on main branch push
- **Environment**: Production environment variables managed via GitHub Secrets
- **Caching**: CloudFront cache invalidation on deployments

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Running Flight Tracker Collector service

### Installation

```bash
# Clone the repository
git clone https://github.com/jeffstrout/flightTrackerWebUI.git
cd flightTrackerWebUI

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Configure your API endpoint
# Edit .env and set VITE_API_BASE_URL to your collector service URL
```

### Development

```bash
# Start development server
npm run dev

# Run type checking
npm run type-check

# Run linting
npm run lint
```

Visit `http://localhost:5173` to view the application.

### Production Build

```bash
# Build for production
npm run build

# Preview production build
npm run preview
```

## ⚙️ Configuration

The application uses environment variables for configuration:

### Required Settings

```bash
# API Configuration
VITE_API_BASE_URL=https://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com
VITE_DEFAULT_REGION=etex                 # Default region to load
```

### Optional Settings

```bash
# Map Configuration
VITE_MAP_DEFAULT_ZOOM=8                  # Initial zoom level
VITE_MAP_CENTER_LAT=32.3513             # Default center latitude
VITE_MAP_CENTER_LON=-95.3011            # Default center longitude

# Update Configuration  
VITE_REFRESH_INTERVAL=15000             # Default auto-refresh interval (ms)

# Feature Flags
VITE_ENABLE_FLIGHT_TRAILS=true          # Show aircraft trails
VITE_ENABLE_CLUSTERING=true             # Cluster aircraft markers
VITE_ENABLE_DARK_MODE=true             # Auto dark mode support
```

## 🔗 API Integration

This web UI connects to the Flight Tracker Collector service endpoints:

### Primary Endpoints
- `GET /api/v1/{region}/flights` - All flights for region (airborne only)
- `GET /api/v1/{region}/choppers` - Helicopters only  
- `GET /api/v1/regions` - Available regions
- `GET /api/v1/status` - System health status

### Expected Data Format

```typescript
interface Aircraft {
  hex: string;              // ICAO24 hex code
  flight?: string;          // Callsign/flight number
  lat: number;              // Latitude
  lon: number;              // Longitude
  alt_baro?: number;        // Barometric altitude (feet)
  gs?: number;              // Ground speed (knots)
  track?: number;           // True track (degrees)
  on_ground: boolean;       // Ground status (automatically filtered out)
  seen: number;             // Seconds since last update
  data_source: string;      // opensky/dump1090/blended
  // ... additional metadata fields
}
```

## 📁 Architecture

### Component Structure

```
src/
├── components/
│   ├── Map/
│   │   ├── FlightMap.tsx          # Main map container with fit-all control
│   │   └── AircraftMarker.tsx     # Aircraft markers
│   ├── UI/
│   │   ├── Header.tsx             # App header with settings and version info
│   │   ├── Sidebar.tsx            # Flight list sidebar with helicopter toggle
│   │   └── StatusBar.tsx          # Optimized status display
│   └── Aircraft/
│       ├── AircraftList.tsx       # Scrollable flight list
│       └── AircraftCard.tsx       # Individual flight cards
├── hooks/
│   ├── useFlightData.ts           # Flight data management
│   └── useFilters.ts              # Filter state with ground aircraft exclusion
├── services/
│   ├── api.ts                     # Production API client
│   └── types.ts                   # TypeScript definitions
└── styles/
    └── globals.css                # Global styles with dark mode
```

### Key Features & Optimizations

- **Ground Aircraft Filtering**: Automatically excludes aircraft on ground from all displays
- **Helicopter-First Design**: Default view shows helicopters with prominent toggle controls
- **Configurable Refresh**: User-selectable intervals from 5 seconds to 5 minutes via settings menu
- **Optimized Status Bar**: Clean display without average altitude or unnecessary messages
- **Interactive Map**: Click aircraft for detailed information with smooth position updates
- **Enhanced Map Controls**: New fit-all button to show all aircraft in region view
- **Responsive Sidebar**: Collapsible flight list with advanced search/filter capabilities
- **Unified Statistics**: Total aircraft and helicopter counts always show region totals
- **Performance Optimized**: Efficient rendering for hundreds of aircraft
- **Auto Dark Mode**: Follows system theme preferences automatically
- **Version Info**: Build version and commit hash available in settings menu

## 🚀 Deployment

### Production (Current)
- **URL**: http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com
- **CI/CD**: GitHub Actions automatic deployment
- **Infrastructure**: AWS S3 + ECS Fargate + ElastiCache Redis
- **Cost**: ~$42/month (optimized with Spot instances and scheduling)

### Alternative Hosting Options

- **Netlify**: Connect repository for automatic deployments
- **Vercel**: Import project and deploy with one click  
- **GitHub Pages**: Enable in repository settings

### Docker Deployment

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
```

## 🌐 Browser Support

- **Desktop**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Mobile**: iOS Safari 14+, Chrome Mobile 90+
- **Progressive Enhancement**: Core functionality works in older browsers

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🐛 Troubleshooting

### Common Issues

#### No Data Displayed
- Verify `VITE_API_BASE_URL` is correct and accessible
- Check browser console for API errors
- Ensure Flight Tracker Collector service is running
- Try changing refresh interval in settings menu

#### Map Not Loading
- Check internet connection for OpenStreetMap tiles
- Verify map center coordinates are valid
- Clear browser cache and hard refresh (Ctrl+Shift+R)

#### Settings Menu Not Visible
- Try hard refresh to clear browser cache
- Open in incognito/private window
- Ensure JavaScript is enabled

### Performance Issues
- Adjust refresh interval via settings menu (gear icon)
- Enable clustering for high aircraft density areas
- Check if your system meets browser requirements

## 📋 Management Commands

### AWS Service Management
```bash
# Start services (7AM daily via Lambda)
./scripts/manage-flight-tracker.sh start

# Stop services (11PM daily via Lambda)  
./scripts/manage-flight-tracker.sh stop

# Check service status
./scripts/manage-flight-tracker.sh status

# Check AWS costs
./scripts/check-aws-costs.sh
```

## 📄 License

MIT License - see LICENSE file for details

---

For detailed AWS deployment information, see [AWS_DEPLOYMENT_SUMMARY.md](./AWS_DEPLOYMENT_SUMMARY.md)