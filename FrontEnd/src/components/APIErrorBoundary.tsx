import React, { useState, useEffect } from 'react';
import { WifiOff, RefreshCw, AlertCircle } from 'lucide-react';
import flightAPI from '../services/api';

interface Props {
  children: React.ReactNode;
  onConnectionRestored?: () => void;
}

const APIErrorBoundary: React.FC<Props> = ({ children, onConnectionRestored }) => {
  const [isOffline, setIsOffline] = useState(false);
  const [isAPIDown, setIsAPIDown] = useState(false);
  const [retryCount, setRetryCount] = useState(0);
  const [isRetrying, setIsRetrying] = useState(false);

  // Check online status
  useEffect(() => {
    const updateOnlineStatus = () => {
      setIsOffline(!navigator.onLine);
    };

    window.addEventListener('online', updateOnlineStatus);
    window.addEventListener('offline', updateOnlineStatus);

    // Initial check
    updateOnlineStatus();

    return () => {
      window.removeEventListener('online', updateOnlineStatus);
      window.removeEventListener('offline', updateOnlineStatus);
    };
  }, []);

  // Check API health periodically when offline or API is down
  useEffect(() => {
    if (!isOffline && !isAPIDown) return;

    const checkAPIHealth = async () => {
      try {
        await flightAPI.checkConnection();
        setIsAPIDown(false);
        setRetryCount(0);
        if (onConnectionRestored) {
          onConnectionRestored();
        }
      } catch {
        setIsAPIDown(true);
      }
    };

    const interval = setInterval(checkAPIHealth, 5000); // Check every 5 seconds
    return () => clearInterval(interval);
  }, [isOffline, isAPIDown, onConnectionRestored]);

  const handleRetry = async () => {
    setIsRetrying(true);
    setRetryCount(prev => prev + 1);

    try {
      const isConnected = await flightAPI.checkConnection();
      if (isConnected) {
        setIsAPIDown(false);
        setIsOffline(false);
        setRetryCount(0);
        if (onConnectionRestored) {
          onConnectionRestored();
        }
      } else {
        setIsAPIDown(true);
      }
    } catch {
      setIsAPIDown(true);
    } finally {
      setIsRetrying(false);
    }
  };

  if (isOffline || isAPIDown) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 p-4">
        <div className="max-w-md w-full bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
          <div className="flex items-center justify-center w-12 h-12 mx-auto bg-yellow-100 dark:bg-yellow-900 rounded-full">
            {isOffline ? (
              <WifiOff className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
            ) : (
              <AlertCircle className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
            )}
          </div>

          <h1 className="mt-4 text-xl font-semibold text-center text-gray-900 dark:text-white">
            {isOffline ? 'No Internet Connection' : 'Cannot Connect to Flight Tracker'}
          </h1>

          <p className="mt-2 text-sm text-center text-gray-600 dark:text-gray-400">
            {isOffline
              ? 'Please check your internet connection and try again.'
              : 'The flight tracking service is currently unavailable. We\'ll automatically retry the connection.'}
          </p>

          {retryCount > 0 && (
            <p className="mt-2 text-xs text-center text-gray-500 dark:text-gray-400">
              Retry attempt: {retryCount}
            </p>
          )}

          <div className="mt-6">
            <button
              onClick={handleRetry}
              disabled={isRetrying}
              className="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isRetrying ? (
                <>
                  <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                  Retrying...
                </>
              ) : (
                <>
                  <RefreshCw className="w-4 h-4 mr-2" />
                  Retry Connection
                </>
              )}
            </button>
          </div>

          <div className="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-md">
            <p className="text-xs text-blue-800 dark:text-blue-200">
              <strong>Tip:</strong> The application will automatically attempt to reconnect every 5 seconds.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
};

export default APIErrorBoundary;