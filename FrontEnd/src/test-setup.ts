import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

// Cleanup after each test
afterEach(() => {
  cleanup();
});

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(), // deprecated
    removeListener: vi.fn(), // deprecated
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

// Mock IntersectionObserver
global.IntersectionObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
}));

// Mock ResizeObserver
global.ResizeObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
}));

// Mock navigator.serviceWorker
Object.defineProperty(navigator, 'serviceWorker', {
  writable: true,
  value: {
    register: vi.fn(() => Promise.resolve({ scope: '/' })),
    ready: Promise.resolve({
      active: { postMessage: vi.fn() },
    }),
  },
});

// Mock Leaflet map methods
vi.mock('leaflet', () => ({
  map: vi.fn(() => ({
    setView: vi.fn(),
    addLayer: vi.fn(),
    removeLayer: vi.fn(),
    fitBounds: vi.fn(),
    getBounds: vi.fn(() => ({
      getSouthWest: vi.fn(() => ({ lat: 0, lng: 0 })),
      getNorthEast: vi.fn(() => ({ lat: 1, lng: 1 })),
    })),
    getZoom: vi.fn(() => 10),
    invalidateSize: vi.fn(),
    on: vi.fn(),
    off: vi.fn(),
  })),
  tileLayer: vi.fn(() => ({
    addTo: vi.fn(),
  })),
  marker: vi.fn(() => ({
    addTo: vi.fn(),
    setLatLng: vi.fn(),
    bindPopup: vi.fn(),
    on: vi.fn(),
  })),
  divIcon: vi.fn((options) => options),
  latLngBounds: vi.fn(),
  Canvas: vi.fn(),
  canvas: vi.fn(() => ({})),
}));