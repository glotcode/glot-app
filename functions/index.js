//import wasmModule from "../../pkg/distance.wasm";
import init, { homePage } from "../wasm/glot";

export async function onRequest({ request }) {
  await init("../wasm/glot");

  //const moduleInstance = await WebAssembly.instantiate(wasmModule);
  //const distance = await moduleInstance.exports.distance_between();
  //console.log(moduleInstance.exports);

  return new Response("Hello, world2!");
}
