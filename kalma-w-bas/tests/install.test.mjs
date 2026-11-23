import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import fs from 'node:fs';

const source=fs.readFileSync(new URL('../dist/pwa.js',import.meta.url),'utf8');
function boot({userAgent='',platform='',maxTouchPoints=0,standalone=false}={}){
 const elements=new Map(),windowEvents={},dispatched=[],copied=[];
 function element(id){
  if(!elements.has(id))elements.set(id,{innerHTML:'',textContent:'',hidden:false,open:false,style:{},attributes:{},events:{},setAttribute(k,v){this.attributes[k]=v;},addEventListener(k,fn){this.events[k]=fn;},showModal(){this.open=true;},close(){this.open=false;}});
  return elements.get(id);
 }
 const document={querySelector:element,documentElement:{classList:{toggle(){}}},dispatchEvent(event){dispatched.push(event.type);}};
 const window={isSecureContext:true,matchMedia(){return {matches:standalone,addEventListener(){}};},addEventListener(k,fn){windowEvents[k]=fn;}};
 const navigator={userAgent,platform,maxTouchPoints,standalone,onLine:true,clipboard:{async writeText(text){copied.push(text);}}};
 vm.runInNewContext(source,{document,window,navigator,Event});
 return {element,windowEvents,dispatched,copied,click:async id=>element(id).events.click({target:element(id)})};
}
test('iPhone install help opens Safari instructions and copies a Safari handoff',async()=>{
 const app=boot({userAgent:'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 Mobile Safari/604.1'});
 await app.click('#install-button');
 assert.equal(app.element('#install-help').open,true);
 assert.ok(app.dispatched.includes('kalma:before-update'));
 const instructions=app.element('#install-help-steps').innerHTML;
 assert.match(instructions,/Safari/);assert.match(instructions,/مشاركة/);assert.match(instructions,/إضافة إلى الشاشة الرئيسية/);assert.match(instructions,/فتح كتطبيق ويب/);
 assert.doesNotMatch(instructions,/Chrome|سامسونج/);
 assert.match(app.element('#offline-status').textContent,/Safari/);
 await app.click('#copy-install-link');
 assert.equal(app.copied[0],'https://kalma-w-bas.laith-ziod.chatgpt.site');
 assert.match(app.element('#install-help-feedback').textContent,/Safari/);
});
test('iPads with a desktop user agent get iOS instructions, while a Mac does not',()=>{
 const ipad=boot({userAgent:'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15) AppleWebKit/605.1.15',platform:'MacIntel',maxTouchPoints:5});
 assert.equal(ipad.element('#install-device-ios').attributes['aria-pressed'],'true');
 const mac=boot({platform:'MacIntel',maxTouchPoints:0});
 assert.equal(mac.element('#install-device-ios').attributes['aria-pressed'],'false');
 assert.equal(mac.element('#install-help-steps').innerHTML,'');
});
test('manual device selection changes both instructions and copy feedback',async()=>{
 const app=boot({userAgent:'Embedded browser'});
 await app.click('#install-device-ios');await app.click('#copy-install-link');
 assert.match(app.element('#install-help-feedback').textContent,/Safari/);
 await app.click('#install-device-android');
 assert.equal(app.element('#install-device-ios').attributes['aria-pressed'],'false');
 assert.equal(app.element('#install-device-android').attributes['aria-pressed'],'true');
 assert.match(app.element('#install-help-intro').innerHTML,/Chrome/);
 assert.doesNotMatch(app.element('#install-help-steps').innerHTML,/Safari/);
 await app.click('#copy-install-link');assert.match(app.element('#install-help-feedback').textContent,/Chrome/);
});
test('Android still uses the available native install prompt',async()=>{
 const app=boot({userAgent:'Mozilla/5.0 (Linux; Android 17) Chrome/140.0 Mobile Safari/537.36'});
 let prompted=0,prevented=0;
 app.windowEvents.beforeinstallprompt({preventDefault(){prevented++;},async prompt(){prompted++;},userChoice:Promise.resolve({outcome:'accepted'})});
 await app.click('#install-button');
 assert.equal(prevented,1);assert.equal(prompted,1);assert.equal(app.element('#install-help').open,false);
});
test('an installed iOS app hides the install action',()=>{
 const app=boot({userAgent:'iPhone',standalone:true});
 assert.equal(app.element('#install-button').hidden,true);
 assert.equal(app.element('#install-title').textContent,'اللعبة على جهازك.');
});
