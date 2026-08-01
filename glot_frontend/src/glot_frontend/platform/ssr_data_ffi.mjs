export function take(elementId) {
  if (typeof document === "undefined") {
    return "";
  }

  const data = document.getElementById(elementId);
  if (!data) {
    return "";
  }

  const value = data.textContent ?? "";
  data.remove();
  return value;
}
