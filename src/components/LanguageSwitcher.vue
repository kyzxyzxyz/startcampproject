<template>
  <div class="lang-switcher" role="navigation" aria-label="language switcher">
    <button :class="['lang-btn', { active: current === 'ko' }]" @click="set('ko')">KO</button>
    <button :class="['lang-btn', { active: current === 'en' }]" @click="set('en')">EN</button>
  </div>
</template>

<script>
import { computed, onMounted } from 'vue'
import i18n from '../i18n'

export default {
  name: 'LanguageSwitcher',
  setup() {
    const current = computed(() => {
      try { return i18n.global.locale.value } catch(e){ return 'ko' }
    })

    function set(l) {
      if (!l) return
      try {
        i18n.global.locale.value = l
        localStorage.setItem('locale', l)
      } catch (e) { /* ignore */ }
    }

    onMounted(() => {
      try {
        const saved = localStorage.getItem('locale')
        if (saved) i18n.global.locale.value = saved
      } catch (e) {}
    })

    return { current, set }
  }
}
</script>

<style scoped>
.lang-switcher { display:flex; gap:6px; align-items:center; }

.lang-btn {
  background: transparent;
  border: none;
  color: #2563eb;
  font-weight: 600;
  cursor: pointer;
  padding: 6px 8px;
  font-size: 14px;
}
.lang-btn.active {
  text-decoration: underline;
  color: #2563eb;
}
</style>