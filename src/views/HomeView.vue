<template>
  <div class="home-page">
    <section class="hero card">
      <div class="hero-inner">
        <div class="hero-left">
          <h1 class="hero-title">{{ $t('app.homeTitle') }}</h1>
          <p class="lead">{{ $t('app.homeLead') }}</p>

          <div class="category-grid" role="list">
            <BaseButton
              v-for="cat in categories"
              :key="cat.key"
              class="cat-card"
              variant="ghost"
              @click="openCategory(cat)"
              role="listitem"
            >
              <div class="cat-label">{{ $t(cat.labelKey) }}</div>
              <div class="cat-num">{{ getCount(cat.key) }}</div>
            </BaseButton>
          </div>
        </div>

        <div class="hero-right">
          <!-- 오른쪽 빈 공간/비주얼 영역 -->
        </div>
      </div>
    </section>

    <section class="content-row">
      <div class="left-col">
        <div class="card" id="map-section" ref="map">
          <h3 class="card-title">{{ $t('app.map') }}</h3>
          <MapView />
        </div>

        <div class="card festival-card">
          <div class="card-header">
            <h3 class="card-title">주간 축제 캘린더</h3>
            <BaseButton class="view-all-btn" variant="ghost" @click="goToFestivals">캘린더 전체보기</BaseButton>
          </div>

          <FestivalCalendar :compact="true" :show-date-controls="true" />
        </div>
      </div>

      <aside class="right-col">
        <div class="card">
          <WeatherCard />
        </div>

        <div class="card">
          <h4>{{ $t('app.recentPosts') }}</h4>
          <ul class="compact-list">
            <li v-for="p in recentPosts" :key="p.id">
              <router-link :to="`/board/${p.id}`">{{ p.title }}</router-link>
            </li>
            <li v-if="recentPosts.length===0"><em>{{ $t('app.noPosts') }}</em></li>
          </ul>
        </div>
      </aside>
    </section>

    <CategoryListModal
      :visible="showModal"
      :category="activeCategory"
      :items="modalItems"
      @close="closeModal"
    />
  </div>
</template>

<script>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import MapView from '../components/MapView.vue'
import CategoryListModal from '../components/CategoryListModal.vue'
import { loadPosts } from '../utils/storage'
import FestivalCalendar from '../components/FestivalCalendar.vue'
import WeatherCard from '../components/WeatherCard.vue'
import BaseButton from '../components/BaseButton.vue'

export default {
  components: { MapView, CategoryListModal, FestivalCalendar, WeatherCard, BaseButton },
  setup() {
    const router = useRouter()

    const categories = [
      { key: 'tourist', labelKey: 'categories.tourist', file: '/구미_경북권_관광지.json' },
      { key: 'food', labelKey: 'categories.food', file: '/구미_경북권_음식점.json' },
      { key: 'shopping', labelKey: 'categories.shopping', file: '/구미_경북권_쇼핑.json' },
      { key: 'sports', labelKey: 'categories.sports', file: '/구미_경북권_레포츠.json' },
      { key: 'culture', labelKey: 'categories.culture', file: '/구미_경북권_문화시설.json' },
      { key: 'lodging', labelKey: 'categories.lodging', file: '/구미_경북권_숙박.json' },
      { key: 'course', labelKey: 'categories.course', file: '/구미_경북권_여행코스.json' },
      { key: 'festival', labelKey: 'categories.festival', file: '/구미_경북권_축제공연행사.json' }
    ]

    const counts = reactive({})
    const itemsCache = reactive({})
    const showModal = ref(false)
    const activeCategory = ref(null)
    const modalItems = ref([])
    const recentPosts = ref([])

    function loadRecentPosts() {
      const all = loadPosts() || []
      all.sort((a, b) => {
        const ta = a.createdAt || a.createdTime || a.created || ''
        const tb = b.createdAt || b.createdTime || b.created || ''
        return (tb > ta) ? 1 : (tb < ta) ? -1 : 0
      })
      recentPosts.value = all.slice(0, 3)
    }

    async function fetchCount(cat) {
      try {
        const res = await fetch(cat.file)
        if (!res.ok) return 0
        const json = await res.json()
        return (json.total ?? (json.items && json.items.length) ?? 0)
      } catch (e) {
        return 0
      }
    }

    async function loadAllCounts() {
      await Promise.all(categories.map(async (c) => {
        counts[c.key] = await fetchCount(c)
      }))
    }

    async function openCategory(cat) {
      activeCategory.value = cat
      if (itemsCache[cat.key]) {
        modalItems.value = itemsCache[cat.key]
        showModal.value = true
        return
      }
      try {
        const res = await fetch(cat.file)
        if (!res.ok) {
          modalItems.value = []
          showModal.value = true
          return
        }
        const json = await res.json()
        const items = Array.isArray(json.items) ? json.items.slice() : []
        items.sort((a, b) => {
          if (!a.title) return -1
          if (!b.title) return 1
          return a.title.localeCompare(b.title, 'ko')
        })
        itemsCache[cat.key] = items
        modalItems.value = items
      } catch (e) {
        modalItems.value = []
      } finally {
        showModal.value = true
      }
    }

    function closeModal() {
      showModal.value = false
      activeCategory.value = null
      modalItems.value = []
    }

    function goToFestivals() {
      router.push('/festivals')
    }

    function getCount(key) {
      const v = counts[key]
      return (v === undefined || v === null) ? 0 : v
    }

    onMounted(() => {
      loadAllCounts()
      loadRecentPosts()
      window.addEventListener('ggb-posts-changed', loadRecentPosts)
    })

    return {
      categories,
      counts,
      showModal,
      activeCategory,
      modalItems,
      getCount,
      openCategory,
      closeModal,
      recentPosts,
      goToFestivals
    }
  }
}
</script>

<style scoped>
.hero {
  background: var(--card);
  padding: 18px;
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  border: 1px solid rgba(11,17,34,0.04);
}

.hero-inner {
  display: flex;
  gap: 24px;
  align-items: flex-start;
  max-width: 1100px;
  margin: 0 auto;
}

.hero-title {
  font-size: 22px;
  margin: 0 0 6px;
  color: var(--text);
  font-weight: 800;
}
.lead {
  margin: 0 0 16px;
  color: var(--muted);
  font-size: 14px;
}

/* 카테고리 그리드: 한 줄로 정렬, 가로 스크롤 허용 */
.category-grid {
  display: flex;
  gap: 10px;
  flex-wrap: nowrap;
  overflow-x: auto;
  padding-bottom: 6px;
  -webkit-overflow-scrolling: touch;
}

/* 카테고리 카드: 이름 위, 개수 아래 (세로 정렬) */
.cat-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px 12px;
  border-radius: 10px;
  min-width: 120px;
  height: 72px;
  background: transparent;
  border: 1px solid rgba(11,17,34,0.04);
  color: var(--text);
  flex: 0 0 auto;
}

/* 카테고리 이름 강조 */
.cat-label {
  font-size: 16px;
  font-weight: 700;
  color: var(--text);
  line-height: 1;
  text-align: center;
}

/* 개수는 아래, primary 색상 */
.cat-num {
  font-weight: 800;
  color: var(--primary);
  font-size: 14px;
  text-align: center;
}

/* 반응형: 작은 화면에서 카드 너비 축소 */
@media (max-width: 820px) {
  .hero-inner { flex-direction: column; gap: 12px; }
  .hero-right { display: none; }
  .category-grid { gap: 8px; }
  .cat-card { min-width: 100px; height: 64px; padding: 8px 10px; }
  .cat-label { font-size: 15px; }
  .cat-num { font-size: 13px; }
}
</style>