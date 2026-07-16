<template>
  <div id="app">
    <header class="site-header" :style="headerStyle">
      <div class="header-inner">
        <div class="brand">
          <router-link to="/" class="logo" aria-label="LocalHub 홈">
            <svg class="logo-mark" width="36" height="36" viewBox="0 0 24 24" fill="none" aria-hidden>
              <circle cx="12" cy="8" r="4.2" fill="#2563eb"/>
              <path d="M4 20c0-4.4 3.6-8 8-8s8 3.6 8 8" stroke="#2563eb" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
            <span class="brand-text">LocalHub</span>
          </router-link>
        </div>

        <div class="header-actions">
          <BaseButton @click="goMap" variant="ghost">{{ $t('app.map') }}</BaseButton>
          <BaseButton @click="goCommunity" variant="ghost">{{ $t('app.communityView') }}</BaseButton>
          <BaseButton @click="goCalendar" variant="ghost">{{ $t('app.calendar') }}</BaseButton>
          <LanguageSwitcher />
          <button class="search-btn theme-toggle" aria-label="다크 모드 토글" @click="toggleTheme">
            {{ isDark ? '🌙' : '☀️' }}
          </button>
          <button class="search-btn" :aria-label="$t('app.searchButtonAria') || '검색'" @click="openSearchModal">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
              <path d="M21 21l-4.35-4.35" stroke="#334155" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
              <circle cx="11" cy="11" r="5" stroke="#334155" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </button>
        </div>
      </div>
    </header>

    <main class="site-main">
      <router-view />
    </main>

    <footer class="site-footer">
      <div class="footer-inner">
        <div class="contact">
          <div class="contact-item">
            <strong>{{ $t('app.contactEmail') }} :</strong>
            <a href="mailto:contact@example.com"> contact@example.com</a>
          </div>
          <div class="contact-item">
            <strong>{{ $t('app.contactPhone') }} :</strong>
            <a href="tel:+821012345678"> +82 10-1234-5678</a>
          </div>
        </div>

        <div class="subscribe">
          <form class="subscribe-form" @submit.prevent="subscribe">
            <input id="sub-email" ref="subInput" v-model="email" type="email" :placeholder="$t('app.subscribePlaceholder')" aria-describedby="sub-error" />
            <BaseButton type="submit" variant="primary">{{ $t('app.subscribeButton') }}</BaseButton>
          </form>

          <p class="subscribe-note">{{ $t('app.subscribeNote') }}</p>
          <p id="sub-error" class="subscribe-error" v-if="subscribeError">{{ subscribeError }}</p>
        </div>
      </div>
    </footer>

    <ChatModal />
    <CommunityModal />
    <SearchModal ref="searchModal" />
  </div>
</template>

<script>
import { ref, nextTick, computed } from 'vue'
import ChatModal from './components/ChatModal.vue'
import CommunityModal from './components/CommunityModal.vue'
import LanguageSwitcher from './components/LanguageSwitcher.vue'
import SearchModal from './components/SearchModal.vue'
import BaseButton from './components/BaseButton.vue'

export default {
  components: { ChatModal, CommunityModal, LanguageSwitcher, SearchModal, BaseButton },
  setup() {
    const searchModal = ref(null)
    const email = ref('')
    const subInput = ref(null)
    const subscribeError = ref('')
    const isDark = ref(document.documentElement.classList.contains('dark'));

    const headerStyle = computed(() => ({
      background: isDark.value ? '#1e1e24' : '#ffffff',
      borderBottom: isDark.value ? '1px solid #2c2d35' : '1px solid rgba(2,6,23,0.06)',
      color: isDark.value ? '#f1f3f5' : '#0b1220'
    }));

    const iconColor = computed(() => isDark.value ? '#9aa0a6' : '#334155');

    function openSearchModal() {
      if (searchModal.value && searchModal.value.open) searchModal.value.open()
    }

    function syncIsDark() {
      isDark.value = document.documentElement.classList.contains('dark');
    }

    // 탭 간 동기화
    window.addEventListener('storage', (e) => {
      if (e.key === 'theme') syncIsDark();
    });

    // 시스템 테마 변경 감지 (브라우저 호환)
    const mq = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)');
    if (mq) {
      if (mq.addEventListener) mq.addEventListener('change', syncIsDark);
      else if (mq.addListener) mq.addListener(syncIsDark);
    }


    async function focusSubInput() {
      await nextTick()
      setTimeout(() => {
        try {
          const el = subInput.value || document.getElementById('sub-email')
          if (el && typeof el.focus === 'function') {
            el.focus()
            if (typeof el.select === 'function') el.select()
            if (typeof el.setSelectionRange === 'function') el.setSelectionRange(0, 9999)
          }
        } catch (e) {}
      }, 100)
    }

    async function subscribe() {
      subscribeError.value = ''
      if (!email.value) {
        subscribeError.value = '이메일을 입력하세요.'
        await focusSubInput()
        return
      }
      try {
        const subs = JSON.parse(localStorage.getItem('subscribers') || '[]')
        subs.push({ email: email.value, date: new Date().toISOString() })
        localStorage.setItem('subscribers', JSON.stringify(subs))
        alert('구독해주셔서 감사합니다!')
        email.value = ''
        await focusSubInput()
      } catch (e) {
        console.error(e)
        subscribeError.value = '구독 처리 중 오류가 발생했습니다.'
        await focusSubInput()
      }
    }

    return { searchModal, openSearchModal, email, subscribe, subInput, subscribeError, isDark, headerStyle, iconColor  }
  },
  methods: {
    goCommunity() { this.$router.push('/community') },
    goMap() {
      this.$router.push('/').catch(()=>{})
      setTimeout(()=>{
        const el = document.querySelector('#map-section');
        if(el && el.scrollIntoView) el.scrollIntoView({ behavior:'smooth' })
      }, 300)
    },
    goCalendar() { this.$router.push('/festivals') },

    toggleTheme() {
      const currentlyDark = document.documentElement.classList.contains('dark');
      (window.setTheme || (()=>{}))(!currentlyDark);
      this.isDark = !currentlyDark;
    }
  },
}
</script>

<style scoped>
.search-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 1px solid var(--border);
  background: var(--card);
  color: var(--text);
}

/* footer tweaks */
.contact-item { margin-bottom:6px; }
.subscribe-note { margin-top:6px; color:var(--muted); }
</style>