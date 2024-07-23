import { RequestCounter } from './request_counter'
export { RequestCounter };


interface Env {
	REQUEST_COUNTER: DurableObjectNamespace<RequestCounter>;
}

export default {
	async fetch(request, env, ctx): Promise<Response> {
		const ip = request.headers.get("CF-Connecting-IP");
		if (ip === null) {
			return errorResponse(400, "Could not determine client IP");
		}

		try {
			const id = env.REQUEST_COUNTER.idFromName(ip);
			const stub = env.REQUEST_COUNTER.get(id);
			const stats = await stub.increment();

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