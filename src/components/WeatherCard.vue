<template>
  <div class="weather-card">
    <div class="weather-header">
      <div>
        <p class="weather-label">현재 날씨</p>
        <h4>{{ city }}</h4>
      </div>
      <BaseButton variant="ghost" size="sm" class="refresh-btn" @click="loadWeather">↻</BaseButton>
    </div>

    <div v-if="loading" class="weather-state">불러오는 중...</div>
    <div v-else-if="error" class="weather-state error">{{ error }}</div>
    <div v-else class="weather-body">
      <div class="temp-row">
        <img v-if="weather.icon" :src="iconUrl" alt="weather icon" />
        <div>
          <div class="temp">{{ weather.temp }}°C</div>
          <div class="desc">{{ weather.description }}</div>
        </div>
      </div>

      <ul class="weather-meta">
        <li>체감 {{ weather.feelsLike }}°C</li>
        <li>습도 {{ weather.humidity }}%</li>
        <li>풍속 {{ weather.wind }}m/s</li>
      </ul>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import BaseButton from './BaseButton.vue'

const city = '구미'
const apiKey = import.meta.env.VITE_OPENWEATHER_API_KEY
const weather = ref(null)
const loading = ref(true)
const error = ref('')

const iconUrl = computed(() => {
  if (!weather.value?.icon) return ''
  return `https://openweathermap.org/img/wn/${weather.value.icon}@2x.png`
})

async function loadWeather() {
  loading.value = true
  error.value = ''

  if (!apiKey) {
    error.value = 'API 키가 설정되지 않았습니다. .env.local을 확인하세요.'
    loading.value = false
    return
  }

  try {
    const res = await fetch(
      `https://api.openweathermap.org/data/2.5/weather?lat=36.1194&lon=128.344&appid=${apiKey}&units=metric&lang=ko`
    )

    if (!res.ok) throw new Error('날씨 정보를 불러오지 못했습니다.')

    const data = await res.json()

    weather.value = {
      temp: Math.round(data.main.temp),
      feelsLike: Math.round(data.main.feels_like),
      description: data.weather?.[0]?.description || '',
      icon: data.weather?.[0]?.icon || '',
      humidity: data.main?.humidity,
      wind: Math.round(data.wind?.speed || 0),
      name: data.name
    }
  } catch (e) {
    error.value = e.message || '날씨를 불러오지 못했습니다.'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadWeather()
})
</script>

<style scoped>
.weather-card {
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 14px;
  background: var(--surface);
}
.weather-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}
.weather-label {
  margin: 0;
  font-size: 12px;
  color: var(--text-muted);
}
.refresh-btn {
  border-radius: 999px;
  width: 32px;
  height: 32px;
}
.weather-body {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.temp-row {
  display: flex;
  align-items: center;
  gap: 10px;
}
.temp {
  font-size: 24px;
  font-weight: 700;
  color: var(--text-main);
}
.desc {
  color: var(--text-muted);
}
.weather-meta {
  list-style: none;
  padding: 0;
  margin: 0;
  color: var(--text-muted);
  font-size: 13px;
}
.weather-state.error {
  color: #dc2626;
}



</style>