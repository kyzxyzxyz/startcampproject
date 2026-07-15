<template>
  <div class="page card">
    <div class="view-header" style="display:flex;justify-content:space-between;align-items:center;">
      <div>
        <h2>{{ $t('app.communityView') }}</h2>
        <p class="muted">{{ $t('board.listTitle') }}</p>
      </div>
      <div>
        <button class="btn primary" @click="goWrite">{{ $t('app.myPost') }}</button>
      </div>
    </div>

    <div class="category-bar" style="margin:12px 0;">
      <button :class="['cat-btn',{active:selected===null}]" @click="select(null)">{{ $t('board.all') }}</button>
      <button v-for="c in categories" :key="c.key" :class="['cat-btn',{active:selected===c.value}]" @click="select(c.value)">{{ $t(`categories.${c.key}`) }}</button>
    </div>

    <BoardList :category="selected" :poiId="null" />
  </div>
</template>

<script>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import BoardList from '../components/BoardList.vue'

export default {
  components: { BoardList },
  setup() {
    const router = useRouter()
    const categories = [
      { key: 'tourist', value: '관광지' },
      { key: 'sports', value: '레포츠' },
      { key: 'culture', value: '문화시설' },
      { key: 'shopping', value: '쇼핑' },
      { key: 'lodging', value: '숙박' },
      { key: 'course', value: '여행코스' },
      { key: 'food', value: '음식점' },
      { key: 'festival', value: '축제공연행사' }
    ]
    const selected = ref(null)
    function select(c){ selected.value = c }

    function goWrite(){
      const q = {}
      if (selected.value) q.category = selected.value
      router.push({ path: '/board', query: q })
    }

    return { categories, selected, select, goWrite }
  }
}
</script>

<style scoped>
.muted { color:#64748b; margin:0; }
.cat-btn { margin-right:8px; padding:8px 12px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); background:#fff; cursor:pointer; }
.cat-btn.active { background:#0f62fe; color:#fff; border-color:#0f62fe; }
.btn.primary { background:#2563eb; color:#fff; border:none; padding:8px 12px; border-radius:8px; }
</style>