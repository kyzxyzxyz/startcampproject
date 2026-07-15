<template>
  <div class="lang-switcher" role="navigation" aria-label="language switcher">
    <BaseButton variant="ghost" size="sm" :class="{ active: current === 'ko' }" @click="set('ko')">KO</BaseButton>
    <BaseButton variant="ghost" size="sm" :class="{ active: current === 'en' }" @click="set('en')">EN</BaseButton>
  </div>
</template>

<script>
import { computed, onMounted } from 'vue'
import i18n from '../i18n'
import BaseButton from './BaseButton.vue'

export default {
  name: 'LanguageSwitcher',
  components: { BaseButton },
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
.lang-switcher .active { text-decoration: underline; }
</style>