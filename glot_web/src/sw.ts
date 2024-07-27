import { registerRoute } from 'workbox-routing';
import { CacheFirst, NetworkFirst } from 'workbox-strategies';
import { WorkboxPlugin, CacheDidUpdateCallbackParam } from 'workbox-core/types.js';


class EvictStaleHashedFilesPlugin implements WorkboxPlugin {
    // Delete old cache entries of the same file (but with a stale hash) when a new file is cached
    async cacheDidUpdate({ cacheName, request }: CacheDidUpdateCallbackParam) {
        const newUrl = new URL(request.url)
        const cache = await self.caches.open(cacheName)
        const keys = await cache.keys()

        const staleRequests = keys.filter((oldRequest) => {
            const oldUrl = new URL(oldRequest.url)
            return oldUrl.pathname === newUrl.pathname && !this.hasSameHash(oldUrl, newUrl)
        })

        staleRequests.forEach((request) => {
            cache.delete(request)
        })
    }

    private hasSameHash(url: URL, otherUrl: URL) {
        return url.searchParams.get("hash") == otherUrl.searchParams.get("hash")
    }
}

// Cache files with a hash parameter
registerRoute(({ url }) => {
    return hasHashParam(url);
}, new CacheFirst({
    cacheName: "hashed-files",
    plugins: [new EvictStaleHashedFilesPlugin()]
}));


// Cache all requests that meet the following criteria:
// - does not have an hash parameter
// - is not an API request
// - is not the service worker itself
// - is not an ignored url
registerRoute(
    ({ url }) => {
        return !hasHashParam(url) && !isApiRequest(url) && !isServiceWorker(url) && !isIgnored(url);
    },
    new NetworkFirst({
        cacheName: "offline-fallback"
    })
);


function isServiceWorker(url: URL) {
    return url.pathname === "/sw.js";
}

function isApiRequest(url: URL) {
    return url.pathname.startsWith("/internal-api");
}

function hasHashParam(url: URL) {
    const hash = url.searchParams.get("hash");
    return hash !== null && hash !== "checksum";
}

function isIgnored(url: URL) {
    return url.hostname.includes("cloudflareinsights")
}