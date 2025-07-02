import React from 'react';
import AircraftCard from './AircraftCard';
import type { Aircraft } from '../../services/types';

interface AircraftListProps {
  aircraft: Aircraft[];
  selectedAircraft?: string;
  onAircraftSelect: (hex?: string) => void;
}

const AircraftList: React.FC<AircraftListProps> = ({
  aircraft,
  selectedAircraft,
  onAircraftSelect,
}) => {
  if (aircraft.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="text-center">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-100 dark:bg-gray-700 rounded-full flex items-center justify-center">
            <svg
              className="w-8 h-8 text-gray-400 dark:text-gray-500"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M5 15l7-7 7 7"
              />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
            No aircraft found
          </h3>
          <p className="text-gray-600 dark:text-gray-400 text-sm max-w-sm">
            No aircraft match your current filters. Try adjusting your search or clearing filters.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="absolute inset-0 overflow-y-auto custom-scrollbar">
      <div className="p-3 space-y-2">
        {aircraft.map((ac) => (
          <AircraftCard
            key={ac.hex}
            aircraft={ac}
            isSelected={selectedAircraft === ac.hex}
            onClick={() => onAircraftSelect(ac.hex)}
          />
        ))}
      </div>
    </div>
  );
};

export default AircraftList;