// Bump this release whenever any application asset changes.
const CACHE_PREFIX = 'kalma-w-bas-shell-';
const CACHE_NAME = CACHE_PREFIX + '2026-10-20-ios-install-1';
const SHELL_MARKER = 'data-app-shell="kalma-w-bas"';
const APP_ASSETS = [
  '/', '/index.html', '/app.js', '/engine.mjs', '/players.mjs',
  '/styles.css', '/theme-94.css', '/pwa.css', '/pwa.js', '/manifest.webmanifest',
  '/photos.css', '/player-photos.mjs', '/photo-assets.json', '/photo-credits.html',
  '/assets/icon.svg', '/assets/arabic.woff', '/assets/arabic-bold.woff', '/assets/display.woff',
  '/assets/app-icon-180.png', '/assets/app-icon-192.png', '/assets/app-icon-512.png',
  '/assets/app-icon-maskable-512.png'
];
const SHELL_PATHS = new Set(['/', '/index.html']);
const PHOTO_PATH = /^\/assets\/players\/p\d{3}\.(?:jpe?g|png|webp)$/;

async function cachePlayerPhotos(cache,manifest) {
  if (!Array.isArray(manifest.assets) || manifest.assets.length !== manifest.count ||
      !manifest.assets.every(path => PHOTO_PATH.test(path)) ||
      new Set(manifest.assets).size !== manifest.assets.length) throw new Error('Invalid player photo list');
  let cursor = 0;
  let failure = null;
  // Bounded downloads avoid a burst of hundreds of image requests on mobile.
  await Promise.all(Array.from({length:Math.min(5,manifest.assets.length)}, async () => {
    while (cursor < manifest.assets.length && !failure) {
      const path = manifest.assets[cursor++];
      try {
        const response = await fetch(new Request(new URL(path,self.location.origin), {
          credentials:'same-origin',cache:'reload',redirect:'error'
        }));
        if (!response.ok || response.redirected || !(response.headers.get('content-type') || '').startsWith('image/')) {
          throw new Error('Player photo download incomplete');
        }
        await cache.put(path,response);
      } catch(error) {failure=error;}
    }
  }));
  if(failure)throw failure;
}

async function isGameShell(response) {
  return response.ok && !response.redirected && response.type !== 'opaqueredirect' &&
    (response.headers.get('content-type') || '').includes('text/html') &&
    (await response.clone().text()).includes(SHELL_MARKER);
}

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    // Validate every file before writing. A sign-in response must never become the offline game.
    const entries = await Promise.all(APP_ASSETS.map(async path => {
      const response = await fetch(new Request(new URL(path, self.location.origin), {
        credentials: 'same-origin', cache: 'reload', redirect: 'error'
      }));
      if (!response.ok || response.redirected) throw new Error('App download incomplete');
      if (SHELL_PATHS.has(path)) {
        if (!await isGameShell(response)) throw new Error('App sign-in required');
      } else if (path !== '/photo-credits.html' && (response.headers.get('content-type') || '').includes('text/html')) {
        throw new Error('Unexpected sign-in or error page');
      }
      return [path, response];
    }));
    const cache = await caches.open(CACHE_NAME);
    try {
      await Promise.all(entries.map(([path,response]) => cache.put(path,response)));
      const manifestResponse = await cache.match('/photo-assets.json');
      await cachePlayerPhotos(cache,await manifestResponse.json());
    }
    catch (error) { await caches.delete(CACHE_NAME); throw error; }
    // Updated workers wait. Only a user's explicit update action can replace a running match.
  })());
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter(name => name.startsWith(CACHE_PREFIX) && name !== CACHE_NAME).map(name => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener('message', event => {
  if (event.data?.type === 'ACTIVATE_UPDATE') self.skipWaiting();
});

async function navigationResponse(request) {
  const cache = await caches.open(CACHE_NAME);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 4000);
  try {
    const response = await fetch(request, {signal: controller.signal});
    // Honour live sign-in/access responses; only network failure uses the offline shell.
    if (!await isGameShell(response)) return response;
    // Keep the HTML and its scripts on one release until an update is activated.
    return await cache.match('/') || response;
  } catch (error) {
    const shell = await cache.match('/');
    if (shell) return shell;
    throw error;
  } finally { clearTimeout(timer); }
}

self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;
  // Leave authentication, callbacks, account data and every unknown route alone.
  if (url.search && url.search !== '?source=pwa') return;
  if (!APP_ASSETS.includes(url.pathname) && !PHOTO_PATH.test(url.pathname)) return;
  if (request.mode === 'navigate' && SHELL_PATHS.has(url.pathname)) {
    event.respondWith(navigationResponse(request));
    return;
  }
  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    return await cache.match(url.pathname) || fetch(request);
  })());
});
