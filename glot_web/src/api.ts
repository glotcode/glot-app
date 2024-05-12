export { sendMagicLink, run, getSnippet, createSnippet, login };

async function run(data: any): Promise<unknown> {
  const response = await fetch("/api/run", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  return response.json();
}

async function createSnippet(data: any): Promise<unknown> {
  const response = await fetch("/api/snippets", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  return response.json();
}

async function getSnippet(snippetId: string): Promise<unknown> {
  const url = `/api/snippets/${snippetId}`;
  const response = await fetch(url);
  return response.json();
}

function sendMagicLink(email: string): Promise<Response> {
  return fetch("/api/magiclink/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ email }),
  });
}

function login(token: string): Promise<Response> {
  return fetch("/api/magiclink/login", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ token }),
  });
}
