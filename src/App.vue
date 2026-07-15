<template>
  <div id="app">
    <header class="site-header">
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
          <button class="btn primary" @click="goCommunity">커뮤니티</button>
          <button class="btn primary" @click="goMap">지도</button>
          <LanguageSwitcher />
          <button class="search-btn" aria-label="검색" @click="openSearchModal">
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
          <div class="contact-item">컨택 이메일: <a href="mailto:contact@example.com">contact@example.com</a></div>
          <div class="contact-item">연락처: <a href="tel:+821012345678">+82 10-1234-5678</a></div>
        </div>

        <div class="subscribe">
          <form class="subscribe-form" @submit.prevent="subscribe">
            <input id="sub-email" v-model="email" type="email" placeholder="이메일을 입력하세요" />
            <button type="submit" class="btn primary">구독</button>
          </form>
          <p class="subscribe-note">뉴스레터와 업데이트를 이메일로 받아보세요.</p>
        </div>
      </div>
    </footer>

    <ChatModal />
    <CommunityModal />
    <SearchModal ref="searchModal" />
  </div>
</template>

<script>
import { ref } from 'vue'
import ChatModal from './components/ChatModal.vue'
import CommunityModal from './components/CommunityModal.vue'
import LanguageSwitcher from './components/LanguageSwitcher.vue'
import SearchModal from './components/SearchModal.vue'

export default {
  components: { ChatModal, CommunityModal, LanguageSwitcher, SearchModal },
  setup() {
    const searchModal = ref(null)
    const email = ref('')

    function openSearchModal() {
      if (searchModal.value && searchModal.value.open) searchModal.value.open()
    }

    function subscribe() {
      if (!email.value) {
        alert('이메일을 입력하세요.')
        return
      }
      try {
        const subs = JSON.parse(localStorage.getItem('subscribers') || '[]')
        subs.push({ email: email.value, date: new Date().toISOString() })
        localStorage.setItem('subscribers', JSON.stringify(subs))
        alert('구독해주셔서 감사합니다!')
        email.value = ''
      } catch (e) {
        console.error(e)
        alert('구독 처리 중 오류가 발생했습니다.')
      }
    }

    return { searchModal, openSearchModal, email, subscribe }
  },
  methods: {
    goCommunity() {
      this.$router.push('/community')
    },
    goMap() {
      this.$router.push('/').catch(()=>{})
      setTimeout(() => {
        const el = document.querySelector('#map-section')
        if (el && el.scrollIntoView) el.scrollIntoView({ behavior: 'smooth' })
      }, 300)
    }
  }
}
</script>

<style scoped>
/* 기존 스타일 유지 (생략 가능) */
.site-header { background:#fff; border-bottom:1px solid rgba(2,6,23,0.06); position:sticky; top:0; z-index:60; }
.header-inner { max-width:1100px; margin:0 auto; display:flex; align-items:center; gap:16px; padding:12px 16px; box-sizing:border-box; }
.brand { display:flex; align-items:center; min-width:160px; }
.logo { display:flex; align-items:center; gap:10px; text-decoration:none; }
.logo-mark { flex:0 0 auto; }
.brand-text { font-family: 'Poppins', system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial; font-weight:700; color:#2563eb; font-size:20px; }
.header-actions { margin-left:auto; display:flex; gap:10px; align-items:center; justify-content:flex-end; }
.header-actions .btn.primary { padding: 8px 12px; border-radius: 12px; font-weight:700; font-size:14px; min-height:36px; min-width:76px; box-shadow: 0 6px 18px rgba(15,99,254,0.12); }
.header-actions > *:not(:last-child) { vertical-align:middle; }
.search-btn { display:inline-flex; align-items:center; justify-content:center; width:40px; height:40px; border-radius:50%; border:1px solid rgba(11,17,34,0.06); background:#fff; cursor:pointer; }
@media (max-width:900px) {
  .brand-text { font-size:18px; }
  .header-inner { padding:10px 12px; }
  .header-actions .btn.primary { padding:6px 10px; font-size:13px; border-radius:10px; min-width:68px; }
}

.site-footer { background:#f8fafc; border-top:1px solid rgba(2,6,23,0.06); padding:28px 0; }
.footer-inner { max-width:1100px; margin:0 auto; display:flex; align-items:center; justify-content:space-between; gap:20px; padding:0 16px; box-sizing:border-box; }
.contact { display:flex; flex-direction:column; gap:6px; color:#334155; }
.contact-item a { color:#0f99ff; text-decoration:underline; }
.subscribe { display:flex; flex-direction:column; align-items:flex-end; gap:8px; }
.subscribe-form { display:flex; gap:8px; align-items:center; }
.subscribe-form input[type="email"] { padding:8px 10px; border:1px solid rgba(11,17,34,0.06); border-radius:10px; min-width:220px; }
.subscribe-note { font-size:13px; color:#64748b; margin:0; }
@media (max-width:700px) {
  .footer-inner { flex-direction:column; align-items:flex-start; }
  .subscribe { width:100%; align-items:flex-start; }
  .subscribe-form input[type="email"] { width:100%; min-width:0; }
}
</style>