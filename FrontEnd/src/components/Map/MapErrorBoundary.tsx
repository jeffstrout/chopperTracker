import React from 'react';
import ErrorBoundary from '../ErrorBoundary';
import { MapPin, AlertTriangle } from 'lucide-react';

interface Props {
  children: React.ReactNode;
  onMapError?: (error: Error) => void;
}

const MapErrorFallback: React.FC = () => (
  <div className="h-full w-full flex items-center justify-center bg-gray-100 dark:bg-gray-800">
    <div className="text-center p-8">
      <div className="flex items-center justify-center w-16 h-16 mx-auto bg-orange-100 dark:bg-orange-900 rounded-full mb-4">
        <MapPin className="w-8 h-8 text-orange-600 dark:text-orange-400" />
      </div>
      <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
        Map Loading Error
      </h2>
      <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
        Unable to load the flight map. This might be due to network issues or browser compatibility.
      </p>
      <button
        onClick={() => window.location.reload()}
        className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        Reload Page
      </button>
    </div>
  </div>
);

const MapErrorBoundary: React.FC<Props> = ({ children, onMapError }) => {
  const handleError = (error: Error, errorInfo: React.ErrorInfo) => {
    // Log map-specific errors
    if (import.meta.env.DEV) {
      console.error('Map component error:', error);
      console.error('Component stack:', errorInfo.componentStack);
    }

    // Call custom error handler if provided
    if (onMapError) {
      onMapError(error);
    }
  };

  return (
    <ErrorBoundary
      fallback={<MapErrorFallback />}
      onError={handleError}
    >
      {children}
    </ErrorBoundary>
  );
};

export default MapErrorBoundary;