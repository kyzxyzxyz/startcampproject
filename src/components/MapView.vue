<template>
  <div>
    <div class="map-controls">
      <button
        :class="{active: activeType === null}"
        @click="showAll"
        class="all-btn">전체</button>

      <button
        v-for="type in types"
        :key="type"
        :class="{active: activeType === type}"
        :style="buttonStyle(type)"
        @click="selectType(type)">
        {{ t(typeLabelMap[type] ?? type) }}
      </button>
    </div>

    <div class="map-container card">
      <div ref="mapEl" class="map"></div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import L from 'leaflet'
import 'leaflet.markercluster'
import 'leaflet.markercluster/dist/MarkerCluster.css'
import 'leaflet.markercluster/dist/MarkerCluster.Default.css'
import { useI18n } from 'vue-i18n'

export default {
  setup() {
    const { t } = useI18n()
    const mapEl = ref(null)
    let map = null

    const layerGroups = {}
    const markerIndex = {} // contentid -> marker
    const types = ref([])
    const activeType = ref(null)

    const typeLabelMap = {
      '관광지': 'categories.tourist',
      '음식점': 'categories.food',
      '쇼핑': 'categories.shopping',
      '레포츠': 'categories.sports',
      '문화시설': 'categories.culture',
      '숙박': 'categories.lodging',
      '여행코스': 'categories.course',
      '축제공연행사': 'categories.festival',
      '기타': 'app.list'
    }

    const contentTypeNames = {
      '12': '관광지','14': '문화시설','15': '축제/공연/행사','25': '여행코스',
      '28': '레포츠','32': '숙박','38': '쇼핑','39': '음식점'
    }

    const palette = ['#ef4444','#f97316','#f59e0b','#10b981','#06b6d4','#3b82f6','#7c3aed','#ec4899','#8b5cf6','#64748b']
    const colorMap = {}
    let paletteIndex = 0
    function getColorForType(typeName){
      if (!typeName) return '#2563eb'
      if (colorMap[typeName]) return colorMap[typeName]
      colorMap[typeName] = palette[paletteIndex % palette.length]
      paletteIndex += 1
      return colorMap[typeName]
    }

    function buttonStyle(typeName) {
      const color = getColorForType(typeName)
      const isActive = activeType.value === typeName
      if (activeType.value === null) {
        return {
          background: color,
          color: '#fff',
          borderColor: color
        }
      } else if (isActive) {
        return {
          background: color,
          color: '#fff',
          borderColor: color
        }
      } else {
        return {
          background: '#f3f4f6',
          color: '#64748b',
          borderColor: 'rgba(11,17,34,0.06)'
        }
      }
    }

    function toFloat(v){ const n = parseFloat(v); return Number.isFinite(n) ? n : null }

    async function loadFiles() {
      const files = [
        '/data/구미_경북권_관광지.json',
        '/data/구미_경북권_음식점.json',
        '/data/구미_경북권_축제공연행사.json',
        '/data/구미_경북권_문화시설.json',
        '/data/구미_경북권_레포츠.json',
        '/data/구미_경북권_숙박.json',
        '/data/구미_경북권_여행코스.json',
        '/data/구미_경북권_쇼핑.json'
      ]
      const results = await Promise.all(files.map(async (f) => {
        try {
          const r = await fetch(f)
          if (!r.ok) return null
          const j = await r.json()
          return { items: j.items || [], contentType: j.contentType || null }
        } catch (e) {
          return null
        }
      }))
      return results.filter(Boolean)
    }

    function escapeHtml(str){
      return String(str || '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;')
    }

    function getClassification(it){
      const ctid = String(it.contenttypeid || it.contentTypeId || '')
      const pick = (fields) => {
        for (const f of fields) {
          if (it[f] && String(it[f]).trim()) return String(it[f]).trim()
        }
        return ''
      }

      if (ctid === '39') {
        const sub = pick(['cat3','lclsSystm3','cat2','lclsSystm2','cat1','lclsSystm1'])
        if (sub) return sub
        return contentTypeNames[ctid] || '음식점'
      }

      if (ctid && contentTypeNames[ctid]) return contentTypeNames[ctid]
      const cats = []
      if (it.cat1) cats.push(it.cat1)
      if (it.cat2) cats.push(it.cat2)
      if (it.cat3) cats.push(it.cat3)
      if (cats.length) return cats.join(' / ')
      const lcls = pick(['lclsSystm3','lclsSystm2','lclsSystm1'])
      if (lcls) return lcls
      return ''
    }

    function createTeardropIcon(color){
      const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="28" height="36" viewBox="0 0 28 36"><path d="M14 2 C9 2 4 7 4 12 C4 18 14 30 14 30 C14 30 24 18 24 12 C24 7 19 2 14 2 Z" fill="${color}" /></svg>`
      const url = 'data:image/svg+xml;utf8,' + encodeURIComponent(svg)
      return L.icon({ iconUrl: url, iconSize: [28,36], iconAnchor: [14,30], popupAnchor: [0,-28] })
    }

    function addMarkersForType(typeName, items){
      const clusterOptions = {
        chunkedLoading: true,
        showCoverageOnHover: false,
        spiderfyOnMaxZoom: true,
        disableClusteringAtZoom: 16
      }
      const mg = L.markerClusterGroup(clusterOptions)
      const points = []
      const color = getColorForType(typeName)
      const icon = createTeardropIcon(color)

      items.forEach(it => {
        const lon = toFloat(it.mapx)
        const lat = toFloat(it.mapy)
        if (!(lat && lon)) return

        const marker = L.marker([lat, lon], { icon })
        const title = it.title || '무명'
        const addr = it.addr1 || ''
        const poiId = it.contentid || ''
        const bodyText = (it.overview || it.description || '').trim()
        const tel = it.tel || ''
        const img = it.firstimage || it.firstimage2 || ''
        const classification = escapeHtml(getClassification(it))
        const localizedTitle = escapeHtml(title)

        const imgHtml = img ? `<div class="poi-image" style="margin-top:8px;text-align:center;"><img src="${escapeHtml(img)}" style="max-width:100%;max-height:140px;border-radius:6px;object-fit:cover;" alt="${escapeHtml(title)}"/></div>` : ''

        const bodyHtml = bodyText ? `
  <div class="poi-body" style="min-height:60px; max-height:160px; overflow:auto; font-size:13px; color:#334155; padding:8px; border-radius:6px; background:#fbfdff; border:1px solid rgba(11,17,34,0.03); margin-top:8px;">
    ${escapeHtml(bodyText)}
  </div>
` : ''

        const popupHtml = `
<div class="poi-popup" style="font-family:inherit; color:#0b1220; display:flex; flex-direction:column; gap:6px; padding:8px; max-width:360px;">
  <div class="poi-top" style="display:flex; flex-direction:column; gap:4px;">
    <a href="#" class="plain-link" data-poi-id="${poiId}" data-poi-title="${localizedTitle}" data-poi-category="${escapeHtml(typeName)}"
       style="background:transparent;border:none;color:#2563eb;font-weight:600;cursor:pointer;padding:0;text-align:left;font-size:15px;text-decoration:none;display:inline-block;">
      ${escapeHtml(title)}
    </a>
    ${classification ? `<div class="poi-class" style="font-size:13px;color:#475569;">${classification}</div>` : ''}
    ${addr ? `<div class="poi-addr" style="font-size:13px;color:#64748b;line-height:1.3;">${escapeHtml(addr)}</div>` : ''}
    ${tel ? `<div class="poi-tel" style="font-size:13px;color:#0b1220;margin-top:4px;">☎ ${escapeHtml(tel)}</div>` : ''}
    ${imgHtml}
  </div>
  ${bodyHtml}
</div>`.trim()

        marker.bindPopup(popupHtml, { minWidth: 260, maxWidth: 360, autoPan: false })

        marker.on('popupopen', (e) => {
          try {
            const popupEl = (e.popup && typeof e.popup.getElement === 'function') ? e.popup.getElement() : (e.popup && e.popup._contentNode) || null
            if (popupEl) {
              const titleLink = popupEl.querySelector('.plain-link')
              if (titleLink) {
                titleLink.onclick = (ev) => {
                  ev.preventDefault()
                  const poiIdAttr = titleLink.getAttribute('data-poi-id') || ''
                  const poiTitleAttr = titleLink.getAttribute('data-poi-title') || ''
                  const poiCategoryAttr = titleLink.getAttribute('data-poi-category') || ''
                  window.dispatchEvent(new CustomEvent('open-community', { detail: { poiId: poiIdAttr, poiTitle: poiTitleAttr, poiCategory: poiCategoryAttr } }))
                }
              }
            }
          } catch (err) { /* ignore */ }
        })

        // 클릭 시 마커가 맵 컨테이너 중앙에 오도록 처리
        marker.on('click', () => {
          try {
            if (!map) return
            const latlng = marker.getLatLng()
            map.setView([latlng.lat+0.005, latlng.lng], Math.max(map.getZoom(), 15), { animate: true })
          } catch (e) {}
        })

        // 인덱스에 저장 (contentid 기반)
        if (poiId) {
          try { markerIndex[String(poiId)] = marker } catch (e) {}
        }

        mg.addLayer(marker)
        points.push([lat, lon])
      })

      layerGroups[typeName] = { layer: mg, points }
    }

    function clearLayersFromMap() {
      Object.values(layerGroups).forEach(obj => {
        try { obj.layer.remove() } catch (e) {}
      })
    }

    function applyVisibleLayers() {
      clearLayersFromMap()
      if (activeType.value === null) {
        Object.values(layerGroups).forEach(obj => obj.layer.addTo(map))
      } else {
        const obj = layerGroups[activeType.value]
        if (obj) obj.layer.addTo(map)
      }
    }

    function selectType(t) {
      if (activeType.value === t) activeType.value = null
      else activeType.value = t
      applyVisibleLayers()
    }

    function showAll() {
      activeType.value = null
      applyVisibleLayers()
    }

    function ensureGroupVisibleForMarker(marker) {
      try {
        for (const key of Object.keys(layerGroups)) {
          const g = layerGroups[key]
          if (g && g.layer && typeof g.layer.hasLayer === 'function' && g.layer.hasLayer(marker)) {
            if (!map.hasLayer(g.layer)) g.layer.addTo(map)
            return
          }
        }
      } catch (e) {}
    }

    function handleGotoPoi(ev) {
      const d = ev?.detail || {}
      if (!map) return
      // 좌표가 있으면 이동 후 팝업 열기 시도
      if (d.lat && d.lon) {
        const lat = Number(d.lat), lon = Number(d.lon)
        if (!Number.isFinite(lat) || !Number.isFinite(lon)) return
        map.setView([lat, lon], 15, { animate: true })
        // raw에 contentid 있으면 해당 마커 팝업 열기
        const cid = d.raw && (d.raw.contentid || d.raw.contentId) ? String(d.raw.contentid || d.raw.contentId) : null
        if (cid && markerIndex[cid]) {
          const m = markerIndex[cid]
          ensureGroupVisibleForMarker(m)
          try { m.openPopup() } catch (e) {}
        }
        return
      }
      // contentid만 있는 경우
      if (d.raw && (d.raw.contentid || d.raw.contentId)) {
        const cid = String(d.raw.contentid || d.raw.contentId)
        const m = markerIndex[cid]
        if (m) {
          ensureGroupVisibleForMarker(m)
          try {
            const latlng = m.getLatLng()
            map.setView(latlng, 15, { animate: true })
            m.openPopup()
          } catch (e) {}
        }
        return
      }
      // postId가 있는 경우는 게시글 열기 이벤트로 위임
      if (d.postId) {
        try { window.dispatchEvent(new CustomEvent('open-post', { detail: { id: d.postId } })) } catch(e){}
        return
      }
    }

    onMounted(async () => {
      map = L.map(mapEl.value, { center: [36.11, 128.34], zoom: 11, preferCanvas: true })
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors'
      }).addTo(map)

      const files = await loadFiles()

      // 먼저 고유 타입 목록 구성 및 색 매핑을 예약
      const discovered = []
      files.forEach(f => {
        const typeName = f.contentType || '기타'
        if (!discovered.includes(typeName)) discovered.push(typeName)
      })
      types.value = discovered
      // 사전 색 할당(버튼/핀 동일 색 보장)
      discovered.forEach(tn => getColorForType(tn))

      // 마커 추가
      files.forEach(f => {
        const typeName = f.contentType || '기타'
        addMarkersForType(typeName, f.items)
      })

      applyVisibleLayers()

      // 검색 모달 등에서 발행하는 goto-poi 이벤트 처리
      window.addEventListener('goto-poi', handleGotoPoi)
    })

    onBeforeUnmount(() => {
      if (map) map.remove()
      try { window.removeEventListener('goto-poi', handleGotoPoi) } catch(e){}
    })

    return { mapEl, types, activeType, selectType, showAll, t, typeLabelMap, buttonStyle }
  }
}
</script>

<style scoped>
.map-controls { display:flex; gap:8px; flex-wrap:wrap; margin-bottom:12px; }
.map-controls button { padding:8px 10px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); font-weight:600; cursor:pointer; }
.map-controls button.all-btn { background:#fff; color:#0f172a; border-color: rgba(11,17,34,0.06); }
.map-controls button.active { box-shadow:0 6px 18px rgba(15,99,254,0.08); }
.map-container { width:100%; }
.map { width:100%; height:520px; border-radius:10px; overflow:hidden; border:1px solid rgba(11,17,34,0.04); position:relative; z-index:0; }
</style>