'use strict';
fetch('config.json').then(response => {
  if (!response.ok) throw new Error('Configuration unavailable');
  return response.json();
}).then(config => {
  if (!config.endpoint) return;
  const url = new URL(config.endpoint);
  if (url.protocol !== 'https:' || !url.pathname.endsWith('/mcp') || url.username || url.password) return;
  document.getElementById('endpoint').textContent = url.href;
  document.getElementById('connect-status').textContent = `Connect using Streamable HTTP at ${url.href}. Configure authentication according to your deployment.`;
}).catch(() => { /* Keep the honest pending-deployment fallback. */ });
