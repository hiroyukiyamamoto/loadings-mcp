'use strict';
fetch('config.json', {cache: 'no-store'}).then(response => {
  if (!response.ok) throw new Error('Configuration unavailable');
  return response.json();
}).then(config => {
  if (!config.endpoint) return;
  const url = new URL(config.endpoint);
  if (url.protocol !== 'https:' || !url.pathname.endsWith('/mcp') || url.username || url.password) return;
  document.getElementById('endpoint').textContent = url.href;
  document.getElementById('connect-status').textContent = config.authentication === 'none'
    ? `Free public Streamable HTTP at ${url.href}. No sign-up or API key is required. Shared usage limits apply.`
    : `Connect using Streamable HTTP at ${url.href}. Configure authentication according to your deployment.`;
  document.getElementById('claude-command').textContent = `claude mcp add --transport http loadings-mcp ${url.href}`;
}).catch(() => { /* Keep the honest pending-deployment fallback. */ });
