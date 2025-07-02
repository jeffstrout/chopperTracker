import React from 'react';
import { 
  X, 
  Plane, 
  MapPin, 
  Clock
} from 'lucide-react';
import AircraftList from '../Aircraft/AircraftList';
import type { Aircraft, FlightFilters } from '../../services/types';

interface SidebarProps {
  isOpen: boolean;
  aircraft: Aircraft[];
  totalAircraft: Aircraft[];
  selectedAircraft?: string;
  onAircraftSelect: (hex?: string) => void;
  filters: FlightFilters;
  onFiltersChange: (filters: FlightFilters) => void;
  onClose: () => void;
}

const Sidebar: React.FC<SidebarProps> = ({
  isOpen,
  aircraft,
  totalAircraft,
  selectedAircraft,
  onAircraftSelect,
  filters,
  onFiltersChange,
  onClose,
}) => {

  // Calculate statistics from total aircraft (unfiltered)
  const helicopterCount = totalAircraft.filter(ac => ac.icao_aircraft_class?.startsWith('H')).length;
  const stats = {
    total: totalAircraft.length,
    helicopters: helicopterCount,
    airplanes: totalAircraft.length - helicopterCount,
    military: totalAircraft.filter(ac => ac.hex.toUpperCase().startsWith('AE')).length,
    onGround: totalAircraft.filter(ac => ac.on_ground).length,
  };

  return (
    <>
      {/* Overlay for mobile */}
      {isOpen && (
        <div 
          className="lg:hidden fixed inset-0 bg-black bg-opacity-50 sidebar-overlay"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <div className={`
        fixed lg:relative inset-y-0 left-0 w-80 max-w-[75vw] sm:max-w-[85vw] bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 transform transition-transform duration-300 ease-in-out flex flex-col sidebar-panel
        ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
      `}>
        {/* Header */}
        <div className="flex-shrink-0 p-4 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
              Live Flights
            </h2>
            <button
              onClick={onClose}
              className="lg:hidden btn btn-ghost p-1"
              aria-label="Close sidebar"
            >
              <X size={20} />
            </button>
          </div>


          {/* Filter buttons */}
          <div className="flex gap-1 bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
            <button
              onClick={() => onFiltersChange({ ...filters, helicopters_only: true })}
              className={`flex-1 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                filters.helicopters_only
                  ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-gray-100 shadow-sm'
                  : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'
              }`}
            >
              Choppers
            </button>
            
            <button
              onClick={() => onFiltersChange({ ...filters, helicopters_only: false })}
              className={`flex-1 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                !filters.helicopters_only
                  ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-gray-100 shadow-sm'
                  : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'
              }`}
            >
              Airplanes
            </button>
          </div>

          {/* Statistics */}
          <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
            <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-2">
              <div className="flex items-center space-x-1">
                <div className="w-3 h-3 bg-green-500 rounded-full" />
                <span className="text-gray-600 dark:text-gray-400">Choppers</span>
              </div>
              <div className="font-semibold text-gray-900 dark:text-gray-100">
                {stats.helicopters}
              </div>
            </div>
            
            <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-2">
              <div className="flex items-center space-x-1">
                <Plane size={14} className="text-blue-500" />
                <span className="text-gray-600 dark:text-gray-400">Airplanes</span>
              </div>
              <div className="font-semibold text-gray-900 dark:text-gray-100">
                {stats.airplanes}
              </div>
            </div>
          </div>
        </div>


        {/* Aircraft list */}
        <div className="flex-1 overflow-hidden relative">
          <AircraftList
            aircraft={aircraft}
            selectedAircraft={selectedAircraft}
            onAircraftSelect={onAircraftSelect}
          />
        </div>

        {/* Footer */}
        <div className="flex-shrink-0 p-3 border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-750">
          <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
            <div className="flex items-center space-x-1">
              <Clock size={12} />
              <span>Auto-refresh: 3s</span>
            </div>
            <div>
              Showing {aircraft.length} flights
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Sidebar;