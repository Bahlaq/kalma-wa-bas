import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {PLAYERS} from '../dist/players.mjs';
import {PLAYER_PHOTOS} from '../dist/player-photos.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const escape=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const external=url=>/^https:\/\//.test(url||'');
const missing=PLAYERS.filter(player=>!PLAYER_PHOTOS[player.id]);
if(missing.length)throw new Error(`Missing player portraits: ${missing.map(p=>p.id+' '+p.name).join(', ')}`);
const assets=[...new Set(PLAYERS.map(player=>PLAYER_PHOTOS[player.id].src))];
let bytes=0;
for(const src of assets){if(!/^\/assets\/players\/p\d{3}\.(?:jpe?g|png|webp)$/.test(src))throw new Error(`Invalid asset: ${src}`);bytes+=fs.statSync(path.join(root,'dist',src)).size;}
fs.writeFileSync(path.join(root,'dist/photo-assets.json'),JSON.stringify({version:1,count:assets.length,bytes,assets},null,2)+'\n');
const rows=PLAYERS.map(player=>{
  const p=PLAYER_PHOTOS[player.id];
  if(!external(p.source))throw new Error(`Missing source for ${player.id}`);
  const license=external(p.licenseUrl)?`<a href="${escape(p.licenseUrl)}" target="_blank" rel="noopener noreferrer">${escape(p.license||'الترخيص')}</a>`:escape(p.license||'حسب شروط المصدر');
  const author=p.attribution||p.author||'راجع المصدر الأصلي';
  const credit=p.author&&p.attribution&&!p.attribution.includes(p.author)?`${p.author} — ${p.attribution}`:author;
  return `<tr id="${escape(player.id)}"><td>${escape(player.name)}</td><td class="credit-author">${escape(credit)}</td><td class="license-cell">${license}</td><td class="credit-source"><a href="${escape(p.source)}" target="_blank" rel="noopener noreferrer" dir="auto">${escape(p.title||'الصورة ومصدرها')} ↗</a></td></tr>`;
}).join('\n');
const html=`<!doctype html><html lang="ar" dir="rtl"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#142b69"><title>مصادر صور اللاعبين — كلمة وبس</title><link rel="icon" href="/assets/icon.svg"><link rel="stylesheet" href="/styles.css"><link rel="stylesheet" href="/theme-94.css"><link rel="stylesheet" href="/photos.css"></head><body><main class="credits-page"><a class="credits-back" href="/">← العودة إلى اللعبة</a><h1>صور اللاعبين ومصادرها</h1><p>صور حقيقية مرتبطة بلاعبي اللعبة. كل صورة مع اسم صاحبها أو الجهة المذكورة في المصدر، ورابط أصلها وترخيصها إن كان محددًا.</p><p class="credits-info">الصور معروضة بحجم مصغّر داخل بطاقة اللعبة، مع الحفاظ على نسبها. أسماء اللاعبين وصورهم تخصّ أصحابها؛ استخدام الصور لا يعني رعاية اللعبة من اللاعبين أو الجهات الظاهرة فيها. الأسماء التي تُضاف يدويًا تحتاج إلى صورة معروفة في بنك اللعبة لتظهر بصورة.</p><div class="credits-table-wrap"><table class="credits-table"><caption>${new Intl.NumberFormat('ar-JO').format(PLAYERS.length)} لاعبًا بصور موثّقة المصدر</caption><thead><tr><th scope="col">اللاعب</th><th scope="col">صاحب الصورة / الجهة</th><th scope="col">الترخيص</th><th scope="col">المصدر</th></tr></thead><tbody>${rows}</tbody></table></div></main></body></html>`;
fs.writeFileSync(path.join(root,'dist/photo-credits.html'),html);
console.log(JSON.stringify({players:PLAYERS.length,photos:assets.length,megabytes:Math.round(bytes/1e4)/100}));
