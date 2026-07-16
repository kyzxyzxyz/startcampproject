<template>
  <div class="page card">
    <div class="view-header" style="display:flex;justify-content:space-between;align-items:center;">
      <div>
        <h2>{{ $t('app.communityView') }}</h2>
        <p class="muted">{{ $t('board.listTitle') }}</p>
      </div>
      <div>
        <BaseButton variant="primary" @click="goWrite">{{ $t('app.myPost') }}</BaseButton>
      </div>
    </div>

    <div class="category-bar" style="margin:12px 0;">
      <BaseButton :class="['cat-btn',{active:selected===null}]" variant="ghost" @click="select(null)">{{ $t('board.all') }}</BaseButton>
      <BaseButton v-for="c in categories" :key="c.key" :class="['cat-btn',{active:selected===c.value}]" variant="ghost" @click="select(c.value)">{{ $t(`categories.${c.key}`) }}</BaseButton>
    </div>

    <BoardList :category="selected" :poiId="null" />
  </div>
</template>

<script>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import BoardList from '../components/BoardList.vue'
import BaseButton from '../components/BaseButton.vue'

export default {
  components: { BoardList, BaseButton },
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
.muted { color:var(--muted); margin:0; }

/* 카테고리 버튼: 다크/라이트 변수 사용 */
.cat-btn {
  margin-right:8px;
  padding:8px 12px;
  border-radius:8px;
  border:1px solid var(--border);
  background: transparent;
  color: var(--text);
  cursor:pointer;
  transition: all .12s ease;
  box-shadow: none;
}

/* 호버(비활성 상태) */
.cat-btn:not(.active):hover {
  background: color-mix(in srgb, var(--card) 92%, var(--primary) 8%);
  color: var(--text);
  border-color: var(--border);
}

/* 활성 상태 */
.cat-btn.active {
  background: var(--primary);
  color: #fff;
  border-color: var(--primary);
}

/* 모바일에서 버튼 간격 보정 */
@media (max-width:720px) {
  .cat-btn { margin-bottom:8px; }
}
</style>