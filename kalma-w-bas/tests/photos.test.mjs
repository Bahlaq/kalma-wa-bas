import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {PLAYERS} from '../dist/players.mjs';
import {PLAYER_PHOTOS} from '../dist/player-photos.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..','dist');
test('every built-in player has a locally stored real image and an attributed source',()=>{
 const images=[];
 for(const player of PLAYERS){
  const photo=PLAYER_PHOTOS[player.id];assert.ok(photo,`${player.name} has no photo`);
  assert.match(photo.src,/^\/assets\/players\/p\d{3}\.(jpe?g|png|webp)$/);
  assert.match(photo.source,/^https:\/\//);assert.ok(photo.author?.trim());
  const bytes=fs.readFileSync(path.join(root,photo.src));assert.ok(bytes.length>1000,`${player.name}: image too small`);
  const jpg=bytes[0]===0xff&&bytes[1]===0xd8;
  const png=bytes.subarray(1,4).toString()==='PNG';
  const webp=bytes.subarray(0,4).toString()==='RIFF'&&bytes.subarray(8,12).toString()==='WEBP';
  assert.ok(jpg||png||webp,`${player.name}: not a supported image`);images.push(photo.src);
 }
 const manifest=JSON.parse(fs.readFileSync(path.join(root,'photo-assets.json'),'utf8'));
 assert.equal(manifest.count,new Set(images).size);
 assert.deepEqual([...manifest.assets].sort(),[...new Set(images)].sort());
});
test('every picture has a reachable local credit entry',()=>{
 const html=fs.readFileSync(path.join(root,'photo-credits.html'),'utf8');
 for(const player of PLAYERS){assert.ok(html.includes(`id="${player.id}"`));assert.ok(html.includes(player.name));}
});
