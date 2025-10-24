<template>
  <Transition name="unlock">
    <div v-if="!isUnlocked" class="password-overlay" :class="{ 'success': isUnlocking }">
      <div class="password-container" :class="{ 'success-animation': isUnlocking }">
        <div v-if="!isUnlocking" class="lock-icon">
          🔒
        </div>
        <div v-else class="success-content">
          <div class="unlock-icon">💕</div>
        </div>
        <div v-if="!isUnlocking" class="password-input-container">
          <input
            type="password"
            v-model="passwordInput"
            placeholder="Digite a senha..."
            class="password-input"
            maxlength="8"
            @input="validatePassword"
          />
          <div v-if="showError" class="error-message">
            Ei, quem você pensa que é para acessar isto?
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import '../assets/css/password-protection.css'

// Definir emits
const emit = defineEmits<{
  unlocked: []
}>()

const isUnlocked = ref(false)
const isUnlocking = ref(false)
const passwordInput = ref('')
const showError = ref(false)
const correctPassword = '19112021'

const validatePassword = () => {
  showError.value = false
  
  if (passwordInput.value.length === 8) {
    if (passwordInput.value === correctPassword) {
      // Inicia animação de sucesso
      isUnlocking.value = true
      
      // Após 2 segundos, remove o componente completamente
      setTimeout(() => {
        isUnlocked.value = true
        emit('unlocked')
      }, 2000)
    } else {
      showError.value = true
      // Limpa o campo após 2 segundos
      setTimeout(() => {
        passwordInput.value = ''
        showError.value = false
      }, 3000)
    }
  }
}

// Limpa erro quando usuário digita novamente
watch(passwordInput, () => {
  if (showError.value && passwordInput.value.length < 8) {
    showError.value = false
  }
})
</script>

