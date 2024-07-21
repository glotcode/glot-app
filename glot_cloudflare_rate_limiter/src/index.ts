import { RateLimiter } from './rate_limiter'
export { RateLimiter };

/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run `npm run dev` in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run `npm run deploy` to publish your worker
 *
 * Bind resources to your worker in `wrangler.toml`. After adding bindings, a type definition for the
 * `Env` object can be regenerated with `npm run cf-typegen`.
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

interface Env {
	RATE_LIMITER: DurableObjectNamespace<RateLimiter>;
}

export default {
	async fetch(request, env, ctx): Promise<Response> {
		const ip = request.headers.get("CF-Connecting-IP");
		if (ip === null) {
			return errorResponse(400, "Could not determine client IP");
		}

		try {
			const id = env.RATE_LIMITER.idFromName(ip);
			const stub = env.RATE_LIMITER.get(id);
			const stats = await stub.increment({ maxRequests: 10, periodDuration: 60 * 1000 });

			return new Response(JSON.stringify(stats));
		} catch (e) {
			return errorResponse(500, "Internal server error");
		}
	},
} satisfies ExportedHandler<Env>;



function errorResponse(status: number, message: string): Response {
	return new Response(JSON.stringify({ message }), {
		status,
		headers: {
			"Content-Type": "application/json",
		},
	});
}
