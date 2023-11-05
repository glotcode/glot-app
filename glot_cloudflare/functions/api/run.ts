type StringRecord = Record<string, string>;

export const onRequestPost: PagesFunction<StringRecord> = async (context) => {
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
  ensure_not_empty(env, "DOCKER_RUN_BASE_URL");
  ensure_not_empty(env, "DOCKER_RUN_ACCESS_TOKEN");

  return {
    dockerRunBaseUrl: env.DOCKER_RUN_BASE_URL,
    dockerRunAccessToken: env.DOCKER_RUN_ACCESS_TOKEN,
  };
}

function ensure_not_empty(env: StringRecord, field: string) {
  if (!(field in env) || env[field] === "") {
    throw new Error(`Missing env var ${field}`);
  }
}
