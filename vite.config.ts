import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  server: {
    host: '192.168.1.5',
    port: 5173,
    https: process.env.NODE_ENV === 'development' && fs.existsSync(path.resolve(__dirname, 'certs/192.168.10.19.pem')) 
      ? {
          key: fs.readFileSync(path.resolve(__dirname, 'certs/192.168.10.19-key.pem')),
          cert: fs.readFileSync(path.resolve(__dirname, 'certs/192.168.10.19.pem'))
        }
      : undefined
  },
  plugins: [vue()],
  base: '/dedicatory/',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    target: 'esnext',
    minify: 'esbuild',
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: {
          vue: ['vue'],
        },
      },
    },
  },
  optimizeDeps: {
    include: ['vue']
  }
})