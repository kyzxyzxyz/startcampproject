import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import HomeView from './views/HomeView.vue'
import BoardView from './views/BoardView.vue'
import BoardDetail from './views/BoardDetail.vue'
import ChatView from './views/ChatView.vue'
import CommunityView from './views/CommunityView.vue'
import FestivalView from './views/FestivalView.vue'
import './styles.css'
import i18n from './i18n' // vue-i18n 설정 파일
import { updateMetaThemeColor, setTheme, initThemeStorageSync } from './utils/theme';

import 'leaflet/dist/leaflet.css'
import L from 'leaflet'
try {
  delete L.Icon.Default.prototype._getIconUrl
} catch (e) {}
L.Icon.Default.mergeOptions({
  iconRetinaUrl: new URL('leaflet/dist/images/marker-icon-2x.png', import.meta.url).href,
  iconUrl: new URL('leaflet/dist/images/marker-icon.png', import.meta.url).href,
  shadowUrl: new URL('leaflet/dist/images/marker-shadow.png', import.meta.url).href,
})

const routes = [
  { path: '/', component: HomeView },
  { path: '/community', component: CommunityView },
  { path: '/board', component: BoardView },
  { path: '/board/:id', component: BoardDetail, props: true },
  { path: '/festivals', component: FestivalView },
  { path: '/chat', component: ChatView }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 메타/테마 초기화
updateMetaThemeColor();
initThemeStorageSync();

const app = createApp(App)
app.use(router)
app.use(i18n)

// 전역 테마 접근성 제공
app.config.globalProperties.$setTheme = setTheme
window.setTheme = setTheme

// 전역 이벤트: 'open-post' 수신 시 상세로 이동 후 CommunityModal 닫기 이벤트 발생
window.addEventListener('open-post', (e) => {
  try {
    const d = e && e.detail ? e.detail : null
    let id = null
    if (!d) return
    if (typeof d === 'string') id = d
    else if (d.id) id = d.id
    else if (d.postId) id = d.postId
    else if (d.raw) id = (d.raw.id || d.raw.postId || null)
    if (id) {
      router.push(`/board/${String(id)}`)
        .then(() => {
          try { window.dispatchEvent(new Event('close-community')) } catch (err) {}
        })
        .catch(()=>{})
    }
  } catch (err) {
    // 무시
  }
})

app.mount('#app')