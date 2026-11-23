export const VERSION = 1;
const copy = value=>JSON.parse(JSON.stringify(value));
export function normalizeWord(word) {
  return word.trim().normalize('NFKC').replace(/[\u064B-\u065F\u0670\u0640]/gu,'').replace(/[أإآ]/gu,'ا').toLowerCase();
}
export function makePool(players,config) {
  const custom = [...new Set((config.customNames||'').split('\n').map(s=>s.trim()).filter(Boolean))].slice(0,150)
    .map((name,index)=>({id:`custom-${index}`,name:name.slice(0,70),difficulty:'custom',tags:['custom']}));
  const filtered = config.category==='custom' ? [] : players.filter(p=>(config.category==='all'||p.tags.includes(config.category))&&(config.difficulty==='all'||p.difficulty===config.difficulty));
  return [...filtered,...custom].filter((p,i,a)=>a.findIndex(x=>normalizeWord(x.name)===normalizeWord(p.name))===i);
}
export function shuffled(list,rng=Math.random) {
  const a=copy(list);
  for(let i=a.length-1;i>0;i--){const j=Math.floor(rng()*(i+1));[a[i],a[j]]=[a[j],a[i]];}
  return a;
}
export function createMatch(config,players,rng=Math.random) {
  const deck=shuffled(makePool(players,config),rng);
  if(deck.length<2) throw new Error('اختاروا لاعبين اثنين على الأقل لبدء التحدّي.');
  const state={version:VERSION,config:copy(config),deck,cursor:0,scores:[0,0],history:[],phase:'reveal',current:null,endReason:null};
  return nextRound(state);
}
export function nextRound(previous,{replace=false}={}) {
  const state=copy(previous);
  if(state.cursor>=state.deck.length){state.phase='finished';state.endReason='exhausted';return state;}
  const number=replace?state.current.number:state.history.length+1;
  state.current={number,player:state.deck[state.cursor++],revealStep:0,seen:[false,false],turn:(number-1)%2,clues:[0,0],hints:[],remaining:state.config.seconds||null,deadline:null,paused:false,outcome:null};
  state.phase='reveal';return state;
}
export function markSeen(previous) {
  const state=copy(previous);
  if(state.phase==='reveal') state.current.seen[state.current.revealStep]=true;
  return state;
}
export function acknowledge(previous) {
  const state=copy(previous);
  if(state.phase!=='reveal'||!state.current.seen[state.current.revealStep])return state;
  if(state.current.revealStep===0)state.current.revealStep=1;else state.phase='ready';
  return state;
}
export function startRound(previous,now=Date.now()) {
  const state=copy(previous);
  if(state.phase!=='ready')return state;
  state.phase='playing';state.current.paused=false;
  state.current.deadline=state.config.seconds?now+state.current.remaining*1000:null;
  return state;
}
export function remaining(state,now=Date.now()) {
  if(!state.config.seconds)return null;
  return state.current.deadline===null?state.current.remaining:Math.max(0,(state.current.deadline-now)/1000);
}
export function pause(previous,now=Date.now()) {
  const state=copy(previous);
  if(state.phase!=='playing')return state;
  state.current.remaining=remaining(state,now);state.current.deadline=null;state.current.paused=true;
  return state;
}
export function resume(previous,now=Date.now()) {
  const state=copy(previous);
  if(state.phase!=='playing'||!state.current.paused)return state;
  state.current.paused=false;state.current.deadline=state.config.seconds?now+state.current.remaining*1000:null;
  return state;
}
export function addHint(previous,word='',now=Date.now()) {
  if(previous.phase!=='playing'||previous.current.paused)throw new Error('تابعوا المؤقّت أولًا.');
  if(remaining(previous,now)===0)throw new Error('انتهى الوقت.');
  const clean=word.trim();const normalized=normalizeWord(clean);
  if(clean&&(!/^[\p{L}\p{M}\p{N}]+$/u.test(clean)||clean.length>30))throw new Error('كلمة واحدة فقط، بدون مسافات أو رموز.');
  if(clean&&previous.current.hints.some(h=>normalizeWord(h.word)===normalized))throw new Error('هذه الكلمة انقالت! جرّب كلمة جديدة.');
  const state=copy(previous);const team=state.current.turn;
  state.current.hints.push({team,word:clean});state.current.clues[team]++;state.current.turn=1-team;
  return state;
}
export function resolveRound(previous,winner=null,reason='skip',now=Date.now()) {
  const state=copy(previous);
  if(state.phase!=='playing')return state;
  if(winner!==null&&winner!==0&&winner!==1)throw new Error('فريق غير صالح.');
  if(winner!==null&&state.current.paused)throw new Error('تابعوا الجولة قبل تسجيل النقطة.');
  state.current.remaining=remaining(state,now);state.current.deadline=null;state.current.paused=false;
  state.current.outcome={winner,reason};
  if(winner!==null)state.scores[winner]++;
  state.history.push({number:state.current.number,player:state.current.player,winner,reason,clues:[...state.current.clues],hints:copy(state.current.hints)});
  state.phase='result';return state;
}
export function undoResult(previous) {
  const state=copy(previous);
  if(state.phase!=='result'||state.current.outcome?.winner===null)return state;
  state.scores[state.current.outcome.winner]--;state.history.pop();state.current.outcome=null;
  state.current.remaining=state.config.seconds?Math.max(1,state.current.remaining):null;
  state.phase='playing';state.current.paused=true;return state;
}
export function matchWinner(state) {
  return state.scores.findIndex(score=>score>=state.config.target);
}
export function continueMatch(previous) {
  if(previous.phase!=='result')return copy(previous);
  if(matchWinner(previous)!==-1)return {...copy(previous),phase:'finished',endReason:'target'};
  return nextRound(previous);
}
export function finishMatch(previous) {
  const state=pause(previous);state.phase='finished';state.endReason='manual';return state;
}
export function cluePerson(state,team) {return state.config.teams[team].members[(state.current.number-1)%2];}
export function guessPerson(state,team) {return state.config.teams[team].members[state.current.number%2];}
export function validSavedState(state) {
  return state?.version===VERSION&&Array.isArray(state.deck)&&state.deck.length>0&&state.config?.teams?.length===2&&state.config.teams.every(t=>typeof t.name==='string'&&t.members?.length===2)&&Array.isArray(state.scores)&&state.scores.length===2&&state.scores.every(Number.isFinite)&&state.current?.player?.name&&['reveal','ready','playing','result','finished'].includes(state.phase)&&Array.isArray(state.history)&&Number.isInteger(state.cursor)&&state.cursor>=1&&state.cursor<=state.deck.length;
}
