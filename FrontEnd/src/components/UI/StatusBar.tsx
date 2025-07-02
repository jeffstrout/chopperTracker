import React from 'react';
import { 
  Clock, 
  Plane, 
  MapPin, 
  Activity,
  Wifi,
  WifiOff,
  AlertTriangle
} from 'lucide-react';
import type { Aircraft, SystemStatus } from '../../services/types';

interface StatusBarProps {
  aircraft: Aircraft[];
  totalAircraft: Aircraft[];
  lastUpdate: Date | null;
  isOnline: boolean;
  region: string;
  systemStatus?: SystemStatus | null;
}

const StatusBar: React.FC<StatusBarProps> = ({
  aircraft,
  totalAircraft,
  lastUpdate,
  isOnline,
  region,
  systemStatus,
}) => {
  // Format last update time
  const formatLastUpdate = (date: Date | null) => {
    if (!date) return 'Never';
    
    const now = new Date();
    const diff = Math.floor((now.getTime() - date.getTime()) / 1000);
    
    if (diff < 0) return '0s ago'; // Handle negative values
    if (diff < 60) return `${diff}s ago`;
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    return `${Math.floor(diff / 3600)}h ago`;
  };

  // Calculate statistics from total aircraft (unfiltered)
  const helicopterCount = totalAircraft.filter(ac => ac.icao_aircraft_class?.startsWith('H')).length;
  const stats = {
    visible: aircraft.length,
    total: totalAircraft.length,
    helicopters: helicopterCount,
    airplanes: totalAircraft.length - helicopterCount,
    onGround: 0, // Always 0 since ground aircraft are filtered out
    avgAltitude: aircraft.length > 0 
      ? Math.round(aircraft.reduce((sum, ac) => sum + (ac.alt_baro || 0), 0) / aircraft.length)
      : 0,
  };

  // Get connection status
  const getConnectionStatus = () => {
    if (!isOnline) {
      return { icon: WifiOff, color: 'text-red-500', text: 'Offline' };
    }
    
    if (systemStatus?.status === 'degraded') {
      return { icon: AlertTriangle, color: 'text-yellow-500', text: 'Degraded' };
    }
    
    return { icon: Wifi, color: 'text-green-500', text: 'Online' };
  };

  const connectionStatus = getConnectionStatus();
  const ConnectionIcon = connectionStatus.icon;

  return (
    <div className="bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 px-4 py-2">
      <div className="flex items-center justify-between text-sm">
        {/* Left section - Connection and update status */}
        <div className="flex items-center space-x-4">
          {/* Connection status */}
          <div className="flex items-center space-x-1">
            <ConnectionIcon className={connectionStatus.color} size={16} />
            <span className="text-gray-600 dark:text-gray-400">
              {connectionStatus.text}
            </span>
          </div>

          {/* Last update */}
          <div className="flex items-center space-x-1">
            <Clock className="text-gray-400" size={16} />
            <span className="text-gray-600 dark:text-gray-400">
              Updated: {formatLastUpdate(lastUpdate)}
            </span>
          </div>

          {/* Region */}
          <div className="flex items-center space-x-1">
            <MapPin className="text-gray-400" size={16} />
            <span className="text-gray-600 dark:text-gray-400">
              Region: {region.toUpperCase()}
            </span>
          </div>
        </div>

        {/* Center section - Aircraft statistics */}
        <div className="hidden md:flex items-center space-x-6">
          {/* Helicopters */}
          <div className="flex items-center space-x-1">
            <div className="w-3 h-3 bg-green-500 rounded-full" />
            <span className="text-gray-700 dark:text-gray-300 font-medium">
              {stats.helicopters}
            </span>
            <span className="text-gray-600 dark:text-gray-400">choppers</span>
          </div>

          {/* Airplanes */}
          <div className="flex items-center space-x-1">
            <Plane className="text-blue-500" size={16} />
            <span className="text-gray-700 dark:text-gray-300 font-medium">
              {stats.airplanes}
            </span>
            <span className="text-gray-600 dark:text-gray-400">airplanes</span>
          </div>

          {/* On ground */}
          {stats.onGround > 0 && (
            <div className="flex items-center space-x-1">
              <div className="w-3 h-3 bg-gray-500 rounded-full" />
              <span className="text-gray-700 dark:text-gray-300 font-medium">
                {stats.onGround}
              </span>
              <span className="text-gray-600 dark:text-gray-400">on ground</span>
            </div>
          )}
        </div>

        {/* Right section - System info */}
        <div className="flex items-center space-x-4">

          {/* API credits (if available) */}
          {systemStatus?.api_credits?.opensky_remaining && (
            <div className="hidden xl:flex items-center space-x-1">
              <span className="text-gray-600 dark:text-gray-400">
                Credits: 
              </span>
              <span className="font-mono text-gray-700 dark:text-gray-300">
                {systemStatus.api_credits.opensky_remaining}
              </span>
            </div>
          )}

          {/* Collectors status */}
          {systemStatus?.collectors && (
            <div className="hidden xl:flex items-center space-x-2">
              {Object.entries(systemStatus.collectors)
                .filter(([name, status]) => name !== 'message' && typeof status === 'object' && status.status)
                .map(([name, status]) => (
                <div key={name} className="flex items-center space-x-1">
                  <div 
                    className={`w-2 h-2 rounded-full ${
                      status.status === 'active' ? 'bg-green-500' :
                      status.status === 'error' ? 'bg-red-500' :
                      status.status === 'rate_limited' ? 'bg-yellow-500' :
                      'bg-gray-500'
                    }`}
                  />
                  <span className="text-xs text-gray-600 dark:text-gray-400 capitalize">
                    {name}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Mobile stats row */}
      <div className="md:hidden mt-2 flex items-center justify-between text-xs text-gray-600 dark:text-gray-400">
        <div className="flex items-center space-x-3">
          <span>{stats.helicopters} choppers</span>
          <span>{stats.total} total</span>
        </div>
      </div>
    </div>
  );
};

export default StatusBar;