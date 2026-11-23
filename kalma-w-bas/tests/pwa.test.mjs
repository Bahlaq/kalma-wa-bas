import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..','dist');
const origin='https://kalma-w-bas.laith-ziod.chatgpt.site';
const marker='<html data-app-shell="kalma-w-bas">game</html>';
function harness(){
 const handlers={},stores=new Map();let offline=false,auth=false,badAsset=false,badPhoto=false,activated=0;
 const cacheKey=k=>new URL(typeof k==='string'?k:k.url,origin).pathname;
 const caches={
  async open(name){if(!stores.has(name))stores.set(name,new Map());const store=stores.get(name);return {async put(k,r){store.set(cacheKey(k),r.clone());},async match(k){return store.get(cacheKey(k))?.clone();}};},
  async keys(){return [...stores.keys()];},async delete(name){return stores.delete(name);}
 };
 const self={location:{origin},clients:{async claim(){}},addEventListener(type,fn){handlers[type]=fn;},skipWaiting(){activated++;}};
 const fetch=async request=>{if(offline)throw new Error('offline');const url=new URL(typeof request==='string'?request:request.url,origin);const shell=['/','/index.html'].includes(url.pathname);if(auth&&shell)return new Response('Sign in',{status:403,headers:{'content-type':'text/html'}});if(badAsset&&url.pathname==='/app.js')return new Response('<html>Sign in</html>',{headers:{'content-type':'text/html'}});if(url.pathname==='/photo-assets.json')return new Response(fs.readFileSync(path.join(root,'photo-assets.json')),{headers:{'content-type':'application/json'}});if(url.pathname.startsWith('/assets/players/'))return badPhoto?new Response('Not found',{status:404}):new Response('photo',{headers:{'content-type':'image/jpeg'}});return new Response(shell?marker:'asset',{headers:{'content-type':shell?'text/html':'application/octet-stream'}});};
 const context=vm.createContext({self,caches,fetch,Request,Response,URL,AbortController,setTimeout,clearTimeout,console});
 vm.runInContext(fs.readFileSync(path.join(root,'sw.js'),'utf8'),context);
 const trigger=async name=>{let work;handlers[name]({waitUntil(promise){work=promise;}});await work;};
 const request=async (pathname,mode='navigate')=>{let result;handlers.fetch({request:{url:origin+pathname,method:'GET',mode},respondWith(promise){result=promise;}});return result?await result:undefined;};
 return {handlers,stores,context,trigger,request,setOffline(v){offline=v;},setAuth(v){auth=v;},setBadAsset(v){badAsset=v;},setBadPhoto(v){badPhoto=v;},get activated(){return activated;}};
}
test('manifest supplies Android launch identity and correctly sized, local PNG icons',()=>{
 const manifest=JSON.parse(fs.readFileSync(path.join(root,'manifest.webmanifest'),'utf8'));
 assert.equal(manifest.display,'standalone');assert.equal(manifest.id,'/');assert.equal(manifest.start_url,'/?source=pwa');
 assert.ok(manifest.icons.some(i=>i.purpose==='maskable'));
 for(const icon of manifest.icons){const data=fs.readFileSync(path.join(root,icon.src));const [width,height]=icon.sizes.split('x').map(Number);assert.equal(data.readUInt32BE(16),width);assert.equal(data.readUInt32BE(20),height);}
 const index=fs.readFileSync(path.join(root,'index.html'),'utf8');assert.match(index,/<link rel="manifest"[^>]*crossorigin="use-credentials"/);
 const h=harness();for(const asset of vm.runInContext('APP_ASSETS',h.context))assert.ok(fs.existsSync(path.join(root,asset==='/'?'index.html':asset)),asset);
});
test('offline game launches and serves its local modules after complete installation',async()=>{
 const h=harness();await h.trigger('install');await h.trigger('activate');h.setOffline(true);
 assert.match(await(await h.request('/?source=pwa')).text(),/kalma-w-bas/);
 assert.equal(await(await h.request('/engine.mjs','cors')).text(),'asset');
 const photos=JSON.parse(fs.readFileSync(path.join(root,'photo-assets.json'),'utf8'));
 for(const src of photos.assets)assert.equal(await(await h.request(src,'cors')).text(),'photo',src);
 assert.equal(h.activated,0,'updates must not skip waiting without a user action');
});
test('online authorization failures are respected and account/callback routes are not intercepted',async()=>{
 const h=harness();await h.trigger('install');h.setAuth(true);
 assert.equal((await h.request('/')).status,403);
 assert.equal(await h.request('/auth/callback'),undefined);
 assert.equal(await h.request('/?code=private-token'),undefined);
 assert.equal(await h.request('/api/account'),undefined);
});
test('a sign-in page served instead of a script cannot become the offline application',async()=>{
 const h=harness();h.setBadAsset(true);await assert.rejects(()=>h.trigger('install'),/sign-in/);
 assert.equal(h.stores.size,0);
});
test('an incomplete photo download cannot claim the game is ready offline',async()=>{
 const h=harness();h.setBadPhoto(true);await assert.rejects(()=>h.trigger('install'),/photo download incomplete/);
 assert.equal(h.stores.size,0);
});
test('update activation is explicit and deletes only older app caches',async()=>{
 const h=harness();await h.trigger('install');h.stores.set('other-app-data',new Map());h.stores.set('kalma-w-bas-shell-old',new Map());
 h.handlers.message({data:{type:'ACTIVATE_UPDATE'}});assert.equal(h.activated,1);
 await h.trigger('activate');assert.ok(h.stores.has('other-app-data'));assert.ok(!h.stores.has('kalma-w-bas-shell-old'));
});
