import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig({
  server: {
    host: '192.168.10.19'
  },
  plugins: [vue()],
  base: process.env.NODE_ENV === 'production' ? '/dedicatory/' : '/',
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
})
