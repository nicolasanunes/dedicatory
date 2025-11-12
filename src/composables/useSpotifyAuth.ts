import { ref, computed, readonly } from 'vue'

interface TokenResponse {
  access_token: string
  refresh_token?: string
  expires_in: number
  token_type: string
}

interface SpotifyAuthState {
  accessToken: string
  refreshToken: string
  expiresAt: number
  isAuthenticated: boolean
}

export const useSpotifyAuth = () => {
  // Estados reativos
  const accessToken = ref('')
  const refreshToken = ref('')
  const expiresAt = ref(0)
  const isRefreshing = ref(false)
  const lastRefreshError = ref<string | null>(null)
  
  // Configurações do Spotify
  const clientId = import.meta.env.VITE_SPOTIFY_CLIENT_ID
  const clientSecret = import.meta.env.VITE_SPOTIFY_CLIENT_SECRET
  const initialToken = import.meta.env.VITE_SPOTIFY_ACCESS_TOKEN
  const initialRefreshToken = import.meta.env.VITE_SPOTIFY_REFRESH_TOKEN

  console.log('🔑 Configurações do Spotify carregadas:', {
    clientId,
    clientSecret,
    initialToken,
    initialRefreshToken
  })

  // Computed properties
  const isAuthenticated = computed(() => !!accessToken.value)
  const isTokenExpired = computed(() => Date.now() >= expiresAt.value)
  const timeUntilExpiry = computed(() => Math.max(0, expiresAt.value - Date.now()))
  const minutesUntilExpiry = computed(() => Math.floor(timeUntilExpiry.value / (1000 * 60)))

  // Carregar tokens salvos do localStorage
  const loadSavedTokens = () => {
    try {
      const savedState = localStorage.getItem('spotify_auth_state')
      if (savedState) {
        const state: SpotifyAuthState = JSON.parse(savedState)
        accessToken.value = state.accessToken
        refreshToken.value = state.refreshToken
        expiresAt.value = state.expiresAt
        console.log('✅ Tokens carregados do localStorage')
        return true
      }
    } catch (error) {
      console.warn('⚠️ Erro ao carregar tokens salvos:', error)
    }
    return false
  }

  // Salvar tokens no localStorage
  const saveTokens = () => {
    try {
      const state: SpotifyAuthState = {
        accessToken: accessToken.value,
        refreshToken: refreshToken.value,
        expiresAt: expiresAt.value,
        isAuthenticated: true
      }
      localStorage.setItem('spotify_auth_state', JSON.stringify(state))
      console.log('💾 Tokens salvos no localStorage')
    } catch (error) {
      console.error('❌ Erro ao salvar tokens:', error)
    }
  }

  // Inicializar com token do .env se não houver tokens salvos
  const initializeTokens = () => {
    // Tentar carregar tokens salvos primeiro
    if (loadSavedTokens()) {
      // Verificar se o token salvo ainda é válido
      if (isTokenExpired.value) {
        console.log('⚠️ Token salvo expirado, tentando renovar...')
        refreshAccessToken()
      }
      return
    }

    // Se não houver tokens salvos, usar do .env
    if (initialToken) {
      accessToken.value = initialToken
      refreshToken.value = initialRefreshToken || ''
      // Token do .env expira em 1 hora (assumindo que foi gerado recentemente)
      expiresAt.value = Date.now() + (50 * 60 * 1000) // 50 minutos para ser seguro
      saveTokens()
      console.log('🔑 Tokens inicializados do .env.local')
    }
  }

  // Renovar access token usando refresh token
  const refreshAccessToken = async (): Promise<boolean> => {
    if (!refreshToken.value || !clientId || !clientSecret) {
      console.warn('⚠️ Refresh token ou credenciais não disponíveis')
      return false
    }

    if (isRefreshing.value) {
      console.log('🔄 Renovação já em andamento...')
      return false
    }

    isRefreshing.value = true
    lastRefreshError.value = null

    try {
      console.log('🔄 Renovando access token...')

      const response = await fetch('https://accounts.spotify.com/api/token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': `Basic ${btoa(clientId + ':' + clientSecret)}`
        },
        body: new URLSearchParams({
          grant_type: 'refresh_token',
          refresh_token: refreshToken.value
        })
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const data: TokenResponse = await response.json()

      // Atualizar tokens
      accessToken.value = data.access_token
      if (data.refresh_token) {
        refreshToken.value = data.refresh_token
      }
      expiresAt.value = Date.now() + (data.expires_in * 1000)

      saveTokens()
      
      console.log('✅ Token renovado com sucesso! Válido até:', new Date(expiresAt.value))
      return true

    } catch (error) {
      console.error('❌ Erro ao renovar token:', error)
      lastRefreshError.value = error instanceof Error ? error.message : 'Erro desconhecido'
      return false
    } finally {
      isRefreshing.value = false
    }
  }

  // Obter token válido (renova automaticamente se necessário)
  const getValidToken = async (): Promise<string | null> => {
    // Se token atual é válido, retornar ele
    if (accessToken.value && !isTokenExpired.value) {
      return accessToken.value
    }

    console.log('🔄 Token expirado, tentando renovar...')

    // Tentar renovar token
    const success = await refreshAccessToken()
    if (success) {
      return accessToken.value
    }

    // Se falhou, limpar tokens inválidos
    clearTokens()
    console.error('❌ Não foi possível renovar o token. Login necessário.')
    return null
  }

  // Limpar todos os tokens
  const clearTokens = () => {
    accessToken.value = ''
    refreshToken.value = ''
    expiresAt.value = 0
    localStorage.removeItem('spotify_auth_state')
    console.log('🗑️ Tokens limpos')
  }

  // Monitoramento automático de expiração
  const startAutoRefresh = () => {
    const checkInterval = setInterval(async () => {
      // Verificar se token vai expirar nos próximos 10 minutos (mais margem de segurança)
      const tenMinutesInMs = 10 * 60 * 1000
      const timeLeft = expiresAt.value - Date.now()

      if (timeLeft <= tenMinutesInMs && timeLeft > 0 && accessToken.value && !isRefreshing.value) {
        console.log(`⚠️ Token expira em ${Math.floor(timeLeft / 60000)} minutos. Renovando...`)
        await refreshAccessToken()
      }
    }, 30 * 1000) // Verificar a cada 30 segundos

    return () => clearInterval(checkInterval)
  }

  // Fazer requisição autenticada à API do Spotify
  const spotifyApiRequest = async (url: string, options: RequestInit = {}) => {
    const token = await getValidToken()
    if (!token) {
      throw new Error('Token não disponível')
    }

    const response = await fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        'Authorization': `Bearer ${token}`
      }
    })

    // Se receber 401, tentar renovar token uma vez
    if (response.status === 401) {
      console.log('🔄 Recebido 401, tentando renovar token...')
      const newToken = await getValidToken()
      if (newToken) {
        // Repetir requisição com novo token
        return fetch(url, {
          ...options,
          headers: {
            ...options.headers,
            'Authorization': `Bearer ${newToken}`
          }
        })
      }
    }

    return response
  }

  // Debug info
  const getDebugInfo = () => ({
    hasAccessToken: !!accessToken.value,
    hasRefreshToken: !!refreshToken.value,
    isExpired: isTokenExpired.value,
    expiresIn: Math.floor(timeUntilExpiry.value / 1000),
    expiresAt: new Date(expiresAt.value).toLocaleString(),
    isRefreshing: isRefreshing.value,
    lastError: lastRefreshError.value
  })

  return {
    // Estados
    accessToken: readonly(accessToken),
    refreshToken: readonly(refreshToken),
    expiresAt: readonly(expiresAt),
    isAuthenticated,
    isTokenExpired,
    timeUntilExpiry,
    minutesUntilExpiry,
    isRefreshing: readonly(isRefreshing),
    lastRefreshError: readonly(lastRefreshError),

    // Métodos
    initializeTokens,
    refreshAccessToken,
    getValidToken,
    clearTokens,
    startAutoRefresh,
    spotifyApiRequest,
    getDebugInfo
  }
}