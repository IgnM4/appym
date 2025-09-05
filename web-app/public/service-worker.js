const CACHE = 'static-v1';
const DATA_CACHE = 'data-v1';
const BASE_URL = new URL(self.registration.scope).pathname;

const ASSETS = [
  '',
  'index.html',
  'dashboard.html',
  'login.html',
  'pos.html',
  'styles.css',
  'pos.css',
  'js/csv.js',
  'js/dashboard.js',
  'js/pos.js',
  'js/auth.js',
  'js/i18n.js',
  'i18n.json',
  'offline.html',
];

function url(path) {
  return BASE_URL + path;
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(ASSETS.map(url))),
  );
});

self.addEventListener('fetch', (event) => {
  const urlObj = new URL(event.request.url);
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => caches.match(url('offline.html'))),
    );
    return;
  }
  if (urlObj.pathname.startsWith(url('data/'))) {
    event.respondWith(
      caches.open(DATA_CACHE).then((cache) =>
        fetch(event.request)
          .then((resp) => {
            cache.put(event.request, resp.clone());
            return resp;
          })
          .catch(() => cache.match(event.request)),
      ),
    );
  } else {
    event.respondWith(
      caches.match(event.request).then((r) => r || fetch(event.request)),
    );
  }
});
