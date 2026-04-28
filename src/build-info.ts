// Build metadata injected by Vite at build time (see vite.config.ts).
declare const __BUILD_COMMIT__: string;
declare const __BUILD_COMMIT_SHORT__: string;
declare const __BUILD_TIME__: string;
declare const __BUILD_TAG__: string;
declare const __BUILD_BRANCH__: string;

export interface BuildInfo {
  commit: string;
  commitShort: string;
  buildTime: string;
  imageTag: string;
  branch: string;
}

export const BUNDLED_BUILD_INFO: BuildInfo = {
  commit: typeof __BUILD_COMMIT__ !== "undefined" ? __BUILD_COMMIT__ : "unknown",
  commitShort: typeof __BUILD_COMMIT_SHORT__ !== "undefined" ? __BUILD_COMMIT_SHORT__ : "unknown",
  buildTime: typeof __BUILD_TIME__ !== "undefined" ? __BUILD_TIME__ : "unknown",
  imageTag: typeof __BUILD_TAG__ !== "undefined" ? __BUILD_TAG__ : "local",
  branch: typeof __BUILD_BRANCH__ !== "undefined" ? __BUILD_BRANCH__ : "main",
};

export async function fetchServerBuildInfo(): Promise<BuildInfo> {
  // Cache-bust to ensure we read what the live server is actually serving
  const res = await fetch(`/build-info.json?t=${Date.now()}`, {
    cache: "no-store",
    headers: { "Cache-Control": "no-cache" },
  });
  if (!res.ok) {
    throw new Error(`Server returned ${res.status} when fetching /build-info.json`);
  }
  const data = (await res.json()) as Partial<BuildInfo>;
  return {
    commit: data.commit || "unknown",
    commitShort: data.commitShort || (data.commit ? data.commit.slice(0, 7) : "unknown"),
    buildTime: data.buildTime || "unknown",
    imageTag: data.imageTag || "unknown",
    branch: data.branch || "unknown",
  };
}
