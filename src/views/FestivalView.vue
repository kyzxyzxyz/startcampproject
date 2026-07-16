<template>
  <div class="page">
    <div class="page-header">
      <h2>{{ $t('app.festivalCalendar') }}</h2>
      <router-link to="/" class="back-link">{{ $t('app.goHome') }}</router-link>
    </div>

    <FestivalCalendar :view-mode="'month'" :show-date-controls="true" />
  </div>
</template>

<script>
import FestivalCalendar from '../components/FestivalCalendar.vue'

export default {
  components: { FestivalCalendar }
}
</script>

<style scoped>
.page {
  padding: 12px;
  max-width: 1100px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin: 16px 0;
}

.back-link {
  color: #2563eb;
  text-decoration: none;
  font-weight: 600;
}
</style>