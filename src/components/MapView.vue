<template>
  <div>
    <div class="map-controls">
      <button class="control-btn" :class="{ active: activeType === null }" @click="showAll">
        {{ t('board.all') }}
      </button>

      <button
        v-for="type in types"
        :key="type"
        class="control-btn"
        :class="{ active: activeType === type }"
        :style="buttonStyle(type)"
        @click="selectType(type)"
      >
        {{ t(typeLabelMap[type] ?? findLabelKey(type) ?? type) }}
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

    const defaultPoiZoom = 15
    const zoomStepOnClick = 2

    const classifications = {}
    const layerGroups = {}
    const normalizedMap = {}
    const markerIndex = {}
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
      '축제/공연/행사': 'categories.festival',
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
        return { background: color, color: '#fff', borderColor: color }
      } else if (isActive) {
        return { background: color, color: '#fff', borderColor: color }
      } else {
        return { background: '#f3f4f6', color: '#64748b', borderColor: 'rgba(11,17,34,0.06)' }
      }
    }

    function toFloat(v){ const n = parseFloat(v); return Number.isFinite(n) ? n : null }

    async function loadFiles() {
      const files = [
        '/구미_경북권_관광지.json',
        '/구미_경북권_음식점.json',
        '/구미_경북권_축제공연행사.json',
        '/구미_경북권_문화시설.json',
        '/구미_경북권_레포츠.json',
        '/구미_경북권_숙박.json',
        '/구미_경북권_여행코스.json',
        '/구미_경북권_쇼핑.json'
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

    async function loadClassifications() {
      try {
        const r = await fetch('/data/classifications.json')
        if (!r.ok) return
        const j = await r.json()
        Object.assign(classifications, j)
      } catch (e) { /* ignore */ }
    }

    function escapeHtml(str){
      return String(str || '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;')
    }

    function normalizeTypeName(s) {
      try {
        return String(s || '').normalize().replace(/[\s\/\\　]+/g, '').trim()
      } catch (e) {
        return String(s || '').replace(/[\s\/\\　]+/g, '').trim()
      }
    }

    function findLabelKey(type) {
      if (!type) return null
      try {
        const norm = normalizeTypeName(type)
        for (const k of Object.keys(typeLabelMap)) {
          if (normalizeTypeName(k) === norm) return typeLabelMap[k]
        }
      } catch (e) {}
      return null
    }

    function getClassification(it){
      const ctid = String(it.contenttypeid || it.contentTypeId || '1')
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
        const localizedTitle = escapeHtml(title)

        const subCode = (it.lclsSystm3 || it.lclsSystm3 || '').toString().trim()
        const subLabel = (subCode && classifications.sub) ? (classifications.sub[subCode] || '') : ''
        const subHtml = subCode ? `<div class="poi-subcat" style="font-size:13px;color:#475569;margin-top:4px;">${escapeHtml(subLabel || subCode)}</div>` : ''

        const imgHtml = img ? `<div class="poi-image" style="margin-top:8px;text-align:center;"><img src="${escapeHtml(img)}" style="max-width:100%;max-height:140px;border-radius:6px;object-fit:cover;" alt="${escapeHtml(title)}"/></div>` : ''

        const bodyHtml = bodyText ? `
          <div class="poi-body">
            ${escapeHtml(bodyText)}
          </div>
        ` : ''

        const darkPopupStyle = 'background:#1e1e24;color:#f1f3f5;border:1px solid rgba(255,255,255,0.06);box-shadow:0 8px 30px rgba(2,6,23,0.6);border-radius:8px;padding:10px;';
        const darkAddrStyle = 'color:#9aa0a6;';
        const darkLinkColor = '#60a5fa';

        const popupHtml = `
          <div class="poi-popup" style="${darkPopupStyle}">
            <div class="poi-top">
              <a href="#" class="plain-link" data-poi-id="${poiId}" data-poi-title="${localizedTitle}" data-poi-category="${escapeHtml(typeName)}" style="color:${darkLinkColor};font-weight:600;text-decoration:none;">
                ${escapeHtml(title)}
              </a>
              ${subHtml}
              ${addr ? `<div class="poi-addr" style="${darkAddrStyle}">${escapeHtml(addr)}</div>` : ''}
              ${tel ? `<div class="poi-tel" style="color:#f1f3f5;margin-top:4px;">☎ ${escapeHtml(tel)}</div>` : ''}
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

        marker.on('click', () => {
          try {
            if (!map) return
            const latlng = marker.getLatLng()
            const currentZoom = map.getZoom()
            const targetZoom = currentZoom > defaultPoiZoom
              ? Math.max(currentZoom - zoomStepOnClick, defaultPoiZoom)
              : Math.max(currentZoom, defaultPoiZoom)

            map.panTo([latlng.lat + 0.005, latlng.lng], { animate: true })
            const onceCb = () => {
              try { map.setZoom(targetZoom, { animate: true }) } catch(e){}
            }
            map.once('moveend', onceCb)
          } catch (e) {}
        })

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

    function fitToPoints(pointsArr) {
      if (!map || !pointsArr || !pointsArr.length) return
      try {
        const bounds = L.latLngBounds(pointsArr)
        map.fitBounds(bounds, { padding: [60, 60], maxZoom: defaultPoiZoom })
      } catch (e) {}
    }

    function applyVisibleLayers() {
      if (!map) return
      if (!Object.keys(layerGroups).length) return

      clearLayersFromMap()

      if (activeType.value === null) {
        // show all
        const allPoints = []
        Object.values(layerGroups).forEach(obj => {
          obj.layer.addTo(map)
          if (Array.isArray(obj.points) && obj.points.length) {
            obj.points.forEach(p => allPoints.push(p))
          }
        })
        // fit to all if there are points
        if (allPoints.length) fitToPoints(allPoints)
        return
      }

      // try direct key first, then normalized lookup
      const direct = layerGroups[activeType.value]
      if (direct) {
        direct.layer.addTo(map)
        if (Array.isArray(direct.points) && direct.points.length) {
          fitToPoints(direct.points)
        }
        return
      }
      const norm = normalizeTypeName(activeType.value)
      const foundKey = normalizedMap[norm]
      if (foundKey && layerGroups[foundKey]) {
        const obj = layerGroups[foundKey]
        obj.layer.addTo(map)
        if (Array.isArray(obj.points) && obj.points.length) {
          fitToPoints(obj.points)
        }
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

    function selectTypeByName(typeName) {
      if (typeName === null) {
        showAll()
        return
      }
      const norm = normalizeTypeName(typeName)
      const direct = layerGroups[typeName]
      if (direct) {
        activeType.value = typeName
        applyVisibleLayers()
        return
      }
      const mapped = normalizedMap[norm]
      if (mapped) {
        activeType.value = mapped
      } else {
        const found = types.value.find(x => normalizeTypeName(x) === norm)
        activeType.value = found ?? null
      }
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
      if (d.lat && d.lon) {
        const lat = Number(d.lat), lon = Number(d.lon)
        if (!Number.isFinite(lat) || !Number.isFinite(lon)) return

        map.panTo([lat, lon], { animate: true })
        map.once('moveend', () => {
          try { map.setZoom(defaultPoiZoom, { animate: true }) } catch(e){}
          const cid = d.raw && (d.raw.contentid || d.raw.contentId) ? String(d.raw.contentid || d.raw.contentId) : null
          if (cid && markerIndex[cid]) {
            const m = markerIndex[cid]
            ensureGroupVisibleForMarker(m)
            try { m.openPopup() } catch (e) {}
          }
        })
        return
      }
      if (d.raw && (d.raw.contentid || d.raw.contentId)) {
        const cid = String(d.raw.contentid || d.raw.contentId)
        const m = markerIndex[cid]
        if (m) {
          ensureGroupVisibleForMarker(m)
          try {
            const latlng = m.getLatLng()
            map.panTo(latlng, { animate: true })
            map.once('moveend', () => {
              try { map.setZoom(defaultPoiZoom, { animate: true }) } catch(e){}
              try { m.openPopup() } catch (e) {}
            })
          } catch (e) {}
        }
        return
      }
      if (d.postId) {
        try { window.dispatchEvent(new CustomEvent('open-post', { detail: { id: d.postId } })) } catch(e){}
        return
      }
    }

    function handleSelectMapType(ev) {
      const requested = ev?.detail?.type ?? null
      if (!map) return
      if (requested === null) {
        showAll()
        return
      }
      selectTypeByName(requested)
    }

    onMounted(async () => {
      map = L.map(mapEl.value, { center: [36.11, 128.34], zoom: 11, preferCanvas: true })
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors'
      }).addTo(map)

      await loadClassifications()
      const files = await loadFiles()

      const discovered = []
      files.forEach(f => {
        const typeName = f.contentType || '기타'
        if (!discovered.includes(typeName)) discovered.push(typeName)
      })

      types.value = discovered

      discovered.forEach(tn => {
        const n = normalizeTypeName(tn)
        normalizedMap[n] = tn
        getColorForType(tn)
      })

      files.forEach(f => {
        const typeName = f.contentType || '기타'
        addMarkersForType(typeName, f.items)
      })

      applyVisibleLayers()
      window.addEventListener('goto-poi', handleGotoPoi)
      window.addEventListener('select-map-type', handleSelectMapType)
    })

    onBeforeUnmount(() => {
      if (map) map.remove()
      try { window.removeEventListener('goto-poi', handleGotoPoi) } catch(e){}
      try { window.removeEventListener('select-map-type', handleSelectMapType) } catch(e){}
    })

    return { mapEl, types, activeType, selectType, showAll, t, typeLabelMap, buttonStyle, selectTypeByName, findLabelKey }
  }
}
</script>

<style scoped>
.map-controls { display:flex; gap:8px; flex-wrap:wrap; margin-bottom:12px; }
.control-btn {
  padding:8px 10px;
  border-radius:8px;
  border:1px solid rgba(11,17,34,0.06);
  font-weight:600;
  cursor:pointer;
  background: #f3f4f6;
  color: #0b1220;
  transition: all .12s ease;
}
.control-btn.active {
  box-shadow:0 6px 18px rgba(15,99,254,0.08);
  color: #fff;
}
.map-container { width:100%; }
.map { width:100%; height:520px; border-radius:10px; overflow:hidden; border:1px solid rgba(11,17,34,0.04); position:relative; z-index:0; }
</style>