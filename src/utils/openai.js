// src/utils/openai.js
export async function callOpenAI(messages, model = 'gpt-5-mini') {
  // const key = import.meta.env.VITE_OPENAI_KEY;
  const key = import.meta.env.VITE_OPENAI_API_KEY;
  if (!key) throw new Error('VITE_OPENAI_KEY not set');

  const useNewParam = /^(gpt-5|gpt-4o)/i.test(model);
  const payload = { model, messages };

  if (useNewParam) {
    payload.max_completion_tokens = 800;
  } else {
    payload.max_tokens = 800;
    payload.temperature = 0.2;
  }

  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${key}`
    },
    body: JSON.stringify(payload)
  });

  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`${res.status} ${txt}`);
  }

  const data = await res.json();
  const content = data.choices?.[0]?.message?.content || '';
  return content;
}