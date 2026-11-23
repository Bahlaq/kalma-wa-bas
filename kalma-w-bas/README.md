# كلمة وبس

Arabic mobile-first, in-person football guessing game. Two teams of two and a referee share one device. Uses a static, offline player deck with real photographs; there is no room server or remote multiplayer.

## Play

The referee sets teams, difficulty, player pool, shared round time and the target score. One clue-giver from each team privately holds the reveal button to see the same footballer's name and photograph. Release hides both. Clues are spoken, one word per turn. Optional typed clues are validated for one word and duplicate use. The referee awards the first correct answer. Each completed round swaps clue-giver and guesser and alternates the opening team.

Player names do not repeat in one match. Custom names can supplement the deck or form their own pool. The timer pauses on navigation away, rules or tab hiding. Match state is persisted only in browser localStorage. Audio is synthesized after user interaction. Fonts and icons are bundled locally; the game has no runtime third-party requests.

## Source

`dist/engine.mjs`: pure state transitions and timer calculations.
`dist/players.mjs`: player name pools, no live club data.
`dist/app.js`: UI, referee controls, local persistence.
`dist/styles.css`: responsive RTL interface.

Run `node --test tests/engine.test.mjs` to verify round progression, privacy handoffs, timer behavior, non-repetition and scoring. Source is stored in the Site Git repository and the static `dist` directory is published with the Sites workflow.

## Visual direction

The USA 1994-inspired theme uses royal blue, red stripes, stars, warm paper and vintage football card/ticket geometry. The artwork is original SVG/CSS. Historical visual reference: https://www.pentagram.com/work/1994-world-cup. This game has no official FIFA affiliation. Local fonts retain their embedded copyright and licensing metadata in `dist/assets/FONT-LICENSES.txt`.

## Verification

Node tests cover timer arithmetic, secret handoff, phase rendering, escaping, category changes, score correction, role rotation, exhaustion, no-repeat selection, photo coverage, complete offline photo caching and platform-specific install guidance. The updated install dialog was visually checked in the managed Chrome preview; iPhone/iPad detection and Android install-prompt behavior were checked with Node VM tests. Run `node --test tests/*.test.mjs`.

## iPhone, Android installation and offline mode

The app is an installable PWA with a credentialed web manifest, standalone launch mode, PNG and maskable launcher icons, an install action and platform-specific help. iPhone and iPad (including desktop-style iPad user agents) show Safari's Share → Add to Home Screen steps, with Open as Web App when offered. Android retains the native install prompt and manual Chrome steps. Help includes a manual iPhone/Android choice for embedded or unusual browsers. The Site is public. Open it online from the new home-screen icon and wait for the offline-ready status. This is a web app, not an App Store or Play Store publication.

`sw.js` precaches the local shell, game logic, player bank, fonts, icons and all bundled player photographs. Bounded photo downloads finish before the offline-ready status appears; a failed image download discards the new incomplete cache. Installation rejects redirects and login HTML in place of assets. Only whitelisted static resources are intercepted; authentication, callback queries, APIs and account routes pass through. Online navigation honours access responses; network failures can use the previously authorised local shell. Match state remains in localStorage.

## Player photographs

`dist/player-photos.mjs` maps built-in player IDs to locally stored photos and individual source/author/license records. `dist/photo-credits.html` exposes the credits. The secret card only inserts the name and photo while held; it removes both on release, blur and the automatic hide deadline. The result card reveals both after the round. Custom names reuse a known picture only when they match a built-in name; otherwise they remain name-only.

Run `node scripts/build-photo-assets.mjs` after updating the photo collection. It refuses missing built-in photos and generates the offline asset list and credits page. The collection has no runtime dependence on Wikipedia or image hosts. Bump the service worker release for any asset change.

Updates wait for the user and save/pause the match before reloading. **Bump CACHE_NAME in dist/sw.js whenever any shell asset changes.** Offline behaviour, cache isolation and platform-specific install guidance are covered by Node VM tests. Physical iPhone/Android installation has not been exercised in this environment.

Installation reference: https://support.google.com/chrome/answer/9658361?co=GENIE.Platform%3DAndroid&hl=ar

iPhone installation reference: https://support.apple.com/ar-jo/guide/iphone/iphea86e5236/ios
