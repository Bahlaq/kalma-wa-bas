# Kalma Wa Bas — Source Code

This is the source for version 4 of the football guessing game, including the USA 1994 theme, 362 player portraits, offline support, and iPhone/Android installation instructions.

## Run on your computer

1. Extract this ZIP.
2. Open a terminal in the `kalma-w-bas` folder.
3. With Python 3 installed, run:

```sh
python3 -m http.server 8000 --directory dist
```

4. Open http://localhost:8000 in your browser.

Serve the files over HTTP as shown above. Opening `index.html` directly as a local file will not load the JavaScript modules correctly.

No npm installation or build step is needed to run the game. An ordinary static web server can serve `dist` instead of Python.

## Main files

- `dist/index.html`: page structure.
- `dist/app.js`: screens and controls.
- `dist/engine.mjs`: game rules, timer and scoring.
- `dist/players.mjs`: player bank.
- `dist/player-photos.mjs`: player-to-photo mapping and credits.
- `dist/styles.css`, `dist/theme-94.css`, `dist/photos.css`: styling.
- `dist/pwa.js`, `dist/sw.js`, `dist/manifest.webmanifest`: installation and offline support.
- `dist/assets/`: all photos, fonts and icons.
- `tests/`: automated checks.
- `scripts/` and `data/`: photo sourcing, records and asset generation.

## Optional checks

With Node.js installed, run from the project folder:

```sh
node --test tests/*.test.mjs
```

## Host on another domain

Publish the contents of `dist` at the root of an HTTPS website. Update the existing game URL in `dist/pwa.js` and `dist/index.html` to your new address. After changing application files, update `CACHE_NAME` in `dist/sw.js` so installed copies receive the new version.

Photo and font credits are included in `dist/photo-credits.html`, `dist/player-photos.mjs`, and `dist/assets/FONT-LICENSES.txt`.

The game is designed for two teams and a referee sharing one device. It does not use an online room server.

## Export provenance

Published version: 4
Source commit: d001b6c341d960311a099f06a556cc3181552f9d
