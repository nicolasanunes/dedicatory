/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SPOTIFY_CLIENT_ID: string
  readonly VITE_SPOTIFY_CLIENT_SECRET: string
  readonly VITE_SPOTIFY_ACCESS_TOKEN: string
  readonly VITE_SPOTIFY_REFRESH_TOKEN: string
  readonly VITE_SPOTIFY_TRACK_URI: string
  // more env variables...
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}