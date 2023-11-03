export async function onRequestPost({ request, env }) {
  const envVars = parseEnvVars(env);
  const runRequest = await request.json();
  const response = await run(envVars, runRequest);

  return new Response(response.body, {
    headers: {
      "content-type": "application/json",
    },
  });
}

async function run(env: EnvVars, runRequest) {
  return fetch(`${env.dockerRunBaseUrl}/run`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Access-Token": env.dockerRunAccessToken,
    },
    body: JSON.stringify(runRequest),
  });
}

interface EnvVars {
  dockerRunBaseUrl: string;
  dockerRunAccessToken: string;
}

function parseEnvVars(env: any): EnvVars {
  ensure_not_empty(env, "DOCKER_RUN_BASE_URL");
  ensure_not_empty(env, "DOCKER_RUN_ACCESS_TOKEN");

  return {
    dockerRunBaseUrl: env.DOCKER_RUN_BASE_URL,
    dockerRunAccessToken: env.DOCKER_RUN_ACCESS_TOKEN,
  };
}

function ensure_not_empty(env: object, field: string) {
  if (!(field in env) || env[field] === "") {
    throw new Error(`Missing env var ${field}`);
  }
}
