<template>
  <div>
    <h3>{{ t('board.listTitle') }}</h3>
    <div class="search-row">
      <input ref="searchInput" class="search-input" v-model="q" :placeholder="t('app.searchPlaceholder')" />
      <button @click="doSearch">{{ t('board.search') }}</button>
      <button @click="clearSearch">{{ t('board.all') }}</button>
    </div>

    <ul class="post-list">
      <li v-for="p in paged" :key="p.id" class="post-item">
        <button class="post-link" @click="openPost(p)">{{ p.title }}</button>
        <small class="post-meta"> — {{ formatDate(p.createdAt) }}</small>
      </li>
    </ul>

    <div v-if="pages>1" class="pager">
      <button @click="prev" :disabled="page===1">{{ t('board.previous') }}</button>
      <span>{{page}} / {{pages}}</span>
      <button @click="next" :disabled="page===pages">{{ t('board.next') }}</button>
    </div>

    <div v-if="filtered.length===0">
      <p>{{ t('board.noPosts') }}</p>
    </div>
  </div>
</template>

<script>
import { computed, ref, watch, onMounted, onBeforeUnmount } from 'vue'
import { loadPosts } from '../utils/storage'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'

export default {
  name: 'BoardList',
  props: {
    category: { type: String, default: null },
    poiId: { type: String, default: null },
    reloadKey: { type: [String, Number], default: null },
    navigateOnClick: { type: Boolean, default: true }
  },
  emits: ['refresh','open-post'],
  setup(props, { emit }) {
    const { t } = useI18n()
    const route = useRoute()
    const router = useRouter()
    const q = ref('')
    const page = ref(1)
    const pageSize = 10
    const searchInput = ref(null)

    const postsVersion = ref(0)

    const filtered = computed(() => {
      const _v = postsVersion.value
      const all = loadPosts()
      const routePoi = route.query.poiId ? String(route.query.poiId) : null
      const effectivePoi = props.poiId || routePoi
      let arr = all
      if (props.category) arr = arr.filter(p => p.category === props.category)
      if (effectivePoi) arr = arr.filter(p => p.poiId === effectivePoi)
      if (!q.value) return arr
      return arr.filter(p => ( (p.title||'') + (p.content||'') ).toLowerCase().includes(q.value.toLowerCase()))
    })

    const pages = computed(() => Math.max(1, Math.ceil(filtered.value.length / pageSize)))
    const paged = computed(() => filtered.value.slice((page.value-1)*pageSize, page.value*pageSize))

    function doSearch() { page.value = 1 }
    function clearSearch() { q.value=''; page.value=1; emit('refresh') }
    function next(){ if(page.value<pages.value) page.value++ }
    function prev(){ if(page.value>1) page.value-- }

    watch(() => props.reloadKey, () => { page.value = 1 })

    function openPost(post) {
      emit('open-post', post)
      try { window.dispatchEvent(new CustomEvent('open-post', { detail: post })) } catch (e) {}
      if (props.navigateOnClick && post && post.id) {
        try { router.push({ path: `/board/${post.id}` }) } catch(e){ /* ignore */ }
      }
    }

    function formatDate(t){ return t ? new Date(t).toLocaleString() : '' }

    function onPostsChanged() {
      postsVersion.value++
      page.value = 1
    }

    function onFocusBoardSearch(e) {
      try {
        if (searchInput.value && typeof searchInput.value.focus === 'function') {
          searchInput.value.focus()
        }
        if (e && e.detail && typeof e.detail.q === 'string') {
          q.value = e.detail.q
          doSearch()
        }
      } catch (err) { /* ignore */ }
    }

    onMounted(() => {
      window.addEventListener('ggb-posts-changed', onPostsChanged)
      window.addEventListener('focus-board-search', onFocusBoardSearch)
    })
    onBeforeUnmount(() => {
      window.removeEventListener('ggb-posts-changed', onPostsChanged)
      window.removeEventListener('focus-board-search', onFocusBoardSearch)
    })

    watch(filtered, () => { if(page.value>pages.value) page.value = pages.value })

    return { t, q, page, pages, paged, doSearch, clearSearch, next, prev, filtered, openPost, formatDate, searchInput }
  }
}
</script>

<style scoped>
.search-row { display:flex; gap:8px; margin-bottom:8px; align-items:center; }
.search-input { flex:1; padding:8px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); box-sizing:border-box; }
.post-list { list-style:none; padding:0; margin:0; }
.post-item { display:flex; align-items:center; gap:8px; padding:10px 0; border-bottom:1px solid rgba(11,17,34,0.04); }
.post-link { background:transparent; border:none; color:var(--primary); font-weight:600; cursor:pointer; text-align:left; padding:0; }
.post-meta { color:#64748b; font-size:12px; margin-left:auto; }
.pager { margin-top:8px; display:flex; gap:8px; align-items:center; }
</style>