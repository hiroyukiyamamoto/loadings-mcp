// Optional deployed-site check using installed Microsoft Edge and native CDP.
// No browser automation dependency, personal profile, or cloud credentials.
import {spawn} from 'node:child_process';
import {mkdirSync, writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import assert from 'node:assert/strict';

const site = process.env.SITE_URL || 'https://hiroyukiyamamoto.github.io/loadings-mcp/';
const executable = process.env.EDGE_PATH || 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';
mkdirSync('test-results', {recursive:true});
const browser = spawn(executable, ['--headless=new','--no-first-run','--no-default-browser-check',
  '--remote-debugging-port=0', `--user-data-dir=${resolve('test-results/edge-profile')}`, 'about:blank'],
  {stdio:['ignore','ignore','pipe'], windowsHide:true});
let socket;
try {
  const endpoint = await new Promise((done, reject) => {
    const timer = setTimeout(() => reject(new Error('Browser startup timed out')), 20000);
    let output = '';
    browser.stderr.on('data', data => {
      output += data.toString();
      const match = output.match(/DevTools listening on (ws:\/\/\S+)/);
      if (match) {clearTimeout(timer); done(match[1]);}
    });
    browser.on('error', reject);
  });
  socket = new WebSocket(endpoint);
  await new Promise((done,reject) => {socket.addEventListener('open', done);socket.addEventListener('error',reject);});
  let id = 0;
  const pending = new Map();
  socket.addEventListener('message', event => {
    const response = JSON.parse(event.data);
    if (pending.has(response.id)) {
      const {done,reject,timer} = pending.get(response.id); pending.delete(response.id); clearTimeout(timer);
      response.error ? reject(new Error(JSON.stringify(response.error))) : done(response.result);
    }
  });
  function send(method, params = {}, sessionId) {
    return new Promise((done,reject) => {
      const callId = ++id;
      const timer = setTimeout(() => {pending.delete(callId);reject(new Error(`CDP timeout: ${method}`));},20000);
      pending.set(callId,{done,reject,timer});
      socket.send(JSON.stringify({id:callId,method,params,sessionId}));
    });
  }
  const {targetId} = await send('Target.createTarget',{url:'about:blank'});
  const {sessionId} = await send('Target.attachToTarget',{targetId,flatten:true});
  const evaluate = async expression => (await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true},sessionId)).result.value;
  await send('Page.enable',{},sessionId);
  const results = [];
  for (const [label,width,height] of [['desktop',1440,1000],['mobile',390,844]]) {
    await send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:label==='mobile'},sessionId);
    await send('Page.navigate',{url:site},sessionId);
    let state;
    for (let attempt=0;attempt<80;attempt++) {
      await evaluate(`document.querySelectorAll('img').forEach(image=>image.loading='eager')`);
      state = await evaluate(`({ready:document.readyState,title:document.title,endpoint:document.getElementById('endpoint')?.textContent,overflow:document.documentElement.scrollWidth>innerWidth,brokenAnchors:[...document.querySelectorAll('a[href^="#"]')].filter(a=>a.hash&& !document.getElementById(a.hash.slice(1))).map(a=>a.hash),images:[...document.images].map(i=>({src:i.src,loaded:i.complete&&i.naturalWidth>0}))})`);
      if (state?.ready === 'complete' && state.endpoint && !state.endpoint.startsWith('Loading ') && state.images.every(i=>i.loaded)) break;
      // Loading=lazy images need scrolling into view for verification.
      await evaluate(`document.getElementById('examples')?.scrollIntoView()`);
      await new Promise(done=>setTimeout(done,200));
    }
    assert(state.title.startsWith('loadings MCP'));
    assert(!state.endpoint.startsWith('Loading '),`${label}: endpoint configuration still loading`);
    assert.equal(state.overflow,false,`${label}: horizontal overflow`);
    assert.deepEqual(state.brokenAnchors,[]);
    assert(state.images.every(i=>i.loaded),`${label}: broken image`);
    await evaluate('scrollTo(0,0)');
    const {data} = await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false},sessionId);
    writeFileSync(`test-results/site-${label}.png`,Buffer.from(data,'base64'));
    results.push({viewport:label,width,height,...state});
  }
  writeFileSync('test-results/browser.json',JSON.stringify({site,results},null,2));
  console.log(JSON.stringify({site,results},null,2));
  await send('Browser.close');
} finally {
  socket?.close();
  browser.kill();
}
