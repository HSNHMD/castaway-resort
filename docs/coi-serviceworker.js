/* coi-serviceworker — adds COOP/COEP headers on GitHub Pages for Godot web exports */
if (typeof window === "undefined") {
  self.addEventListener("install", () => self.skipWaiting());
  self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));
  self.addEventListener("fetch", (e) => {
    if (e.request.cache === "only-if-cached" && e.request.mode !== "same-origin") return;
    e.respondWith(
      fetch(e.request).then((r) => {
        if (r.status === 0) return r;
        const h = new Headers(r.headers);
        h.set("Cross-Origin-Opener-Policy", "same-origin");
        h.set("Cross-Origin-Embedder-Policy", "require-corp");
        h.set("Cross-Origin-Resource-Policy", "cross-origin");
        return new Response(r.body, { status: r.status, statusText: r.statusText, headers: h });
      })
    );
  });
} else {
  const reloaded = sessionStorage.getItem("coiReloaded");
  sessionStorage.removeItem("coiReloaded");
  if (!window.crossOriginIsolated && !reloaded && "serviceWorker" in navigator) {
    navigator.serviceWorker.register(document.currentScript.src).then((reg) => {
      const sw = reg.installing || reg.waiting || reg.active;
      const reload = () => { sessionStorage.setItem("coiReloaded", "1"); location.reload(); };
      if (sw.state === "activated") {
        reload();
      } else {
        sw.addEventListener("statechange", (e) => { if (e.target.state === "activated") reload(); });
      }
    }).catch((e) => console.warn("coi-serviceworker:", e));
  }
}
