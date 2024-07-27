export { run };

async function run(data: any): Promise<unknown> {
  const response = await fetch("/internal-api/run", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  return response.json();
}