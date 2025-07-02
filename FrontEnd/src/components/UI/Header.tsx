import React, { useState, useEffect } from 'react';
import { 
  Plane, 
  Menu, 
  Moon, 
  Sun, 
  Settings, 
  Wifi, 
  WifiOff,
  AlertTriangle,
  CheckCircle
} from 'lucide-react';
import flightAPI from '../../services/api';
import type { SystemStatus } from '../../services/types';
import { useVersion } from '../../hooks/useVersion';

interface HeaderProps {
  region: string;
  onRegionChange: (region: string) => void;
  onToggleSidebar: () => void;
  systemStatus?: SystemStatus | null;
}

const Header: React.FC<HeaderProps> = ({
  region,
  onRegionChange,
  onToggleSidebar,
  systemStatus,
}) => {
  const [regions, setRegions] = useState<string[]>(['etex']); // Default regions
  const [showSettings, setShowSettings] = useState(false);
  const { version } = useVersion();

  // Load available regions from API
  useEffect(() => {
    const loadRegions = async () => {
      try {
        const regionsData = await flightAPI.getRegions();
        if (regionsData.regions && regionsData.regions.length > 0) {
          // Map region names to identifiers used by the app
          const regionIds = regionsData.regions.map(r => {
            const name = r.name?.toLowerCase() || '';
            if (name.includes('texas') || name.includes('etex')) return 'etex';
            if (name.includes('california') || name.includes('socal')) return 'socal';
            if (name.includes('norcal')) return 'norcal';
            // Default to a simplified version of the name
            return name.replace(/\s+/g, '').toLowerCase() || 'unknown';
          }).filter(id => id !== 'unknown');
          
          setRegions(regionIds.length > 0 ? regionIds : ['etex']);
        }
      } catch (error) {
        console.warn('Failed to load regions from API, using defaults:', error);
        setRegions(['etex']); // Only use etex as fallback since that's what the API supports
      }
    };
    
    loadRegions();
  }, []);

  // Get status indicator
  const getStatusInfo = () => {
    if (!systemStatus) {
      return { color: 'text-gray-500', icon: WifiOff, text: 'Connecting...' };
    }

    switch (systemStatus.status) {
      case 'healthy':
        return { color: 'text-green-500', icon: CheckCircle, text: 'Online' };
      case 'degraded':
        return { color: 'text-yellow-500', icon: AlertTriangle, text: 'Degraded' };
      case 'offline':
        return { color: 'text-red-500', icon: WifiOff, text: 'Offline' };
      default:
        return { color: 'text-gray-500', icon: Wifi, text: 'Unknown' };
    }
  };

  const statusInfo = getStatusInfo();
  const StatusIcon = statusInfo.icon;

  return (
    <header className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 shadow-sm">
      <div className="px-4 py-3">
        <div className="flex items-center justify-between">
          {/* Left section */}
          <div className="flex items-center space-x-4">
            {/* Mobile menu button */}
            <button
              onClick={onToggleSidebar}
              className="lg:hidden btn btn-ghost p-2"
              aria-label="Toggle menu"
            >
              <Menu size={20} />
            </button>

            {/* Logo and title */}
            <div className="flex items-center space-x-3">
              <div className="bg-green-100 dark:bg-green-900 p-2 rounded-lg">
                <Plane className="text-green-600 dark:text-green-400" size={24} />
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900 dark:text-gray-100">
                  Chopper Tracker
                </h1>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Live Aircraft Dashboard
                </p>
              </div>
            </div>
          </div>

          {/* Center section - Region selector */}
          <div className="hidden md:flex items-center space-x-3">
            <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
              Region:
            </label>
            <select
              value={region}
              onChange={(e) => onRegionChange(e.target.value)}
              className="bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-1 text-sm font-medium text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {regions.map((r) => (
                <option key={r} value={r}>
                  {r.toUpperCase()}
                </option>
              ))}
            </select>
          </div>

          {/* Right section */}
          <div className="flex items-center space-x-3">
            {/* Status indicator */}
            <div className="hidden sm:flex items-center space-x-2 text-sm">
              <StatusIcon className={`${statusInfo.color}`} size={16} />
              <span className="text-gray-700 dark:text-gray-300">
                {statusInfo.text}
              </span>
            </div>

            {/* API credits (if available) */}
            {systemStatus?.api_credits?.opensky_remaining && (
              <div className="hidden md:flex items-center space-x-1 text-sm text-gray-600 dark:text-gray-400">
                <span>Credits:</span>
                <span className="font-mono font-medium">
                  {systemStatus.api_credits.opensky_remaining}
                </span>
              </div>
            )}


            {/* Settings */}
            <div className="relative">
              <button
                onClick={() => setShowSettings(!showSettings)}
                className="btn btn-ghost p-2"
                aria-label="Settings"
              >
                <Settings size={18} />
              </button>

              {/* Settings dropdown */}
              {showSettings && (
                <div>
                  {/* Close overlay when clicking outside */}
                  <div 
                    className="fixed inset-0 z-[9000]" 
                    onClick={() => setShowSettings(false)}
                  />
                  
                  <div className="absolute right-0 top-full mt-2 w-64 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-[9001]">
                    <div className="p-4 space-y-3">
                      <h3 className="font-medium text-gray-900 dark:text-gray-100">
                        Settings
                      </h3>
                      
                      {/* Mobile region selector */}
                      <div className="md:hidden">
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                          Region
                        </label>
                        <select
                          value={region || 'etex'}
                          onChange={(e) => onRegionChange(e.target.value)}
                          className="w-full bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded px-3 py-2 text-sm"
                        >
                          {(regions && regions.length > 0 ? regions : ['etex']).map((r) => (
                            <option key={r} value={r}>
                              {r.toUpperCase()}
                            </option>
                          ))}
                        </select>
                      </div>

                      {/* System info */}
                      <div className="space-y-2 text-sm">
                        <div className="flex justify-between">
                          <span className="text-gray-600 dark:text-gray-400">Status:</span>
                          <span className="font-medium text-green-500">
                            Online
                          </span>
                        </div>
                        
                        <div className="flex justify-between">
                          <span className="text-gray-600 dark:text-gray-400">Refresh:</span>
                          <span className="text-xs">3s</span>
                        </div>
                        
                        {/* Version info */}
                        {version && (
                          <div className="pt-2 border-t border-gray-200 dark:border-gray-700">
                            <div className="flex justify-between">
                              <span className="text-gray-600 dark:text-gray-400">Version:</span>
                              <span className="text-xs font-mono">
                                v{version.version}
                              </span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-600 dark:text-gray-400">Build:</span>
                              <span className="text-xs font-mono">
                                {version.commit.substring(0, 7)}
                              </span>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;