// netlify/functions/openai-proxy.js
const fetch = global.fetch || require('node-fetch');

exports.handler = async function(event) {
  try {
    const body = event.body ? JSON.parse(event.body) : {};
    const messages = body.messages;
    const model = body.model || 'gpt-5-mini';
    if (!messages) return { statusCode: 400, body: JSON.stringify({ error: 'messages required' }) };

    const key = process.env.OPENAI_API_KEY;
    if (!key) return { statusCode: 500, body: JSON.stringify({ error: 'OPENAI_API_KEY not set' }) };

    // 신형 모델 패턴: max_completion_tokens 사용, temperature 제한(기본값 사용)
    const useNewParam = /^(gpt-5|gpt-4o)/i.test(model);

    const payload = { model, messages };

    if (useNewParam) {
      payload.max_completion_tokens = 800;
      // 신형 모델에서는 temperature를 명시하지 않아 기본값(서버측 기본)을 사용
    } else {
      payload.max_tokens = 800;
      payload.temperature = 0.2;
    }

    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${key}` },
      body: JSON.stringify(payload)
    });

    const text = await resp.text();
    if (!resp.ok) {
      return { statusCode: resp.status, headers: { 'Content-Type': 'application/json' }, body: text };
    }

    return { statusCode: 200, headers: { 'Content-Type': 'application/json' }, body: text };
  } catch (err) {
    return { statusCode: 500, body: JSON.stringify({ error: err.message || String(err) }) };
  }
}