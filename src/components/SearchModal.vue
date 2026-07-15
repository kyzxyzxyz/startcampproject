<template>
  <div v-if="visible" class="sm-overlay" @click.self="close" @keydown.esc="close" tabindex="-1">
    <div class="sm-modal modal-card" role="dialog" aria-modal="true">
      <div class="sm-header" style="display:flex;align-items:center;justify-content:space-between;padding:12px 16px;border-bottom:1px solid rgba(11,17,34,0.04)">
        <strong>검색</strong>
        <BaseButton variant="ghost" size="sm" @click="close" aria-label="닫기">✕</BaseButton>
      </div>

      <div class="sm-body" style="padding:12px 16px;">
        <div class="search-row">
          <input v-model="q" ref="qInput" @keydown.enter="doSearch" placeholder="검색어를 입력하세요" />
          <BaseButton variant="primary" @click="doSearch">검색</BaseButton>
          <BaseButton variant="ghost" @click="clear">초기화</BaseButton>
        </div>

        <div v-if="loading" class="muted">검색 중...</div>

        <ul class="result-list" v-if="results.length">
          <li v-for="(r,i) in results" :key="i" class="result-item">
            <button class="result-link" @click="selectResult(r)">{{ r.title }}</button>
            <div class="result-sub">{{ r.typeLabel }}{{ r.category ? ' · ' + r.category : '' }}{{ r.addr ? ' · ' + r.addr : '' }}</div>
          </li>
        </ul>

        <div v-else-if="!loading" class="muted">검색 결과가 없습니다.</div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import BaseButton from './BaseButton.vue'
import { loadAllData, simpleRank } from '../utils/dataSearch'
import { loadPosts } from '../utils/storage'

export default {
  name: 'SearchModal',
  components: { BaseButton },
  setup(_, { expose }) {
    const visible = ref(false)
    const q = ref('')
    const loading = ref(false)
    const results = ref([])
    const qInput = ref(null)
    const router = useRouter()
    const route = useRoute()
    let placeCache = []

    async function open() {
      visible.value = true
      if (!placeCache.length) {
        loading.value = true
        placeCache = await loadAllData().catch(()=>[])
        loading.value = false
      }
      setTimeout(()=>{ if(qInput.value && qInput.value.focus) qInput.value.focus() },60)
    }
    function close() { visible.value = false; q.value=''; results.value = [] }

    async function doSearch() {
      const term = (q.value || '').trim()
      results.value = []
      if (!term) return
      loading.value = true

      const places = simpleRank(term, placeCache, 30).map(item => ({
        type: 'place',
        typeLabel: '장소',
        title: item.title || '',
        addr: item.addr1 || item.addr || '',
        category: item.contentType || item.cat1 || '',
        lat: item.mapy ? Number(item.mapy) : null,
        lon: item.mapx ? Number(item.mapx) : null,
        raw: item
      }))

      let posts = []
      try { posts = loadPosts() } catch(e){ posts = [] }
      const qlower = term.toLowerCase()
      const postMatches = posts.filter(p =>
        ((p.title||'') + ' ' + (p.content||'')).toLowerCase().includes(qlower)
      ).slice(0, 30).map(p => ({
        type: 'post',
        typeLabel: '게시글',
        title: p.title || '',
        category: p.category || '',
        addr: '',
        poiId: p.poiId || null,
        postId: p.id,
        raw: p
      }))

      results.value = [...places, ...postMatches]
      loading.value = false
    }

    function clear() { q.value=''; results.value = []; if(qInput.value && qInput.value.focus) qInput.value.focus() }

    function ensureHomeAndRun(cb) {
      const onNavigated = () => {
        setTimeout(() => { try { cb() } catch(e){} }, 300)
      }

      if (route.path === '/') {
        setTimeout(() => { try { cb() } catch(e){} }, 100)
      } else {
        router.push('/').then(onNavigated).catch(onNavigated)
      }
    }

    async function selectResult(r) {
      if (r.type === 'place') {
        ensureHomeAndRun(() => {
          try { window.dispatchEvent(new CustomEvent('goto-poi', { detail: { lat: r.lat, lon: r.lon, title: r.title, raw: r.raw } })) } catch(e){}
        })
      } else if (r.type === 'post') {
        const pid = r.postId || (r.raw && r.raw.id)
        if (pid) {
          try {
            router.push(`/board/${pid}`)
          } catch(e){}
          close()
          return
        }

        if (r.poiId) {
          if (!placeCache.length) placeCache = await loadAllData().catch(()=>[])
          const match = placeCache.find(p => String(p.contentid || p.contentId || '') === String(r.poiId))
          if (match && match.mapx && match.mapy) {
            ensureHomeAndRun(() => {
              try { window.dispatchEvent(new CustomEvent('goto-poi', { detail: { lat: Number(match.mapy), lon: Number(match.mapx), title: r.title, raw: match } })) } catch(e){}
            })
            close(); return
          }
          ensureHomeAndRun(() => {
            try { window.dispatchEvent(new CustomEvent('goto-poi', { detail: { raw: { contentid: r.poiId }, title: r.title, postId: r.postId } })) } catch(e){}
          })
          close(); return
        }

        try { window.dispatchEvent(new CustomEvent('open-post', { detail: r.raw })) } catch(e){}
        router.push('/community').catch(()=>{})
      }
      close()
    }

    expose({ open, close })
    return { visible, q, loading, results, open, close, doSearch, clear, qInput, selectResult }
  }
}
</script>

<style scoped>
.sm-overlay { position:fixed; inset:0; background:rgba(2,6,23,0.48); display:flex; align-items:center; justify-content:center; z-index:99999; }
.sm-modal { width:min(720px,96%); max-height:80vh; background:#fff; border-radius:10px; overflow:auto; }

/* body */
.sm-body { padding:12px 16px; }
.search-row { display:flex; gap:8px; align-items:center; margin-bottom:12px; }
.search-row input { flex:1; padding:8px 10px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); box-sizing:border-box; }

/* results */
.result-list { list-style:none; padding:0; margin:0; display:flex; flex-direction:column; gap:8px; }
.result-item { display:flex; flex-direction:column; gap:4px; padding:8px; border-radius:8px; background:#fbfdff; border:1px solid rgba(11,17,34,0.03); }
.result-link { background:transparent; border:none; color:var(--primary); font-weight:700; cursor:pointer; text-align:left; padding:0; }
.result-sub { color:#64748b; font-size:13px; }
.muted { color:#64748b; }
</style>