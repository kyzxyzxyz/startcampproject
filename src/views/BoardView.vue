<template>
  <div class="page card">
    <div style="display:flex;justify-content:space-between;align-items:center;">
      <div>
        <h2>{{ $t('app.createPostTitle') }}</h2>
        <p class="muted">{{ $t('app.boardWriteHint') }}</p>
      </div>
      <div>
        <BaseButton variant="ghost" @click="$router.push('/community')">{{ $t('app.backToCommunity') }}</BaseButton>
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
import BaseButton from '../components/BaseButton.vue'

export default {
  components: { BoardEditor, BaseButton },
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
</style>