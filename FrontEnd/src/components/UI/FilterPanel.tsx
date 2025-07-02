import React from 'react';
import { Plane, Shield, MapPin } from 'lucide-react';
import type { FlightFilters } from '../../services/types';

interface FilterPanelProps {
  filters: FlightFilters;
  onFiltersChange: (filters: FlightFilters) => void;
}

const FilterPanel: React.FC<FilterPanelProps> = ({ filters, onFiltersChange }) => {
  // Handle filter changes
  const updateFilter = <K extends keyof FlightFilters>(key: K, value: FlightFilters[K]) => {
    onFiltersChange({ ...filters, [key]: value });
  };

  return (
    <div className="p-4 space-y-4 bg-gray-50 dark:bg-gray-750">
      {/* Aircraft Type Filter */}
      <div className="space-y-2">
        <h4 className="text-sm font-medium text-gray-900 dark:text-gray-100">
          Aircraft Type
        </h4>
        <div className="flex gap-1 bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
          <button
            onClick={() => updateFilter('helicopters_only', false)}
            className={`flex-1 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
              !filters.helicopters_only
                ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-gray-100 shadow-sm'
                : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'
            }`}
          >
            All Aircraft
          </button>
          
          <button
            onClick={() => updateFilter('helicopters_only', true)}
            className={`flex-1 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
              filters.helicopters_only
                ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-gray-100 shadow-sm'
                : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'
            }`}
          >
            Helicopters Only
          </button>
        </div>
      </div>

      {/* Altitude filter */}
      <div className="space-y-2">
        <h4 className="text-sm font-medium text-gray-900 dark:text-gray-100">
          Altitude (feet)
        </h4>
        <div className="grid grid-cols-2 gap-2">
          <div>
            <label className="block text-xs text-gray-600 dark:text-gray-400 mb-1">
              Minimum
            </label>
            <input
              type="number"
              placeholder="0"
              value={filters.altitude_min || ''}
              onChange={(e) => updateFilter('altitude_min', e.target.value ? Number(e.target.value) : undefined)}
              className="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-600 dark:text-gray-400 mb-1">
              Maximum
            </label>
            <input
              type="number"
              placeholder="50000"
              value={filters.altitude_max || ''}
              onChange={(e) => updateFilter('altitude_max', e.target.value ? Number(e.target.value) : undefined)}
              className="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
            />
          </div>
        </div>
      </div>

      {/* Speed filter */}
      <div className="space-y-2">
        <h4 className="text-sm font-medium text-gray-900 dark:text-gray-100">
          Speed (knots)
        </h4>
        <div className="grid grid-cols-2 gap-2">
          <div>
            <label className="block text-xs text-gray-600 dark:text-gray-400 mb-1">
              Minimum
            </label>
            <input
              type="number"
              placeholder="0"
              value={filters.speed_min || ''}
              onChange={(e) => updateFilter('speed_min', e.target.value ? Number(e.target.value) : undefined)}
              className="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-600 dark:text-gray-400 mb-1">
              Maximum
            </label>
            <input
              type="number"
              placeholder="1000"
              value={filters.speed_max || ''}
              onChange={(e) => updateFilter('speed_max', e.target.value ? Number(e.target.value) : undefined)}
              className="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
            />
          </div>
        </div>
      </div>

      {/* Distance filter */}
      <div className="space-y-2">
        <h4 className="text-sm font-medium text-gray-900 dark:text-gray-100">
          Distance (miles)
        </h4>
        <div>
          <label className="block text-xs text-gray-600 dark:text-gray-400 mb-1">
            Maximum from center
          </label>
          <input
            type="number"
            placeholder="150"
            value={filters.distance_max || ''}
            onChange={(e) => updateFilter('distance_max', e.target.value ? Number(e.target.value) : undefined)}
            className="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
          />
        </div>
      </div>

      {/* Data source filter */}
      <div className="space-y-2">
        <h4 className="text-sm font-medium text-gray-900 dark:text-gray-100">
          Data Source
        </h4>
        <div className="space-y-1">
          {['dump1090', 'opensky', 'blended'].map((source) => (
            <label key={source} className="flex items-center space-x-2 text-sm">
              <input
                type="checkbox"
                checked={filters.data_source?.includes(source) || false}
                onChange={(e) => {
                  const current = filters.data_source || [];
                  const updated = e.target.checked
                    ? [...current, source]
                    : current.filter(s => s !== source);
                  updateFilter('data_source', updated);
                }}
                className="rounded border-gray-300 dark:border-gray-600 text-blue-600 focus:ring-blue-500"
              />
              <span className="text-gray-700 dark:text-gray-300 capitalize">
                {source}
              </span>
            </label>
          ))}
        </div>
      </div>
    </div>
  );
};

export default FilterPanel;