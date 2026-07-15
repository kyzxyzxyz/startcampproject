<template>
  <div class="festival-calendar">
    <div v-if="showDateControls" class="calendar-toolbar">
      <BaseButton variant="ghost" size="sm" class="nav-btn" @click="goPrev">
        {{ isMonthView ? '◀ 이전달' : '◀ 전주' }}
      </BaseButton>

      <div class="calendar-title">{{ currentLabel }}</div>

      <BaseButton variant="ghost" size="sm" class="nav-btn" @click="goNext">
        {{ isMonthView ? '다음달 ▶' : '다음주 ▶' }}
      </BaseButton>
    </div>

    <div v-if="isMonthView" class="month-grid">
      <div
        v-for="day in monthDays"
        :key="day.key"
        class="day-card"
        :class="{ 'other-month': !day.inCurrentMonth }"
      >
        <div class="day-top">
          <div class="day-name">{{ day.name }}</div>
          <div class="day-number">{{ day.number }}</div>
        </div>

        <div class="day-events">
          <div
            v-for="event in day.events"
            :key="event.id"
            class="event-chip"
            :style="{ background: event.colorBg, color: event.colorText }"
            :title="event.title"
          >
            {{ event.title }}
          </div>
          <div v-if="day.events.length === 0" class="empty">행사 없음</div>
        </div>
      </div>
    </div>

    <div v-else class="week-grid">
      <div
        v-for="day in weekDays"
        :key="day.key"
        class="day-card"
      >
        <div class="day-top">
          <div class="day-name">{{ day.name }}</div>
          <div class="day-number">{{ day.number }}</div>
        </div>

        <div class="day-events">
          <div
            v-for="event in day.events"
            :key="event.id"
            class="event-chip"
            :style="{ background: event.colorBg, color: event.colorText }"
          >
            {{ event.title }}
          </div>
          <div v-if="day.events.length === 0" class="empty">행사 없음</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import BaseButton from './BaseButton.vue'

function ymdFromTourTime(ts) {
  if (!ts || typeof ts !== 'string') return null
  if (ts.length < 8) return null
  return `${ts.slice(0, 4)}-${ts.slice(4, 6)}-${ts.slice(6, 8)}`
}

function formatDate(d) {
  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function hashStringToInt(str) {
  let h = 2166136261 >>> 0
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i)
    h = Math.imul(h, 16777619) >>> 0
  }
  return h
}

function colorFromString(str) {
  const h = hashStringToInt(str) % 360
  const s = 40 + (hashStringToInt(str + 's') % 25)
  const l = 74 + (hashStringToInt(str + 'l') % 11)
  return `hsl(${h}, ${s}%, ${l}%)`
}

function readableTextColor(bg) {
  const m = bg.match(/hsl\(\s*([0-9]+)\s*,\s*([0-9]+)%\s*,\s*([0-9]+)%\s*\)/i)
  if (m && m[3]) {
    const l = Number(m[3])
    return l >= 70 ? '#0f172a' : '#ffffff'
  }
  return '#0f172a'
}

export default {
  name: 'FestivalCalendar',
  components: { BaseButton },
  props: {
    compact: { type: Boolean, default: false },
    showDateControls: { type: Boolean, default: false },
    viewMode: { type: String, default: 'week' }
  },
  setup(props) {
    const events = ref([])
    const currentDate = ref(new Date())

    const isMonthView = computed(() => {
      try {
        if (props.viewMode === 'month') return true
        if (typeof window !== 'undefined' && window.location && window.location.pathname) {
          return window.location.pathname.indexOf('/festivals') !== -1
        }
      } catch (e) {}
      return false
    })

    const currentLabel = computed(() => {
      const d = new Date(currentDate.value)
      return `${d.getFullYear()}년 ${d.getMonth() + 1}월`
    })

    const weekDays = computed(() => {
      const base = new Date(currentDate.value)
      const start = new Date(base)
      const dayOfWeek = start.getDay()
      start.setDate(base.getDate() - dayOfWeek)

      const result = []
      for (let i = 0; i < 7; i++) {
        const d = new Date(start)
        d.setDate(start.getDate() + i)

        const key = formatDate(d)
        const dayEvents = events.value.filter((ev) => ev.start === key)

        result.push({
          key,
          name: ['일', '월', '화', '수', '목', '금', '토'][d.getDay()],
          number: d.getDate(),
          events: dayEvents
        })
      }

      return result
    })

    const monthDays = computed(() => {
      const year = currentDate.value.getFullYear()
      const month = currentDate.value.getMonth()

      const firstDay = new Date(year, month, 1)
      const lastDay = new Date(year, month + 1, 0)

      const startWeekDay = firstDay.getDay()
      const totalCells = Math.ceil((startWeekDay + lastDay.getDate()) / 7) * 7

      const result = []

      for (let i = 0; i < totalCells; i++) {
        const d = new Date(firstDay)
        d.setDate(firstDay.getDate() - startWeekDay + i)

        const key = formatDate(d)
        const dayEvents = events.value.filter((ev) => ev.start === key)

        result.push({
          key,
          name: ['일', '월', '화', '수', '목', '금', '토'][d.getDay()],
          number: d.getDate(),
          events: dayEvents,
          inCurrentMonth: d.getMonth() === month
        })
      }

      return result
    })

    function goPrev() {
      const d = new Date(currentDate.value)
      if (isMonthView.value) {
        d.setMonth(d.getMonth() - 1)
      } else {
        d.setDate(d.getDate() - 7)
      }
      currentDate.value = d
    }

    function goNext() {
      const d = new Date(currentDate.value)
      if (isMonthView.value) {
        d.setMonth(d.getMonth() + 1)
      } else {
        d.setDate(d.getDate() + 7)
      }
      currentDate.value = d
    }

    async function loadFestivals() {
      try {
        const res = await fetch('/구미_경북권_축제공연행사.json')
        if (!res.ok) throw new Error('fetch failed: ' + res.status)

        const json = await res.json()
        const items = Array.isArray(json.items) ? json.items : []

        events.value = items
          .map((it) => {
            const start = ymdFromTourTime(it.modifiedtime) || ymdFromTourTime(it.createdtime)
            if (!start) return null
            const keyForColor = `${it.contentid || ''}::${it.title || ''}`
            const bg = colorFromString(keyForColor)
            const text = readableTextColor(bg)
            return {
              id: it.contentid || (it.title || Math.random()).toString(),
              title: it.title || '축제',
              start,
              colorBg: bg,
              colorText: text
            }
          })
          .filter(Boolean)
      } catch (e) {
        console.error('[FestivalCalendar] load error:', e)
      }
    }

    onMounted(() => {
      loadFestivals()
    })

    return {
      weekDays,
      monthDays,
      currentLabel,
      showDateControls: props.showDateControls,
      isMonthView,
      goPrev,
      goNext
    }
  }
}
</script>

<style scoped>
.festival-calendar {
  width: 100%;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 12px;
  box-sizing: border-box;
}

/* toolbar */
.calendar-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 10px;
}

.calendar-title {
  font-weight: 700;
  color: #334155;
  font-size: 14px;
}

/* grids */
.week-grid,
.month-grid {
  display: grid;
  gap: 8px;
}

.week-grid {
  grid-template-columns: repeat(7, 1fr);
}

.month-grid {
  grid-template-columns: repeat(7, 1fr);
  grid-auto-rows: 150px;
}

.day-card {
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 8px;
  box-sizing: border-box;
  background: #fbfdff;
  display: flex;
  flex-direction: column;
  gap: 8px;
  height: 100%;
  overflow: hidden;
}

.day-card.other-month { opacity:0.55; }

.day-top { display:flex; justify-content:space-between; align-items:baseline; gap:8px; }
.day-name { font-size:12px; color:#64748b; font-weight:700; }
.day-number { font-size:16px; font-weight:700; color:#0f172a; }

.day-events { margin-top:0; display:flex; flex-direction:column; gap:6px; overflow-y:auto; padding-right:4px; }
.event-chip { font-size:12px; border-radius:6px; padding:6px 8px; line-height:1.2; white-space:normal; word-break:break-word; overflow:visible; text-overflow:clip; box-shadow: 0 1px 0 rgba(15,17,26,0.04) inset; }
.empty { font-size:11px; color:#94a3b8; }
.nav-btn { padding:6px 8px; border-radius:8px; }
</style>