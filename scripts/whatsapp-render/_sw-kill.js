// Replaces the old Data Forge service worker: wipe its caches, unregister, reload open tabs.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map(k => caches.delete(k)));
    await self.registration.unregister();
    const tabs = await self.clients.matchAll({ type: 'window' });
    tabs.forEach(t => t.navigate(t.url));
  })());
});
