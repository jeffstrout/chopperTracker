# Raspberry Pi Aircraft Forwarder

This script forwards aircraft data from your local dump1090 instance to the Flight Tracker Collector API.

## Installation on Raspberry Pi

First, create a directory for the forwarder:
```bash
mkdir /home/pi/aircraft-forwarder
cd /home/pi/aircraft-forwarder
```

Then, download the script directly from GitHub:
```bash
# Download the script
wget https://raw.githubusercontent.com/jeffstrout/ChopperTracker/main/pi_forwarder/aircraft_forwarder.py

# Make it executable
chmod +x aircraft_forwarder.py

# Test it
python3 aircraft_forwarder.py --interval 5
```

## Configuration

Edit the configuration section at the top of the script:

```python
API_ENDPOINT = "https://api.choppertracker.com/api/v1/aircraft/bulk"
API_KEY = "etex.abc123def456ghi789jkl012"  # Your API key
STATION_ID = "ETEX01"  # Your unique station ID
STATION_NAME = "East Texas 01"  # Your station name
DUMP1090_URL = "http://localhost:8080/data/aircraft.json"  # Your dump1090 URL
```

## Usage

```bash
# Run continuously (default 30 second interval)
python3 aircraft_forwarder.py

# Run with custom interval (5 seconds)
python3 aircraft_forwarder.py --interval 5

# Run once and exit
python3 aircraft_forwarder.py --once

# Run with custom parameters
python3 aircraft_forwarder.py \
  --api-key "etex.your-actual-key" \
  --station-id "YOUR_ID" \
  --station-name "Your Station Name"
```

## Running as a Systemd Service

1. **Create the service file** on the Raspberry Pi:
```bash
sudo nano /etc/systemd/system/aircraft-forwarder.service
```

2. **Add the service configuration**:
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

3. **Enable and start the service**:
```bash
sudo systemctl daemon-reload
sudo systemctl enable aircraft-forwarder.service
sudo systemctl start aircraft-forwarder.service
```