import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { componentTagger } from "lovable-tagger";
import { execSync } from "child_process";
import fs from "fs";

function getCommit() {
  if (process.env.VITE_BUILD_COMMIT) return process.env.VITE_BUILD_COMMIT;
  try {
    return execSync("git rev-parse HEAD", { stdio: ["ignore", "pipe", "ignore"] })
      .toString()
      .trim();
  } catch {
    return "unknown";
  }
}

function getCommitShort(full: string) {
  return full && full !== "unknown" ? full.slice(0, 7) : "unknown";
}

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const commit = getCommit();
  const buildTime = new Date().toISOString();
  const imageTag = process.env.VITE_BUILD_TAG || "local";
  const branch = process.env.VITE_BUILD_BRANCH || "main";

  // Emit build-info.json into public/ so it's served at /build-info.json
  try {
    const info = { commit, commitShort: getCommitShort(commit), buildTime, imageTag, branch };
    fs.mkdirSync(path.resolve(__dirname, "public"), { recursive: true });
    fs.writeFileSync(
      path.resolve(__dirname, "public/build-info.json"),
      JSON.stringify(info, null, 2)
    );
  } catch (e) {
    // non-fatal
  }

  return {
    server: {
      host: "::",
      port: 8080,
      hmr: {
        overlay: false,
      },
    },
    plugins: [react(), mode === "development" && componentTagger()].filter(Boolean),
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "./src"),
      },
    },
    define: {
      __BUILD_COMMIT__: JSON.stringify(commit),
      __BUILD_COMMIT_SHORT__: JSON.stringify(getCommitShort(commit)),
      __BUILD_TIME__: JSON.stringify(buildTime),
      __BUILD_TAG__: JSON.stringify(imageTag),
      __BUILD_BRANCH__: JSON.stringify(branch),
    },
  };
});
