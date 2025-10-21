<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useSpotifyAuth } from './composables/useSpotifyAuth'
import './assets/css/index.css'

// Data de referência (19/11/2021 às 23:23)
const referenceDate = new Date('2021-11-19T23:23:00')

// Estados reativos para cada unidade de tempo
const years = ref(0)
const months = ref(0)
const days = ref(0)
const hours = ref(0)
const minutes = ref(0)
const seconds = ref(0)

let intervalId: NodeJS.Timeout | null = null

// Estados do slideshow
const currentSlide = ref(0)
const isAutoPlaying = ref(true)
let slideInterval: NodeJS.Timeout | null = null

// Array de fotos (você pode substituir por suas próprias imagens)
const photos = ref([
  {
    id: 1,
    src: './src/assets/foto1.jpg',
    alt: 'Foto 1',
  },
  {
    id: 2,
    src: './src/assets/foto2.jpeg',
    alt: 'Foto 2',
  },
  {
    id: 3,
    src: './src/assets/foto3.jpg',
    alt: 'Foto 3',
  },
])

// Funções do slideshow
const nextSlide = () => {
  currentSlide.value = (currentSlide.value + 1) % photos.value.length
}

const prevSlide = () => {
  currentSlide.value = currentSlide.value === 0 ? photos.value.length - 1 : currentSlide.value - 1
}

const goToSlide = (index: number) => {
  currentSlide.value = index
}

const toggleAutoPlay = () => {
  isAutoPlaying.value = !isAutoPlaying.value
  if (isAutoPlaying.value) {
    startAutoPlay()
  } else {
    stopAutoPlay()
  }
}

const startAutoPlay = () => {
  slideInterval = setInterval(nextSlide, 4000) // Muda a cada 4 segundos
}

const stopAutoPlay = () => {
  if (slideInterval) {
    clearInterval(slideInterval)
    slideInterval = null
  }
}

// ========== SPOTIFY WEB PLAYBACK API ==========

// INSTRUÇÕES PARA CONFIGURAÇÃO:
// 1. Vá para https://developer.spotify.com/dashboard
// 2. Crie um novo app
// 3. Configure o Redirect URI: http://localhost:5173
// 4. Copie o Client ID e cole abaixo
// 5. Para obter Access Token:
//    - Use uma ferramenta como Postman ou curl
//    - Endpoint: https://accounts.spotify.com/api/token
//    - Método: POST
//    - Headers: Authorization: Basic btoa(client_id:client_secret)
//    - Body: grant_type=client_credentials&scope=streaming user-read-email user-read-private
// 6. Cole o Access Token abaixo

// ========== SISTEMA DE AUTENTICAÇÃO COM RENOVAÇÃO AUTOMÁTICA ==========
const {
  initializeTokens,
  getValidToken,
  startAutoRefresh,
  spotifyApiRequest
} = useSpotifyAuth()

// Inicializar tokens ao carregar
initializeTokens()

// Estados do Spotify Player
const spotifyPlayer = ref<any>(null)
const isSpotifyReady = ref(false)
const isSpotifyConnected = ref(false)
const currentTrack = ref<any>(null)
const isPlaying = ref(false)
const isPaused = ref(false)
const deviceId = ref('')
const position = ref(0)
const duration = ref(0)
const volume = ref(0.3)
const autoPlayAttempts = ref(0)
const maxAutoPlayAttempts = 3
const isAttemptingAutoPlay = ref(false)

// Track URI da música que você quer tocar (configurável via .env.local)
const trackUri = import.meta.env.VITE_SPOTIFY_TRACK_URI || 'spotify:track:2o2xhyri4aJUtgMGkf5P0J' // Fallback para Lisboa - Anavitoria, Lenine

// Declarar tipos globais
declare global {
  interface Window {
    onSpotifyWebPlaybackSDKReady: () => void
    Spotify: any
  }
}

// Inicializar Spotify Web Playback SDK
const initSpotifyPlayer = () => {
  if (!window.Spotify) {
    console.error('Spotify SDK não carregado')
    return
  }

  const player = new window.Spotify.Player({
    name: 'Nossa Música Player ❤️',
    getOAuthToken: async (cb: (token: string) => void) => {
      const token = await getValidToken()
      if (token) {
        cb(token)
      } else {
        console.error('❌ Não foi possível obter token válido')
      }
    },
    volume: volume.value
  })

  // Event Listeners
  player.addListener('ready', ({ device_id }: { device_id: string }) => {
    console.log('Player pronto! Device ID:', device_id)
    deviceId.value = device_id
    isSpotifyReady.value = true
    isSpotifyConnected.value = true
    
    // Iniciar música automaticamente quando o player estiver pronto
    setTimeout(() => {
      attemptAutoPlay()
    }, 1500) // Delay um pouco maior para garantir inicialização completa
  })

  player.addListener('not_ready', ({ device_id }: { device_id: string }) => {
    console.log('Player não disponível:', device_id)
    isSpotifyReady.value = false
  })

  player.addListener('player_state_changed', (state: any) => {
    if (!state) {
      currentTrack.value = null
      isPlaying.value = false
      isPaused.value = false
      position.value = 0
      duration.value = 0
      return
    }

    currentTrack.value = state.track_window.current_track
    isPlaying.value = !state.paused
    isPaused.value = state.paused
    position.value = state.position
    duration.value = state.duration

    console.log('Estado mudou:', {
      track: currentTrack.value?.name,
      artist: currentTrack.value?.artists[0]?.name,
      playing: isPlaying.value
    })
  })

  // Error handling
  player.addListener('initialization_error', ({ message }: { message: string }) => {
    console.error('Erro de inicialização:', message)
  })

  player.addListener('authentication_error', ({ message }: { message: string }) => {
    console.error('Erro de autenticação:', message)
  })

  player.addListener('account_error', ({ message }: { message: string }) => {
    console.error('Erro de conta:', message)
  })

  player.addListener('playback_error', ({ message }: { message: string }) => {
    console.error('Erro de reprodução:', message)
  })

  // Conectar o player
  player.connect().then((success: boolean) => {
    if (success) {
      console.log('Conectado ao Spotify Web Playback SDK!')
      spotifyPlayer.value = player
    } else {
      console.error('Falha ao conectar com o Spotify')
    }
  })
}

// Funções de controle do player (com renovação automática)
const playMusic = async (isAutoPlay = false) => {
  if (!deviceId.value) {
    console.warn('⚠️ Device ID não disponível')
    if (isAutoPlay && autoPlayAttempts.value < maxAutoPlayAttempts) {
      setTimeout(() => attemptAutoPlay(), 2000)
    }
    return
  }

  if (isAutoPlay) {
    isAttemptingAutoPlay.value = true
  }

  try {
    const response = await spotifyApiRequest(`https://api.spotify.com/v1/me/player/play?device_id=${deviceId.value}`, {
      method: 'PUT',
      body: JSON.stringify({
        uris: [trackUri],
        position_ms: 0
      }),
      headers: {
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      throw new Error(`Erro HTTP: ${response.status}`)
    }

    console.log('🎵 Música iniciada!' + (isAutoPlay ? ' (Auto-play)' : ''))
    if (isAutoPlay) {
      isAttemptingAutoPlay.value = false
      autoPlayAttempts.value = 0 // Reset counter on success
    }
  } catch (error) {
    console.error('❌ Erro ao iniciar música:', error)
    
    if (isAutoPlay && autoPlayAttempts.value < maxAutoPlayAttempts) {
      setTimeout(() => attemptAutoPlay(), 3000)
    } else {
      isAttemptingAutoPlay.value = false
    }
  }
}

// Função específica para tentativas de auto-play
const attemptAutoPlay = () => {
  autoPlayAttempts.value++
  console.log(`🔄 Tentativa ${autoPlayAttempts.value}/${maxAutoPlayAttempts} de auto-play...`)
  playMusic(true)
}

// Adicionar listener para primeira interação do usuário
const handleFirstInteraction = () => {
  if (autoPlayAttempts.value >= maxAutoPlayAttempts && !currentTrack.value && isSpotifyReady.value) {
    console.log('👆 Primeira interação detectada, tentando tocar música...')
    playMusic(false)
    removeInteractionListeners()
  }
}

const removeInteractionListeners = () => {
  document.removeEventListener('click', handleFirstInteraction)
  document.removeEventListener('keydown', handleFirstInteraction)
  document.removeEventListener('touchstart', handleFirstInteraction)
}

const pauseMusic = async () => {
  if (!deviceId.value) {
    console.warn('⚠️ Device ID não disponível')
    return
  }

  try {
    await spotifyApiRequest(`https://api.spotify.com/v1/me/player/pause?device_id=${deviceId.value}`, {
      method: 'PUT'
    })
    console.log('Música pausada!')
  } catch (error) {
    console.error('Erro ao pausar música:', error)
  }
}

const togglePlayback = () => {
  if (isPlaying.value) {
    pauseMusic()
  } else {
    playMusic()
  }
}

const setVolume = async (newVolume: number) => {
  volume.value = newVolume
  
  if (spotifyPlayer.value) {
    await spotifyPlayer.value.setVolume(newVolume)
  }
}



// Formatar tempo em mm:ss
const formatTime = (ms: number) => {
  const minutes = Math.floor(ms / 60000)
  const seconds = Math.floor((ms % 60000) / 1000)
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}





// Callback para quando o SDK estiver pronto
window.onSpotifyWebPlaybackSDKReady = () => {
  initSpotifyPlayer()
}

// ========== FIM SPOTIFY ==========



// Função para calcular a diferença de tempo
const calculateTimeDifference = () => {
  const now = new Date()
  
  // Cálculo dos anos
  let yearDiff = now.getFullYear() - referenceDate.getFullYear()
  
  // Ajuste para meses
  let monthDiff = now.getMonth() - referenceDate.getMonth()
  if (monthDiff < 0) {
    yearDiff--
    monthDiff += 12
  }
  
  // Ajuste para dias
  let dayDiff = now.getDate() - referenceDate.getDate()
  if (dayDiff < 0) {
    monthDiff--
    if (monthDiff < 0) {
      yearDiff--
      monthDiff += 12
    }
    
    // Pega o último dia do mês anterior
    const lastMonth = new Date(now.getFullYear(), now.getMonth(), 0)
    dayDiff += lastMonth.getDate()
  }
  
  // Diferença total em milissegundos para calcular horas, minutos e segundos
  const tempDate = new Date(referenceDate.getFullYear() + yearDiff, referenceDate.getMonth() + monthDiff, referenceDate.getDate() + dayDiff)
  const timeDiff = now.getTime() - tempDate.getTime()
  
  const hourDiff = Math.floor(timeDiff / (1000 * 60 * 60))
  const minuteDiff = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60))
  const secondDiff = Math.floor((timeDiff % (1000 * 60)) / 1000)
  
  // Atualiza os valores reativos
  years.value = yearDiff
  months.value = monthDiff
  days.value = dayDiff
  hours.value = hourDiff
  minutes.value = minuteDiff
  seconds.value = secondDiff
}

// Inicia o contador quando o componente é montado
onMounted(() => {
  calculateTimeDifference() // Calcula imediatamente
  intervalId = setInterval(calculateTimeDifference, 1000) // Atualiza a cada segundo
  
  // Inicia o slideshow automático
  if (isAutoPlaying.value) {
    startAutoPlay()
  }

  // ========== SISTEMA DE RENOVAÇÃO AUTOMÁTICA ==========
  // Iniciar monitoramento automático de renovação
  const stopAutoRefresh = startAutoRefresh()
  
  // Guardar função de cleanup para usar no onUnmounted
  ;(window as any).__stopAutoRefresh = stopAutoRefresh

  // Carregar Spotify Web Playback SDK
  const script = document.createElement('script')
  script.src = 'https://sdk.scdn.co/spotify-player.js'
  script.async = true
  document.body.appendChild(script)

  // Adicionar listeners para primeira interação (para contornar auto-play policies)
  document.addEventListener('click', handleFirstInteraction)
  document.addEventListener('keydown', handleFirstInteraction)  
  document.addEventListener('touchstart', handleFirstInteraction)

  script.onload = () => {
    console.log('🎵 Spotify SDK carregado!')
  }

  script.onerror = () => {
    console.error('Erro ao carregar Spotify SDK')
  }
})

// Limpa os intervalos quando o componente é desmontado
onUnmounted(() => {
  if (intervalId) {
    clearInterval(intervalId)
  }
  stopAutoPlay()
  
  // Parar sistema de renovação automática
  if ((window as any).__stopAutoRefresh) {
    ;(window as any).__stopAutoRefresh()
    delete (window as any).__stopAutoRefresh
  }
  
  // Desconectar player do Spotify
  if (spotifyPlayer.value) {
    spotifyPlayer.value.disconnect()
  }
  
  // Remover listeners de interação
  removeInteractionListeners()
})
</script>

<template>
  <div class="container">
    <!-- ========== SPOTIFY PLAYER ========== -->
    <div class="spotify-player-section">
      <!-- Status de conexão -->
      <div v-if="!isSpotifyConnected" class="spotify-status">
        <div class="connecting">
          <p>Conectando ao Spotify...</p>
        </div>
      </div>

      <!-- Player ativo -->
      <div v-if="isSpotifyConnected">
        <!-- Informações da música -->
        <div v-if="currentTrack" class="track-info">
          <div class="track-image">
            <img 
              v-if="currentTrack.album?.images[0]" 
              :src="currentTrack.album.images[0].url" 
              :alt="currentTrack.name"
            />
            <div v-else class="placeholder-image">🎵</div>
          </div>
          <div style="color: white;">
            <div>
              <div class="track-name">{{ currentTrack.name }} - {{currentTrack.artists[0]?.name  }}</div>
            </div>

            <div class="playback-info">
              <span v-if="currentTrack" class="time">
                {{ formatTime(position) }} / {{ formatTime(duration) }}
              </span>
              <span v-else class="status">
                {{ isSpotifyReady ? 'Pronto para tocar' : 'Carregando...' }}
              </span>
            </div>

            <!-- Controle de volume -->
            <div class="volume-section">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="volume-icon">
                <polygon points="11,5 6,9 2,9 2,15 6,15 11,19" stroke="currentColor" stroke-width="2" fill="none"/>
                <path d="M19.07 4.93a10 10 0 0 1 0 14.14" stroke="currentColor" stroke-width="2"/>
                <path d="M15.54 8.46a5 5 0 0 1 0 7.07" stroke="currentColor" stroke-width="2"/>
              </svg>
              <input 
                type="range" 
                min="0" 
                max="1" 
                step="0.1" 
                :value="volume"
                @input="(event: Event) => setVolume(parseFloat((event.target as HTMLInputElement).value))"
                class="volume-slider"
              />
              <span class="volume-text">{{ Math.round(volume * 100) }}%</span>
            </div>
          </div>
          <!-- Controles de reprodução -->
          <div class="player-controls">
            <a 
              @click="togglePlayback" 
              class="play-pause-btn"
              :disabled="!isSpotifyReady"
              :title="isPlaying ? 'Pausar' : 'Tocar'"
            >
              <svg v-if="isPlaying" width="36" height="36" viewBox="0 0 24 24" fill="none">
                <rect x="6" y="4" width="4" height="16" fill="currentColor" rx="1"/>
                <rect x="14" y="4" width="4" height="16" fill="currentColor" rx="1"/>
              </svg>
              <svg v-else width="36" height="36" viewBox="0 0 24 24" fill="none">
                <polygon points="8,5 19,12 8,19" fill="currentColor"/>
              </svg>
            </a>
          </div>
        </div>

        <!-- Status quando música está carregando -->
        <div v-if="isSpotifyReady && !currentTrack" class="start-music">
          <div v-if="isAttemptingAutoPlay" class="loading-music">
            <p>Iniciando a música automaticamente...</p>
          </div>
        </div>
      </div>
    </div>
    <!-- ========== FIM SPOTIFY PLAYER ========== -->

    <div class="photo-slideshow">
      <div class="slideshow-container">
        <!-- Slides -->
        <div class="slides-wrapper" :style="{ transform: `translateX(-${currentSlide * 33.333}%)` }">
          <div 
            v-for="(photo, index) in photos" 
            :key="photo.id"
            class="slide"
            :class="{ active: index === currentSlide }"
          >
            <img :src="photo.src" :alt="photo.alt" class="slide-image" />
          </div>
        </div>

        <!-- Controles de navegação -->
        <a @click="prevSlide" class="nav-btn prev-btn" aria-label="Foto anterior">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M15 18L9 12L15 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </a>
        
        <a @click="nextSlide" class="nav-btn next-btn" aria-label="Próxima foto">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M9 18L15 12L9 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </a>

        <!-- Indicadores de posição -->
        <div class="slide-indicators">
          <a 
            v-for="(photo, index) in photos" 
            :key="`indicator-${photo.id}`"
            @click="goToSlide(index)"
            class="indicator"
            :class="{ active: index === currentSlide }"
            :aria-label="`Ir para foto ${index + 1}`"
          ></a>
        </div>

        <!-- Controle de autoplay -->
        <div class="autoplay-controls">
          <a @click="toggleAutoPlay" class="autoplay-btn" :aria-label="isAutoPlaying ? 'Pausar slideshow' : 'Iniciar slideshow'">
            <svg v-if="isAutoPlaying" width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="6" y="4" width="4" height="16" fill="currentColor"/>
              <rect x="14" y="4" width="4" height="16" fill="currentColor"/>
            </svg>
            <svg v-else width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <polygon points="5,3 19,12 5,21" fill="currentColor"/>
            </svg>
          </a>
        </div>
      </div>
    </div>    
    <div>
      <h1>Eu te amo há:</h1>
      <h2>{{ years }} anos, {{ months }} meses, {{ days }} dias, {{ hours }} horas, {{ minutes }} minutos e {{ seconds }} segundos</h2>
    </div>
  </div>
</template>

