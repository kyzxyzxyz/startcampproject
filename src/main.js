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

// Leaflet CSS + 아이콘 설정
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

createApp(App).use(router).use(i18n).mount('#app')