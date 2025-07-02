import { useState, useMemo, useCallback } from 'react';
import type { Aircraft, FlightFilters } from '../services/types';

interface UseFiltersReturn {
  filters: FlightFilters;
  filteredAircraft: Aircraft[];
  setFilters: (filters: FlightFilters) => void;
  clearFilters: () => void;
  filterStats: {
    total: number;
    filtered: number;
    helicopters: number;
    military: number;
    commercial: number;
  };
}

const defaultFilters: FlightFilters = {
  search: '',
  aircraft_type: [],
  altitude_min: undefined,
  altitude_max: undefined,
  speed_min: undefined,
  speed_max: undefined,
  distance_max: undefined,
  on_ground: undefined,
  data_source: [],
  helicopters_only: true,
  military_only: false,
};

export function useFilters(aircraft: Aircraft[]): UseFiltersReturn {
  const [filters, setFilters] = useState<FlightFilters>(defaultFilters);

  // Helper function to check if aircraft is helicopter
  const isHelicopter = useCallback((ac: Aircraft): boolean => {
    const isHeli = ac.icao_aircraft_class?.startsWith('H') || false;
    
    // Helicopter detection based on ICAO class
    
    return isHeli;
  }, []);

  // Helper function to check if aircraft is military
  const isMilitary = useCallback((ac: Aircraft): boolean => {
    // Military aircraft typically have hex codes starting with specific patterns
    // US Military: AE prefix, some others use specific ranges
    const hex = ac.hex.toUpperCase();
    return (
      hex.startsWith('AE') || // US Military
      hex.startsWith('43') || // Military (some regions)
      ac.operator?.toLowerCase().includes('air force') ||
      ac.operator?.toLowerCase().includes('navy') ||
      ac.operator?.toLowerCase().includes('army') ||
      ac.operator?.toLowerCase().includes('military') ||
      ac.registration?.startsWith('M-') || // Some military registrations
      false
    );
  }, []);

  // Helper function to check if aircraft is commercial
  const isCommercial = useCallback((ac: Aircraft): boolean => {
    return !isHelicopter(ac) && !isMilitary(ac) && (
      ac.operator !== undefined &&
      ac.operator !== '' &&
      !ac.operator.toLowerCase().includes('private')
    );
  }, [isHelicopter, isMilitary]);

  // Apply filters to aircraft list
  const filteredAircraft = useMemo(() => {
    const filtered = aircraft.filter((ac) => {
      // Always exclude aircraft on ground
      if (ac.on_ground) {
        return false;
      }

      // Search filter (callsign, registration, operator)
      if (filters.search && filters.search.trim()) {
        const searchTerm = filters.search.toLowerCase().trim();
        const matchesSearch = (
          ac.flight?.toLowerCase().includes(searchTerm) ||
          ac.registration?.toLowerCase().includes(searchTerm) ||
          ac.operator?.toLowerCase().includes(searchTerm) ||
          ac.hex.toLowerCase().includes(searchTerm) ||
          ac.model?.toLowerCase().includes(searchTerm)
        );
        if (!matchesSearch) return false;
      }

      // Aircraft type filter
      if (filters.aircraft_type && filters.aircraft_type.length > 0) {
        const hasMatchingType = filters.aircraft_type.some(type =>
          ac.model?.toLowerCase().includes(type.toLowerCase()) ||
          ac.aircraft_type?.toLowerCase().includes(type.toLowerCase()) ||
          ac.typecode?.toLowerCase().includes(type.toLowerCase())
        );
        if (!hasMatchingType) return false;
      }

      // Altitude filters
      if (filters.altitude_min && ac.alt_baro && ac.alt_baro < filters.altitude_min) {
        return false;
      }
      if (filters.altitude_max && ac.alt_baro && ac.alt_baro > filters.altitude_max) {
        return false;
      }

      // Speed filters
      if (filters.speed_min && ac.gs && ac.gs < filters.speed_min) {
        return false;
      }
      if (filters.speed_max && ac.gs && ac.gs > filters.speed_max) {
        return false;
      }

      // Distance filter
      if (filters.distance_max && ac.distance_miles && ac.distance_miles > filters.distance_max) {
        return false;
      }

      // Ground status filter
      if (filters.on_ground !== undefined && ac.on_ground !== filters.on_ground) {
        return false;
      }

      // Data source filter
      if (filters.data_source && filters.data_source.length > 0) {
        if (!filters.data_source.includes(ac.data_source)) {
          return false;
        }
      }

      // Helicopters only filter (true = choppers only, false = airplanes only)
      if (filters.helicopters_only && !isHelicopter(ac)) {
        return false;
      }
      if (!filters.helicopters_only && isHelicopter(ac)) {
        return false;
      }

      // Military only filter
      if (filters.military_only && !isMilitary(ac)) {
        return false;
      }

      return true;
    });

    // Sort by distance from region center (closest first)
    // Aircraft with distance_miles come first, then those without (sorted by seen time)
    return filtered.sort((a, b) => {
      // Both have distance, sort by distance
      if (a.distance_miles !== undefined && b.distance_miles !== undefined) {
        return a.distance_miles - b.distance_miles;
      }
      
      // Only a has distance, it comes first
      if (a.distance_miles !== undefined && b.distance_miles === undefined) {
        return -1;
      }
      
      // Only b has distance, it comes first
      if (a.distance_miles === undefined && b.distance_miles !== undefined) {
        return 1;
      }
      
      // Neither has distance, sort by last seen (most recent first)
      return a.seen - b.seen;
    });
  }, [aircraft, filters, isHelicopter, isMilitary]);

  // Calculate filter statistics
  const filterStats = useMemo(() => {
    const helicopterCount = aircraft.filter(isHelicopter).length;
    const militaryCount = aircraft.filter(isMilitary).length;
    const commercialCount = aircraft.filter(isCommercial).length;

    // Count unique ICAO aircraft classes for statistics
    const icaoClasses = new Set(aircraft.map(ac => ac.icao_aircraft_class).filter(Boolean));

    return {
      total: aircraft.length,
      filtered: filteredAircraft.length,
      helicopters: helicopterCount,
      military: militaryCount,
      commercial: commercialCount,
    };
  }, [aircraft, filteredAircraft, isHelicopter, isMilitary, isCommercial]);

  // Update filters function
  const updateFilters = useCallback((newFilters: FlightFilters) => {
    setFilters(newFilters);
  }, []);

  // Clear all filters
  const clearFilters = useCallback(() => {
    setFilters(defaultFilters);
  }, []);

  return {
    filters,
    filteredAircraft,
    setFilters: updateFilters,
    clearFilters,
    filterStats,
  };
}