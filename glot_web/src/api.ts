export { sendMagicLink };

function sendMagicLink(email: string): Promise<Response> {
  return fetch("/api/magiclink/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ email }),
  });
}
