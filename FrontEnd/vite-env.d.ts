/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string
  readonly VITE_DEFAULT_REGION: string
  readonly VITE_REFRESH_INTERVAL: string
  readonly VITE_MAP_DEFAULT_ZOOM: string
  readonly VITE_MAP_CENTER_LAT: string
  readonly VITE_MAP_CENTER_LON: string
  readonly VITE_MAP_TILE_SERVER: string
  readonly VITE_ENABLE_FLIGHT_TRAILS: string
  readonly VITE_ENABLE_CLUSTERING: string
  readonly VITE_ENABLE_DARK_MODE: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}