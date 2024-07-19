type StringRecord = Record<string, string>;


export const onRequestPost: PagesFunction<StringRecord> = async (context) => {
  if (!isAllowed(context.request)) {
    const body = JSON.stringify({ message: "Forbidden" })
    return new Response(body, {
      status: 403,
      headers: {
        "Content-Type": "application/json",
      },
    })
  }

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
  const allowed = ["glot.io", "glot.pages.dev", "localhost"]

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