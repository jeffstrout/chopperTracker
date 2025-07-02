import { useState, useEffect } from 'react';

interface VersionInfo {
  version: string;
  commit: string;
  branch: string;
  clean: boolean;
  buildTime: string;
  environment: string;
}

declare global {
  interface Window {
    FLIGHT_TRACKER_CONFIG?: {
      VERSION: VersionInfo;
    };
  }
}

export const useVersion = () => {
  const [version, setVersion] = useState<VersionInfo | null>(null);
  const [isNewVersion, setIsNewVersion] = useState(false);

  const fetchVersion = async () => {
    try {
      const response = await fetch(`/config.js?t=${Date.now()}`);
      const text = await response.text();

      // Safely execute the config.js by creating a script element
      const script = document.createElement('script');
      script.textContent = text;
      document.head.appendChild(script);
      document.head.removeChild(script);
      
      // Get version info from the loaded config
      const versionInfo = window.FLIGHT_TRACKER_CONFIG?.VERSION;
      if (versionInfo) {
        // Check if this is a new version
        const currentVersion = localStorage.getItem('app_version');
        if (currentVersion && currentVersion !== versionInfo.commit) {
          setIsNewVersion(true);
        }

        // Store current version
        localStorage.setItem('app_version', versionInfo.commit);
        setVersion(versionInfo);

        // Log to console
        console.log('🚀 App Version:', versionInfo);
      }
    } catch (error) {
      console.error('Failed to fetch version:', error);
      // Set a fallback version to prevent app crash
      setVersion({
        version: '1.0.1',
        commit: 'unknown',
        branch: 'main',
        clean: false,
        buildTime: new Date().toISOString(),
        environment: 'production'
      });
    }
  };

  useEffect(() => {
    fetchVersion();

    // Check for updates every 5 minutes
    const interval = setInterval(fetchVersion, 5 * 60 * 1000);
    return () => clearInterval(interval);
  }, []);

  return { version, isNewVersion, refreshApp: () => window.location.reload() };
};