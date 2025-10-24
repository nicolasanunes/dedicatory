<template>
  <div v-if="!isUnlocked" class="password-overlay">
    <div class="password-container">
      <div class="lock-icon">
        🔒
      </div>
      <h2 class="lock-title">Acesso Restrito</h2>
      <div class="password-input-container">
        <input
          type="password"
          v-model="passwordInput"
          placeholder="Digite a senha..."
          class="password-input"
          maxlength="8"
          @input="validatePassword"
        />
        <div v-if="showError" class="error-message">
          Ei, quem você pensa que é para tentar abrir isto?
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'

const isUnlocked = ref(false)
const passwordInput = ref('')
const showError = ref(false)
const correctPassword = '19112021'

const validatePassword = () => {
  showError.value = false
  
  if (passwordInput.value.length === 8) {
    if (passwordInput.value === correctPassword) {
      isUnlocked.value = true
    } else {
      showError.value = true
      // Limpa o campo após 2 segundos
      setTimeout(() => {
        passwordInput.value = ''
        showError.value = false
      }, 2000)
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

<style scoped>
.password-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
  backdrop-filter: blur(10px);
}

.password-container {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(20px);
  border-radius: 20px;
  padding: 40px;
  text-align: center;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.2);
  max-width: 400px;
  width: 90%;
}

.lock-icon {
  font-size: 4rem;
  margin-bottom: 20px;
  animation: pulse 2s ease-in-out infinite alternate;
}

.lock-title {
  color: white;
  font-family: 'Dancing Script', cursive;
  font-size: 1.8rem;
  margin-bottom: 30px;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
}

.password-input-container {
  position: relative;
}

.password-input {
  width: 100%;
  padding: 15px 20px;
  border: none;
  border-radius: 50px;
  background: rgba(255, 255, 255, 0.9);
  font-size: 1.2rem;
  text-align: center;
  letter-spacing: 2px;
  outline: none;
  transition: all 0.3s ease;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
  box-sizing: border-box;
}

.password-input:focus {
  background: rgba(255, 255, 255, 1);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
  transform: translateY(-2px);
}

.password-input::placeholder {
  color: #666;
  letter-spacing: 1px;
}

.error-message {
  color: #ff4757;
  font-family: 'Dancing Script', cursive;
  font-size: 1.1rem;
  margin-top: 15px;
  font-weight: 600;
  text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.3);
  animation: shake 0.5s ease-in-out;
}

@keyframes pulse {
  from {
    transform: scale(1);
    opacity: 0.8;
  }
  to {
    transform: scale(1.1);
    opacity: 1;
  }
}

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-5px); }
  75% { transform: translateX(5px); }
}

/* Responsividade */
@media (max-width: 480px) {
  .password-container {
    padding: 30px 20px;
  }
  
  .lock-icon {
    font-size: 3rem;
  }
  
  .lock-title {
    font-size: 1.5rem;
  }
  
  .password-input {
    font-size: 1rem;
    padding: 12px 15px;
  }
  
  .error-message {
    font-size: 1rem;
  }
}
</style>