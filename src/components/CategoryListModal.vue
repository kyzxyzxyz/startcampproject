<template>
  <div v-if="visible" class="overlay" @click.self="close">
    <div class="modal modal-card">
      <div class="modal-header">
        <h3>{{ category ? $t(category.labelKey) : $t('modal.itemsTitle', { label: $t('app.list') }) }}</h3>
        <BaseButton variant="ghost" size="sm" @click="close">{{ $t('app.close') }}</BaseButton>
      </div>

      <div class="modal-body">
        <div class="modal-controls">
          <input class="search-input" v-model="searchQuery" :placeholder="$t('modal.searchPlaceholder')" />
          <BaseButton v-if="searchQuery" variant="ghost" @click="clearSearch">초기화</BaseButton>
        </div>

        <div v-if="items && items.length>0">
          <p class="count">{{ $t('modal.resultCount', { total: items.length, filtered: filteredItems.length }) }}</p>
          <ul class="poi-list">
            <li v-for="it in filteredItems" :key="it.contentid || it.id" class="poi-item">
              <div class="poi-row">
                <div class="poi-left" v-if="it.firstimage || it.image || it.thumbnail">
                  <img
                    :src="it.firstimage || it.image || it.thumbnail"
                    alt=""
                    class="poi-thumb"
                    @error="handleImgError($event)"
                  />
                </div>

                <div class="poi-main">
                  <BaseButton variant="ghost" class="plain-link" @click="openCommunity(it)">
                    {{ it.title || it.name }}
                  </BaseButton>

                  <div class="poi-meta">
                    <div class="poi-addr" v-if="it.addr1 || it.addr">{{ it.addr1 || it.addr }}</div>
                    <div v-if="it.tel" class="poi-tel">☎ {{ it.tel }}</div>
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </div>
        <div v-else>
          <p>{{ $t('modal.noItems') }}</p>
        </div>
      </div>

      <div class="modal-footer">
        <BaseButton variant="ghost" @click="close">{{ $t('app.close') }}</BaseButton>
      </div>
    </div>
  </div>
</template>

<script>
import BaseButton from './BaseButton.vue'

export default {
  name: 'CategoryListModal',
  components: { BaseButton },
  props: {
    visible: { type: Boolean, default: false },
    category: { type: Object, default: null },
    items: { type: Array, default: () => [] }
  },
  emits: ['close'],
  data() {
    return { searchQuery: '' }
  },
  computed: {
    filteredItems() {
      const q = (this.searchQuery || '').trim().toLowerCase()
      if (!q) return this.items || []
      return (this.items || []).filter(it => {
        const title = (it.title || it.name || '').toString().toLowerCase()
        return title.includes(q)
      })
    }
  },
  watch: {
    visible(val) { if (val === true) this.searchQuery = '' }
  },
  methods: {
    close() { this.$emit('close') },
    clearSearch() { this.searchQuery = '' },
    openCommunity(item) {
      try {
        const poiId = item.contentid || item.contentId || item.id || null
        const poiTitle = item.title || item.name || ''
        const poiCategory = (this.category && (this.category.label || this.category.labelKey || this.category.key)) || null
        window.dispatchEvent(new CustomEvent('open-community', { detail: { poiId, poiTitle, poiCategory } }))
      } catch (e) { /* ignore */ }
      this.close()
    },
    handleImgError(e) {
      e.target.style.display = 'none'
    }
  }
}
</script>

<style scoped>
.overlay { position:fixed; inset:0; background:rgba(2,6,23,0.5); display:flex; align-items:center; justify-content:center; z-index:99999; }
.modal { width:min(760px,96%); max-height:80vh; overflow:auto; background:#fff; border-radius:10px; padding:12px; box-sizing:border-box; }
.modal-header { display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid #eee; padding-bottom:8px; }
.modal-body { padding:12px 0; }
.modal-controls { display:flex; gap:8px; margin-bottom:8px; align-items:center; }
.search-input { flex:1; padding:8px 10px; border:1px solid rgba(11,17,34,0.08); border-radius:8px; }
.poi-list { list-style:none; padding:0; margin:0; }
.poi-item { padding:8px 0; border-bottom:1px solid rgba(2,6,23,0.04); }

/* 레이아웃: 썸네일 + 본문 */
.poi-row { display:flex; align-items:flex-start; gap:12px; }
.poi-left { width:72px; flex:0 0 72px; }
.poi-thumb { width:72px; height:72px; object-fit:cover; border-radius:8px; display:block; }

/* 글영역 */
.poi-main { flex:1; display:flex; flex-direction:column; gap:6px; min-width:0; }
.plain-link {
  background: transparent;
  border: none;
  color: var(--primary);
  font-weight: 600;
  cursor: pointer;
  padding: 0;
  text-align: left;
  font-size: 15px;
  display: inline-block;
  white-space: normal;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height:1.2;
}
.plain-link:hover { text-decoration: underline; }

/* 제목 밑 메타(작게) */
.poi-meta { display:flex; flex-direction:column; gap:4px; }
.poi-addr { font-size:12px; color:#64748b; }
.poi-tel { font-size:12px; color:#0b1220; }

/* 모바일: 썸네일 왼쪽에서 위로 이동 */
@media (max-width: 560px) {
  .poi-row { flex-direction:column; align-items:flex-start; }
  .poi-left { width:100%; flex:0 0 auto; }
  .poi-thumb { width:100%; height:160px; }
  .poi-main { width:100%; }
}
</style>