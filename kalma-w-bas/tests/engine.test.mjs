import test from 'node:test';
import assert from 'node:assert/strict';
import {PLAYERS} from '../dist/players.mjs';
import * as E from '../dist/engine.mjs';
const config={teams:[{name:'الصقور',members:['أحمد','عمر']},{name:'النمور',members:['محمد','ليث']}],seconds:90,target:5,category:'all',difficulty:'all',customNames:''};
const newMatch=overrides=>E.createMatch({...config,...overrides},PLAYERS,()=>.43);
const reveal=state=>E.acknowledge(E.markSeen(E.acknowledge(E.markSeen(state))));
const playing=(overrides,now=1000)=>E.startRound(reveal(newMatch(overrides)),now);

test('both clue-givers must privately see the same name before the referee starts',()=>{
 let s=newMatch(),name=s.current.player.name;
 assert.equal(E.acknowledge(s).current.revealStep,0);
 assert.equal(E.startRound(s,1000).phase,'reveal');
 s=E.acknowledge(E.markSeen(s));assert.equal(s.current.revealStep,1);
 assert.equal(s.current.player.name,name);assert.equal(E.acknowledge(s).phase,'reveal');
 s=E.acknowledge(E.markSeen(s));assert.equal(s.phase,'ready');
 s=E.startRound(s,1000);assert.equal(s.phase,'playing');assert.equal(s.current.deadline,91000);
});
test('hints alternate teams, count separately and reject sentences and repeated Arabic words',()=>{
 let s=playing();s=E.addHint(s,'أرجنتيني',2000);assert.equal(s.current.turn,1);assert.deepEqual(s.current.clues,[1,0]);
 assert.throws(()=>E.addHint(s,'القدم اليسرى',3000),/كلمة واحدة/);
 assert.throws(()=>E.addHint(s,'ارجنتيني',3000),/انقالت/);
 assert.throws(()=>E.addHint(s,'القدم-اليسرى',3000),/كلمة واحدة/);
 s=E.addHint(s,'يسار',3000);assert.equal(s.current.turn,0);assert.deepEqual(s.current.clues,[1,1]);
 s=E.addHint(s,'',4000);assert.equal(s.current.hints.length,3);assert.equal(s.current.turn,1);
});
test('real elapsed time is used and pausing freezes the remaining time',()=>{
 let s=playing();assert.equal(E.remaining(s,21500),69.5);
 s=E.pause(s,21500);assert.equal(E.remaining(s,9999999),69.5);
 assert.throws(()=>E.addHint(s,'كلمة',9999999),/تابعوا/);
 s=E.resume(s,100000);assert.equal(s.current.deadline,169500);assert.equal(E.remaining(s,169500),0);
 assert.throws(()=>E.addHint(s,'كلمة',170000),/انتهى/);
});
test('untimed rounds have no deadline and can be paused and resumed',()=>{
 let s=playing({seconds:0});assert.equal(E.remaining(s,1e12),null);
 s=E.pause(s,1e12);s=E.resume(s,2e12);assert.equal(s.current.deadline,null);
 assert.equal(E.addHint(s,'عربي',3e12).current.turn,1);
});
test('a scored answer awards one point only, and undo restores the same paused round',()=>{
 let s=playing();s=E.resolveRound(s,1,'correct',17000);
 assert.deepEqual(s.scores,[0,1]);assert.equal(s.history.length,1);assert.equal(s.phase,'result');
 const player=s.current.player.name;
 s=E.resolveRound(s,1,'correct',17001);assert.deepEqual(s.scores,[0,1]);assert.equal(s.history.length,1);
 s=E.undoResult(s);assert.deepEqual(s.scores,[0,0]);assert.equal(s.history.length,0);assert.equal(s.current.player.name,player);assert.equal(s.current.paused,true);assert.equal(s.current.remaining,74);
});
test('timeout and skipping award no points, then swap roles and opening team',()=>{
 let s=playing();assert.equal(E.cluePerson(s,0),'أحمد');assert.equal(E.guessPerson(s,1),'ليث');
 s=E.resolveRound(s,null,'timeout',91000);assert.deepEqual(s.scores,[0,0]);
 s=E.continueMatch(s);assert.equal(s.current.number,2);assert.equal(s.current.turn,1);
 assert.equal(E.cluePerson(s,0),'عمر');assert.equal(E.guessPerson(s,1),'محمد');
 s=E.startRound(reveal(s),100000);s=E.pause(s,101000);s=E.resolveRound(s,null,'skip',101000);
 assert.deepEqual(s.scores,[0,0]);assert.equal(s.history.length,2);
});
test('match finishes at target, with no extra card drawn',()=>{
 let s=newMatch({target:2});
 for(let i=0;i<2;i++){s=E.startRound(reveal(s),1000);s=E.resolveRound(s,0,'correct',2000);s=E.continueMatch(s);}
 assert.equal(s.phase,'finished');assert.equal(s.endReason,'target');assert.equal(s.cursor,2);assert.deepEqual(s.scores,[2,0]);
});
test('every card is unique, replacements consume a card without incrementing the round',()=>{
 let s=newMatch({category:'arab',difficulty:'easy'}),seen=new Set(),count=s.deck.length;
 while(s.phase!=='finished'){assert.ok(!seen.has(s.current.player.id));seen.add(s.current.player.id);s=E.nextRound(s,{replace:true});}
 assert.equal(seen.size,count);assert.equal(s.current.number,1);assert.equal(s.endReason,'exhausted');
});
test('custom-only pool ignores difficulty and deduplicates Arabic aliases',()=>{
 const custom={...config,category:'custom',difficulty:'hard',customNames:'أحمد\nاحمد\nعمر\n\nمحمد'};
 const pool=E.makePool(PLAYERS,custom);assert.equal(pool.length,3);assert.ok(pool.every(p=>p.tags.includes('custom')));
 assert.throws(()=>newMatch({...custom,customNames:'أحمد'}),/اثنين/);
});
test('all supported category and difficulty pairs have a playable pool',()=>{
 for(const category of ['all','arab','world','legends'])for(const difficulty of ['all','easy','medium','hard']){
   const pool=E.makePool(PLAYERS,{...config,category,difficulty});assert.ok(pool.length>=2,`${category}/${difficulty}`);
   assert.ok(pool.every(p=>(category==='all'||p.tags.includes(category))&&(difficulty==='all'||p.difficulty===difficulty)));
 }
 assert.equal(new Set(PLAYERS.map(p=>E.normalizeWord(p.name))).size,PLAYERS.length);
});
test('state round trips through local persistence without losing players or scores',()=>{
 const s=E.pause(playing(),2000);const saved=JSON.parse(JSON.stringify(s));
 assert.equal(E.validSavedState(saved),true);assert.deepEqual(saved,s);
 for(const invalid of [null,{},[],{version:0}, {...s,phase:'corrupt'},{...s,scores:[null,0]}])assert.ok(!E.validSavedState(invalid));
});
