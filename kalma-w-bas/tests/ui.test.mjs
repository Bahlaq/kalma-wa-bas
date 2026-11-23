// Server-side template and event checks. No browser or preview server is used.
import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {PLAYERS,DIFFICULTY,CATEGORIES} from '../dist/players.mjs';
import * as E from '../dist/engine.mjs';
import {PLAYER_PHOTOS} from '../dist/player-photos.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
function boot(){
 const elements=new Map(),storage=new Map(),events={};
 const elem=id=>{if(!elements.has(id))elements.set(id,{innerHTML:'',textContent:'',style:{},dataset:{},disabled:false,open:false,classList:{add(){},remove(){},toggle(){}},setAttribute(){},addEventListener(type,fn){events[`${id}:${type}`]=fn;},focus(){},showModal(){this.open=true;},close(){this.open=false;}});return elements.get(id);};
 const doc={querySelector:elem,querySelectorAll:()=>[],body:{dataset:{}},hidden:false,addEventListener(type,fn){events[type]=fn;},title:''};
 const context=vm.createContext({document:doc,window:{scrollTo(){},addEventListener(){}},localStorage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v)},setInterval(){},setTimeout(){},clearTimeout(){},structuredClone,Intl,FormData,console,E,PLAYERS,DIFFICULTY,CATEGORIES,PLAYER_PHOTOS});
 const source=fs.readFileSync(path.join(root,'dist/app.js'),'utf8').replace(/^import .*\n/gm,'');
 vm.runInContext(source,context);
 return {context,elem,events,run:code=>vm.runInContext(code,context)};
}
test('app boots into an Arabic USA94 home with actionable setup and complete player count',()=>{
 const app=boot();const html=app.elem('#main').innerHTML;
 assert.match(html,/USA/);assert.match(html,/data-action="setup"/);assert.match(html,/retro-marquee/);assert.match(html,/٣٦٢/);
 assert.doesNotMatch(html,/undefined|NaN/);
});
test('hidden name is absent from all pre-game and active round markup',()=>{
 const app=boot();app.run("match=E.createMatch(defaultConfig,PLAYERS,()=>.4);view='match';render();");
 const name=app.run('match.current.player.name');
 assert.ok(!app.elem('#main').innerHTML.includes(name));
 assert.ok(!app.elem('#main').innerHTML.includes('class="player-photo"'));
 app.run('showSecret()');assert.ok(app.elem('#secret-content').innerHTML.includes(name));assert.ok(app.elem('#secret-content').innerHTML.includes('class="player-photo"'));
 app.run('hideSecret()');assert.ok(!app.elem('#secret-content').innerHTML.includes(name));assert.ok(!app.elem('#secret-content').innerHTML.includes('class="player-photo"'));
 app.run('match=E.acknowledge(match);render()');assert.ok(!app.elem('#main').innerHTML.includes(name));
 app.run('match=E.acknowledge(E.markSeen(match));render()');assert.ok(!app.elem('#main').innerHTML.includes(name));
 app.run('match=E.startRound(match);render()');assert.ok(!app.elem('#main').innerHTML.includes(name));assert.ok(!app.elem('#main').innerHTML.includes('class="player-photo"'));
 app.run('match=E.resolveRound(match,0,"correct");render()');assert.ok(app.elem('#main').innerHTML.includes(name));assert.ok(app.elem('#main').innerHTML.includes('class="player-photo"'));
});
test('all match templates render escaped user names and valid action surfaces',()=>{
 const app=boot();app.run('match=E.createMatch({...defaultConfig,teams:[{name:"<script>alert(1)</script>",members:["<img>","A"]},{name:"B",members:["C","D"]}]},PLAYERS);');
 for(const phase of ['reveal','ready','playing','result','finished']){
  app.run(`match.phase='${phase}';match.current.outcome={winner:0,reason:'correct'};view='match';render();`);
  const html=app.elem('#main').innerHTML;assert.ok(html.includes('&lt;script&gt;'));assert.ok(!html.includes('<script>'));assert.doesNotMatch(html,/undefined|NaN/);
 }
});
test('custom-only difficulty selection survives a switch back to the main pool',()=>{
 const app=boot();
 class MockFormData{get(name){return {category:'custom',difficulty:null,seconds:'90',target:'5',customNames:'أحمد\nعمر'}[name]??'';}}
 app.context.FormData=MockFormData;
 assert.equal(app.run('configFromForm().difficulty'),'all');
});
test('custom names reuse only an exact known player photo and its original credit',()=>{
 const app=boot();
 assert.equal(app.run("photoFor({id:'custom-1',name:PLAYERS[0].name,tags:['custom']})"),PLAYER_PHOTOS[PLAYERS[0].id]);
 assert.match(app.run("photoCredit({id:'custom-1',name:PLAYERS[0].name,tags:['custom']})"),new RegExp('photo-credits.html#'+PLAYERS[0].id));
 assert.equal(app.run("playerPortrait({id:'custom-2',name:'اسم غير موجود',tags:['custom']})"),'');
});
test('all local assets referenced by the document and CSS exist',()=>{
 const files=['index.html','styles.css','theme-94.css'];
 for(const file of files){const source=fs.readFileSync(path.join(root,'dist',file),'utf8');const refs=[...source.matchAll(/(?:href|src)="(\/[^"#]+)"|url\('(\/[^']+)'\)/g)].map(m=>m[1]||m[2]);for(const ref of refs)assert.ok(fs.existsSync(path.join(root,'dist',ref)),`${file}: ${ref}`);}
});
