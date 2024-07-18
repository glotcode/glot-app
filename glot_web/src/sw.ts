import { registerRoute } from 'workbox-routing';
import { CacheFirst } from 'workbox-strategies';

registerRoute(({ request, url }) => {
    return hasHashParam(url);
}, new CacheFirst());


function hasHashParam(url: URL) {
    const hash = url.searchParams.get("hash");
    return hash !== null && hash !== "checksum";
}