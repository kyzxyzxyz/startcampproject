/*
 실행: npm run extract-manifest
 목적: public/data/ 내부 제공 JSON 파일들의 최신 modifiedtime을 추출해 public/data_manifest.json 생성
*/
import fs from 'fs'
const files = [
  'public/data/구미_경북권_관광지.json',
  'public/data/구미_경북권_레포츠.json',
  'public/data/구미_경북권_문화시설.json',
  'public/data/구미_경북권_쇼핑.json',
  'public/data/구미_경북권_숙박.json',
  'public/data/구미_경북권_여행코스.json',
  'public/data/구미_경북권_음식점.json',
  'public/data/구미_경북권_축제공연행사.json'
];

const manifest = [];

for(const f of files) {
  if (!fs.existsSync(f)) { console.warn(`${f} not found`); continue; }
  const obj = JSON.parse(fs.readFileSync(f,'utf8'));
  const times = (obj.items || []).map(it => it.modifiedtime || it.createdtime).filter(Boolean);
  const latest = times.length ? times.sort().pop() : null;
  manifest.push({
    file: f.replace('public/',''),
    contentType: obj.contentType || null,
    contentTypeId: obj.contentTypeId || null,
    total: obj.total || (obj.items || []).length,
    license: '공공누리 제3유형 (한국관광공사 Tour API)',
    source: '한국관광공사 Tour API v4 (https://www.data.go.kr/data/15101578/openapi.do)',
    latestModifiedTime: latest
  })
}

fs.writeFileSync('public/data_manifest.json', JSON.stringify(manifest, null, 2))
console.log('wrote public/data_manifest.json')
