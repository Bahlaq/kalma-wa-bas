import { PLAYERS, DIFFICULTY, CATEGORIES } from '../kalma-w-bas/dist/players.mjs';
import { writeFileSync, readdirSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const libData = join(root, 'app', 'lib', 'data');
mkdirSync(libData, { recursive: true });

const esc = (s) => String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'");

let playersOut = `// Generated from kalma-w-bas/dist/players.mjs — do not edit by hand.
import '../engine/models.dart';

const Map<String, String> difficultyLabels = {
`;
for (const [k, v] of Object.entries(DIFFICULTY)) {
  playersOut += `  '${k}': '${esc(v)}',\n`;
}
playersOut += `};

const Map<String, String> categoryLabels = {
`;
for (const [k, v] of Object.entries(CATEGORIES)) {
  playersOut += `  '${k}': '${esc(v)}',\n`;
}
playersOut += `};

final List<Player> builtinPlayers = [
`;
for (const p of PLAYERS) {
  const tags = p.tags.map((t) => `'${t}'`).join(', ');
  playersOut += `  Player(id: '${p.id}', name: '${esc(p.name)}', difficulty: '${p.difficulty}', tags: [${tags}]),\n`;
}
playersOut += '];\n';
writeFileSync(join(libData, 'players.dart'), playersOut);

const files = readdirSync(join(root, 'app', 'assets', 'players'));
const byId = {};
for (const f of files) {
  const m = f.match(/^(p\d+)\.(jpg|jpeg|png|webp)$/i);
  if (m) byId[m[1]] = `assets/players/${f}`;
}

let photosOut = `// Generated from asset filenames.
const Map<String, String> playerPhotoAssets = {
`;
for (const id of Object.keys(byId).sort()) {
  photosOut += `  '${id}': '${byId[id]}',\n`;
}
photosOut += `};

String? photoAssetFor(String playerId) => playerPhotoAssets[playerId];
`;
writeFileSync(join(libData, 'player_photos.dart'), photosOut);

console.log(`Wrote ${PLAYERS.length} players, ${Object.keys(byId).length} photos`);
