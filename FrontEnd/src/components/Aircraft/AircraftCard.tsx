import React from 'react';
import { 
  Plane, 
  MapPin, 
  Clock, 
  Activity,
  Shield
} from 'lucide-react';
import type { Aircraft } from '../../services/types';

interface AircraftCardProps {
  aircraft: Aircraft;
  isSelected: boolean;
  onClick: () => void;
}

const AircraftCard: React.FC<AircraftCardProps> = ({ 
  aircraft, 
  isSelected, 
  onClick 
}) => {
  // Helper functions
  const isHelicopter = aircraft.icao_aircraft_class?.startsWith('H');
  const isMilitary = aircraft.hex.toUpperCase().startsWith('AE');
  
  const formatAltitude = (alt?: number) => {
    if (!alt) return 'N/A';
    return `${alt.toLocaleString()}ft`;
  };

  const formatSpeed = (speed?: number) => {
    if (!speed) return 'N/A';
    return `${Math.round(speed)}kts`;
  };

  const formatLastSeen = (seen: number) => {
    if (seen < 60) return `${Math.round(seen)}s`;
    if (seen < 3600) return `${Math.round(seen / 60)}m`;
    return `${Math.round(seen / 3600)}h`;
  };

  const getStatusColor = () => {
    if (aircraft.seen > 120) return 'text-red-500'; // Stale data
    if (aircraft.seen > 60) return 'text-yellow-500'; // Old data
    return 'text-green-500'; // Fresh data
  };

  const getAircraftIcon = () => {
    // Use Plane icon for all aircraft since Helicopter isn't available in lucide-react
    return Plane;
  };

  const AircraftIcon = getAircraftIcon();

  return (
    <div
      onClick={onClick}
      className={`
        cursor-pointer rounded-lg border p-3 transition-all duration-200 hover:shadow-md
        ${isSelected 
          ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 shadow-md' 
          : 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-gray-300 dark:hover:border-gray-600'
        }
      `}
    >
      {/* Header */}
      <div className="flex items-start justify-between mb-2">
        <div className="flex items-center space-x-2">
          <div className={`p-1 rounded ${
            isHelicopter ? 'bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-400' :
            isMilitary ? 'bg-red-100 text-red-600 dark:bg-red-900 dark:text-red-400' :
            'bg-blue-100 text-blue-600 dark:bg-blue-900 dark:text-blue-400'
          }`}>
            <AircraftIcon size={14} />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900 dark:text-gray-100 text-sm">
              {aircraft.flight || aircraft.hex.toUpperCase()}
            </h3>
            {aircraft.registration && (
              <p className="text-xs text-gray-600 dark:text-gray-400">
                {aircraft.registration}
              </p>
            )}
          </div>
        </div>
        
        {/* Status badges */}
        <div className="flex items-center space-x-1">
          {aircraft.on_ground && (
            <div className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300 text-xs px-2 py-0.5 rounded-full">
              Ground
            </div>
          )}
          {isMilitary && (
            <div className="bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300 text-xs px-2 py-0.5 rounded-full flex items-center space-x-1">
              <Shield size={10} />
              <span>Military</span>
            </div>
          )}
        </div>
      </div>

      {/* Aircraft details */}
      {aircraft.model && (
        <p className="text-sm text-gray-700 dark:text-gray-300 mb-2 truncate">
          {aircraft.model}
        </p>
      )}

      {aircraft.operator && (
        <p className="text-xs text-gray-600 dark:text-gray-400 mb-2 truncate">
          {aircraft.operator}
        </p>
      )}

      {/* Flight data grid */}
      <div className="grid grid-cols-2 gap-2 text-xs">
        <div className="flex items-center space-x-1">
          <Activity size={12} className="text-gray-400" />
          <span className="text-gray-600 dark:text-gray-400">Alt:</span>
          <span className="font-medium text-gray-900 dark:text-gray-100">
            {formatAltitude(aircraft.alt_baro)}
          </span>
        </div>
        
        <div className="flex items-center space-x-1">
          <Plane size={12} className="text-gray-400" />
          <span className="text-gray-600 dark:text-gray-400">Speed:</span>
          <span className="font-medium text-gray-900 dark:text-gray-100">
            {formatSpeed(aircraft.gs)}
          </span>
        </div>
        
        {aircraft.distance_miles && (
          <div className="flex items-center space-x-1">
            <MapPin size={12} className="text-gray-400" />
            <span className="text-gray-600 dark:text-gray-400">Dist:</span>
            <span className="font-medium text-gray-900 dark:text-gray-100">
              {aircraft.distance_miles.toFixed(1)}mi
            </span>
          </div>
        )}
        
        <div className="flex items-center space-x-1">
          <Clock size={12} className={getStatusColor()} />
          <span className="text-gray-600 dark:text-gray-400">Seen:</span>
          <span className={`font-medium ${getStatusColor()}`}>
            {formatLastSeen(aircraft.seen)}
          </span>
        </div>
      </div>

      {/* Data source indicator */}
      <div className="mt-2 flex items-center justify-between">
        <div className="flex items-center space-x-1">
          <div className={`w-2 h-2 rounded-full ${
            aircraft.data_source === 'dump1090' ? 'bg-green-500' :
            aircraft.data_source === 'opensky' ? 'bg-blue-500' :
            'bg-purple-500'
          }`} />
          <span className="text-xs text-gray-500 dark:text-gray-400 capitalize">
            {aircraft.data_source}
          </span>
        </div>
        
        {aircraft.squawk && aircraft.squawk !== '1200' && (
          <span className="text-xs font-mono bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 px-2 py-0.5 rounded">
            {aircraft.squawk}
          </span>
        )}
      </div>
    </div>
  );
};

export default AircraftCard;