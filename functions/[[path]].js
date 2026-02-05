/**
 * DexGuide — Cloudflare Pages Function (catch-all)
 *
 * Runs on every request to dexguide.gg. Two jobs:
 *
 * 1. CRAWLER REQUESTS: Returns a small HTML page with correct Open Graph
 *    meta tags so link previews in iMessage, Slack, Discord, Twitter,
 *    Facebook etc. show the right Pokemon artwork, name, and description.
 *
 * 2. REGULAR USERS: Falls through to static assets. If no static file
 *    matches (SPA deep link like /pokemon/6), the _redirects rule
 *    serves index.html so Flutter's router handles it client-side.
 *
 * No copyrighted assets stored — OG image URLs point to PokeAPI's
 * hosted artwork on GitHub.
 */

const SITE_NAME = 'DexGuide';
const SITE_URL = 'https://dexguide.gg';
const DEFAULT_DESCRIPTION =
  'Your free Pokemon database. Stats, moves, type matchups, team builder, and more for all 1025 Pokemon.';

// PokeAPI official artwork — hosted by PokeAPI on GitHub, not by us
const ARTWORK_URL = (id) =>
  `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${id}.png`;

const DEFAULT_IMAGE = ARTWORK_URL(25); // Pikachu fallback

// --- Crawler detection ---

const CRAWLER_UA_PATTERNS = [
  'facebookexternalhit',
  'Facebot',
  'Twitterbot',
  'WhatsApp',
  'Slackbot',
  'LinkedInBot',
  'Discordbot',
  'TelegramBot',
  'Applebot',
  'Googlebot',
  'bingbot',
  'Pinterestbot',
  'redditbot',
  'Embedly',
  'Quora Link Preview',
  'Showyoubot',
  'outbrain',
  'vkShare',
  'W3C_Validator',
  'Iframely',
];

function isCrawler(request) {
  const ua = request.headers.get('User-Agent') || '';
  if (CRAWLER_UA_PATTERNS.some((p) => ua.toLowerCase().includes(p.toLowerCase()))) {
    return true;
  }
  const purpose = request.headers.get('Purpose') || request.headers.get('X-Purpose') || '';
  if (purpose.toLowerCase() === 'preview') {
    return true;
  }
  return false;
}

// --- Helpers ---

function formatPokemonName(name) {
  return name
    .split('-')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

function padId(id) {
  return String(id).padStart(3, '0');
}

// --- PokeAPI fetch with Cloudflare edge caching ---

async function fetchPokemonInfo(id) {
  try {
    const resp = await fetch(`https://pokeapi.co/api/v2/pokemon/${id}`, {
      cf: { cacheTtl: 604800, cacheEverything: true }, // 7 days
    });
    if (!resp.ok) return null;
    const data = await resp.json();

    let displayName = formatPokemonName(data.name);
    try {
      const speciesResp = await fetch(data.species.url, {
        cf: { cacheTtl: 604800, cacheEverything: true },
      });
      if (speciesResp.ok) {
        const species = await speciesResp.json();
        const en = species.names?.find((n) => n.language.name === 'en');
        if (en) displayName = en.name;
      }
    } catch {
      // Fall back to formatted API name
    }

    const types = data.types.map((t) => formatPokemonName(t.type.name));
    return { name: displayName, types, id: data.id };
  } catch {
    return null;
  }
}

// --- OG HTML builder ---

function buildOgHtml({ title, description, image, url }) {
  const esc = (s) =>
    s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');

  return new Response(
    `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>${esc(title)}</title>

  <!-- Open Graph -->
  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="${esc(SITE_NAME)}" />
  <meta property="og:title" content="${esc(title)}" />
  <meta property="og:description" content="${esc(description)}" />
  <meta property="og:image" content="${esc(image)}" />
  <meta property="og:url" content="${esc(url)}" />

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${esc(title)}" />
  <meta name="twitter:description" content="${esc(description)}" />
  <meta name="twitter:image" content="${esc(image)}" />

  <!-- Redirect real users who somehow land here -->
  <meta http-equiv="refresh" content="0;url=${esc(url)}" />
</head>
<body>
  <p>Redirecting to <a href="${esc(url)}">${esc(SITE_NAME)}</a>...</p>
</body>
</html>`,
    {
      status: 200,
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=3600',
      },
    }
  );
}

// --- Route handlers ---

async function handlePokemonRoute(id) {
  const info = await fetchPokemonInfo(id);
  if (!info) {
    return buildOgHtml({
      title: `Pokemon #${padId(id)} — ${SITE_NAME}`,
      description: DEFAULT_DESCRIPTION,
      image: ARTWORK_URL(id),
      url: `${SITE_URL}/pokemon/${id}`,
    });
  }

  const typeStr = info.types.join(' / ');
  return buildOgHtml({
    title: `${info.name} #${padId(info.id)} — ${SITE_NAME}`,
    description: `${info.name} is a ${typeStr} type Pokemon. View stats, moves, abilities, evolution chain, and type matchups.`,
    image: ARTWORK_URL(info.id),
    url: `${SITE_URL}/pokemon/${id}`,
  });
}

async function handleBattleRoute(id1, id2) {
  const [info1, info2] = await Promise.all([
    fetchPokemonInfo(id1),
    fetchPokemonInfo(id2),
  ]);

  const name1 = info1 ? info1.name : `#${padId(id1)}`;
  const name2 = info2 ? info2.name : `#${padId(id2)}`;

  return buildOgHtml({
    title: `${name1} vs ${name2} — Head to Head — ${SITE_NAME}`,
    description: `Compare ${name1} and ${name2} head to head. Type matchups, base stats, moves, and matchup analysis.`,
    image: ARTWORK_URL(id1),
    url: `${SITE_URL}/battle/${id1}/${id2}`,
  });
}

function handleTypeMatchupRoute(atk, def) {
  const atkName = formatPokemonName(atk);
  const defName = formatPokemonName(def);

  return buildOgHtml({
    title: `${atkName} vs ${defName} — Type Matchup — ${SITE_NAME}`,
    description: `See how ${atkName} type attacks fare against ${defName} type defenders. Effectiveness multipliers and analysis.`,
    image: DEFAULT_IMAGE,
    url: `${SITE_URL}/types/${atk}/vs/${def}`,
  });
}

function handleDefault(path) {
  return buildOgHtml({
    title: SITE_NAME,
    description: DEFAULT_DESCRIPTION,
    image: DEFAULT_IMAGE,
    url: `${SITE_URL}${path}`,
  });
}

// --- Pages Function entry point ---

export async function onRequest(context) {
  const { request } = context;

  // Only intercept GET requests from crawlers
  if (request.method !== 'GET' || !isCrawler(request)) {
    return context.next();
  }

  const url = new URL(request.url);
  const path = url.pathname;
  let match;

  // /pokemon/:id
  match = path.match(/^\/pokemon\/(\d+)$/);
  if (match) {
    return handlePokemonRoute(parseInt(match[1], 10));
  }

  // /battle/:id1/:id2
  match = path.match(/^\/battle\/(\d+)\/(\d+)$/);
  if (match) {
    return handleBattleRoute(
      parseInt(match[1], 10),
      parseInt(match[2], 10)
    );
  }

  // /types/:atk/vs/:def
  match = path.match(/^\/types\/([a-z]+)\/vs\/([a-z]+)$/);
  if (match) {
    return handleTypeMatchupRoute(match[1], match[2]);
  }

  // All other crawler requests — generic OG tags
  return handleDefault(path);
}
