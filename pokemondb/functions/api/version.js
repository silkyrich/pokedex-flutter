// Version info endpoint - returns build metadata for deployment verification

export async function onRequest(context) {
  // Try to fetch the build-time generated version.json
  let buildInfo = {};
  try {
    const versionResponse = await context.env.ASSETS.fetch(new Request(`${context.request.url.origin}/version.json`));
    if (versionResponse.ok) {
      buildInfo = await versionResponse.json();
    }
  } catch (e) {
    // version.json not found, use env vars
  }

  // Combine build-time info with runtime env vars
  const versionInfo = {
    ...buildInfo,
    // Runtime Cloudflare Pages environment info
    cfCommitSha: context.env.CF_PAGES_COMMIT_SHA || buildInfo.gitCommit || "unknown",
    cfBranch: context.env.CF_PAGES_BRANCH || buildInfo.gitBranch || "unknown",
    cfUrl: context.env.CF_PAGES_URL || "unknown",
    environment: context.env.CF_PAGES_BRANCH === "main" ? "production" : "preview",
    deployedAt: context.env.CF_PAGES_COMMIT_SHA ? new Date().toISOString() : buildInfo.buildTime,
  };

  return new Response(JSON.stringify(versionInfo, null, 2), {
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-cache, no-store, must-revalidate",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
