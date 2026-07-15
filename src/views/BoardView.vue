<template>
  <div class="page card">
    <div style="display:flex;justify-content:space-between;align-items:center;">
      <div>
        <h2>게시글 작성</h2>
        <p class="muted">여기에 글을 작성하세요. (비밀번호는 수정/삭제 시 필요)</p>
      </div>
      <div>
        <button class="btn primary" @click="$router.push('/community')">커뮤니티 목록으로</button>
      </div>
    </div>

    <div style="margin-top:12px">
      <BoardEditor :initialTitle="initialTitle" :initialPoiId="initialPoiId" :initialCategory="initialCategory" @created="onCreated" />
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import BoardEditor from '../components/BoardEditor.vue'

export default {
  components: { BoardEditor },
  setup() {
    const route = useRoute()
    const router = useRouter()
    const initialTitle = ref('')
    const initialPoiId = ref('')
    const initialCategory = ref(null)

    onMounted(() => {
      if (route.query.poiTitle) initialTitle.value = String(route.query.poiTitle)
      if (route.query.poiId) initialPoiId.value = String(route.query.poiId)
      if (route.query.category) initialCategory.value = String(route.query.category)
    })

    function onCreated(){
      router.push('/community')
    }

    return { initialTitle, initialPoiId, initialCategory, onCreated }
  }
}
</script>

<style scoped>
.muted { color:#64748b; margin:0; }
.btn.ghost { background:transparent; border:1px solid rgba(11,17,34,0.06); padding:8px 12px; border-radius:8px; cursor:pointer; }
</style>