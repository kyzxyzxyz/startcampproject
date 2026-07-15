<template>
  <div class="page card">
    <div class="view-header" style="display:flex;justify-content:space-between;align-items:center;">
      <div>
        <h2>커뮤니티</h2>
        <p class="muted">카테고리별 게시글 목록입니다.</p>
      </div>
      <div>
        <button class="btn primary" @click="goWrite">글 작성</button>
      </div>
    </div>

    <div class="category-bar" style="margin:12px 0;">
      <button :class="['cat-btn',{active:selected===null}]" @click="select(null)">전체</button>
      <button v-for="c in categories" :key="c" :class="['cat-btn',{active:selected===c}]" @click="select(c)">{{ c }}</button>
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
      '관광지','레포츠','문화시설','쇼핑','숙박','여행코스','음식점','축제공연행사'
    ]
    const selected = ref(null)
    function select(c){ selected.value = c }

    function goWrite(){
      // 이동시 현재 선택 카테고리를 쿼리로 전달 (작성 폼에서 초기값으로 사용)
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