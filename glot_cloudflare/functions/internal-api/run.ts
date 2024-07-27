import { RequestCounter, RequestStats } from "../../../glot_cloudflare_request_counter/src/request_counter";

type StringRecord = Record<string, string>;

interface Env {
  REQUEST_COUNTER: DurableObjectNamespace<RequestCounter>;
}


export const onRequestPost: PagesFunction<Env & StringRecord> = async (context) => {
  const envVars = parseEnvVars(context.env);

  if (!isAllowed(context.request)) {
    return errorResponse(403, "Forbidden");
  }

  const requestBody = context.request.clone().body;
  const runResponse = run(envVars, requestBody);

  try {
    const ip = getRequestIp(context.request);
    const requestStats = await incrementRequestCount(context.env, context.request, ip);

    if (isRateLimited(envVars, requestStats)) {
      return errorResponse(429, "Rate limit exceeded");
    } else {
      return runResponse;
    }
  } catch (e) {
    console.error("Failed to increment request count", e.message);
    return runResponse;
  }
};

function getRequestIp(request: Request): string {
  if (request.headers.has("CF-Connecting-IP")) {
    return request.headers.get("CF-Connecting-IP")
  } else {
    return "127.0.0.1"
  }
}

async function incrementRequestCount(env: Env, request: Request, ip: string): Promise<RequestStats> {
  const id = env.REQUEST_COUNTER.idFromName(ip);
  const stub = env.REQUEST_COUNTER.get(id);
  const response = await stub.fetch(request);
  return response.json();
}

function isRateLimited(env: EnvVars, stats: RequestStats): boolean {
  return (
    stats.minutely.count > env.maxRequestsPerMinute ||
    stats.hourly.count > env.maxRequestsPerHour ||
    stats.daily.count > env.maxRequestsPerDay
  );
}


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
  maxRequestsPerMinute: number;
  maxRequestsPerHour: number;
  maxRequestsPerDay: number;
}

function parseEnvVars(env: StringRecord): EnvVars {
  return {
    dockerRunBaseUrl: getString(env, "DOCKER_RUN_BASE_URL"),
    dockerRunAccessToken: getString(env, "DOCKER_RUN_ACCESS_TOKEN"),
    maxRequestsPerMinute: getNumber(env, "MAX_REQUESTS_PER_MINUTE"),
    maxRequestsPerHour: getNumber(env, "MAX_REQUESTS_PER_HOUR"),
    maxRequestsPerDay: getNumber(env, "MAX_REQUESTS_PER_DAY"),
  };
}

function ensureNotEmpty(env: StringRecord, field: string) {
  if (!(field in env) || env[field] === "") {
    throw new Error(`Missing env var ${field}`);
  }
}

function ensureInt(env: StringRecord, field: string) {
  ensureNotEmpty(env, field);

  const n = parseInt(env[field], 10);
  if (isNaN(n)) {
    throw new Error(`Invalid number for env var ${field}`);
  }
}

function getString(env: StringRecord, field: string): string {
  ensureNotEmpty(env, field);
  return env[field];
}

function getNumber(env: StringRecord, field: string): number {
  ensureNotEmpty(env, field);
  ensureInt(env, field);

  return parseInt(env[field], 10);
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
