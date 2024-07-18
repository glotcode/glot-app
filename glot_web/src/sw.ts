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


// Cache all requests that does not have an hash parameter and are not API requests
registerRoute(
    ({ url }) => {
        return !hasHashParam(url) && !isApiRequest(url);
    },
    new NetworkFirst({
        cacheName: "offline-fallback"
    })
);


function isApiRequest(url: URL) {
    return url.pathname.startsWith("/api");
}


function hasHashParam(url: URL) {
    const hash = url.searchParams.get("hash");
    return hash !== null && hash !== "checksum";
}