import { RateLimiter } from "../../../glot_cloudflare_rate_limiter/src/rate_limiter";

type StringRecord = Record<string, string>;

interface Env {
  RATE_LIMITER: DurableObjectNamespace<RateLimiter>;
}


export const onRequestPost: PagesFunction<Env & StringRecord> = async (context) => {
  if (!isAllowed(context.request)) {
    return errorResponse(403, "Forbidden");
  }

  const ip = context.request.headers.get("CF-Connecting-IP");
  if (ip === null) {
    return errorResponse(400, "Could not determine client IP");
  }

  const id = context.env.RATE_LIMITER.idFromName(ip);
  const stub = context.env.RATE_LIMITER.get(id);
  const response = await stub.fetch(context.request.clone());
  const stats = await response.text();

  console.log(stats)

  const envVars = parseEnvVars(context.env);
  return run(envVars, context.request.body);
};

function run(env: EnvVars, body: ReadableStream): Promise<Response> {
  const url = `${env.dockerRunBaseUrl}/run`;

  return fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Access-Token": env.dockerRunAccessToken,
    },
    body: body,
  });
}

interface EnvVars {
  dockerRunBaseUrl: string;
  dockerRunAccessToken: string;
}

function parseEnvVars(env: StringRecord): EnvVars {
  ensureNotEmpty(env, "DOCKER_RUN_BASE_URL");
  ensureNotEmpty(env, "DOCKER_RUN_ACCESS_TOKEN");

  return {
    dockerRunBaseUrl: env.DOCKER_RUN_BASE_URL,
    dockerRunAccessToken: env.DOCKER_RUN_ACCESS_TOKEN,
  };
}

function ensureNotEmpty(env: StringRecord, field: string) {
  if (!(field in env) || env[field] === "") {
    throw new Error(`Missing env var ${field}`);
  }
}



function isAllowed(request: Request): boolean {
  return hasAllowedOrigin(request) && hasAllowedReferer(request) && supportsBrotli(request);
}

function hasAllowedOrigin(request: Request): boolean {
  const origin = request.headers.get("Origin")
  if (!origin) {
    return false
  }

  return hasAllowedHostname(origin)
}

function hasAllowedReferer(request: Request): boolean {
  const referer = request.headers.get("Referer")
  if (!referer) {
    return false
  }

  return hasAllowedHostname(referer)
}

function hasAllowedHostname(host: string) {
  const allowed = ["glot.io", "beta.glot.io", "glot.pages.dev", "localhost"]

  try {
    const url = new URL(host)
    return allowed.includes(url.hostname)
  } catch (e) {
    return false
  }
}

function supportsBrotli(request: Request): boolean {
  const acceptEncoding = request.headers.get("Accept-Encoding")
  if (!acceptEncoding) {
    return false
  }

  const encodings = acceptEncoding.split(", ")
  return encodings.includes("br") || encodings.some((enc) => enc.startsWith("br;"))
}

function errorResponse(status: number, message: string): Response {
  return new Response(JSON.stringify({ message }), {
    status,
    headers: {
      "Content-Type": "application/json",
    },
  });
}
