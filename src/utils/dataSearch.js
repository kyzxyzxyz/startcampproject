// src/utils/dataSearch.js
const BASENAMES = [
  '구미_경북권_관광지.json',
  '구미_경북권_음식점.json',
  '구미_경북권_축제공연행사.json',
  '구미_경북권_문화시설.json',
  '구미_경북권_레포츠.json',
  '구미_경북권_숙박.json',
  '구미_경북권_여행코스.json',
  '구미_경북권_쇼핑.json'
];

async function fetchEither(name) {
  // 먼저 루트 경로 시도, 실패하면 /data/ 시도
  const paths = [`/${name}`, `/data/${name}`];
  for (const p of paths) {
    try {
      const r = await fetch(p);
      if (r && r.ok) {
        const j = await r.json();
        return j;
      }
    } catch (e) { /* ignore and try next */ }
  }
  return { items: [] };
}

export async function loadAllData() {
  const results = await Promise.all(BASENAMES.map(n => fetchEither(n)));
  const merged = results.flatMap(r => r.items || []);
  return merged;
}

export function simpleRank(query, items, topN = 5) {
  const q = (query || '').toLowerCase().trim();
  if (!q) return [];
  const qwords = q.split(/\s+/).filter(Boolean);

  const scored = items.map(it => {
    const fields = [
      it.title || it.name || '',
      it.addr1 || it.addr || '',
      it.cat1 || '',
      it.cat2 || '',
      it.cat3 || '',
      it.lclsSystm1 || it.lclsSystm2 || it.lclsSystm3 || '',
      it.overview || it.description || ''
    ];
    const text = fields.join(' ').toLowerCase();
    let score = 0;
    if (text.includes(q)) score += 20;
    for (const w of qwords) {
      if (text.includes(w)) score += 3;
    }
    // 가중치: 제목 일치 우대
    const title = (it.title || it.name || '').toLowerCase();
    if (title.includes(q)) score += 10;
    return { it, score };
  }).filter(x => x.score > 0).sort((a, b) => b.score - a.score);

  return scored.slice(0, topN).map(s => s.it);
}