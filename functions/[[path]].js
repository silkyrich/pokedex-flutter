/**
 * DexGuide — Cloudflare Pages Function (catch-all)
 *
 * Runs on every request to dexguide.gg. Three jobs:
 *
 * 1. CRAWLER REQUESTS: Returns a small HTML page with correct Open Graph
 *    meta tags so link previews in iMessage, Slack, Discord, Twitter,
 *    Facebook etc. show the right Pokemon artwork, name, and stats.
 *
 * 2. ANALYTICS TRACKING: Logs every OG card view with rich metadata
 *    (Pokemon ID, types, BST, social platform, country) for measuring
 *    viral spread and understanding sharing patterns.
 *
 * 3. REGULAR USERS: Falls through to static assets. If no static file
 *    matches (SPA deep link like /pokemon/6), the _redirects rule
 *    serves index.html so Flutter's router handles it client-side.
 *
 * TODO: Generate custom OG images with gold Pokemon card border
 *       Currently using direct PokeAPI artwork URLs
 *       Could use Cloudflare Images API or Workers to add border
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

// --- Analytics Tracking ---

function logAnalytics(context, data) {
  const { request } = context;
  const url = new URL(request.url);

  // Extract tracking metadata
  const tracking = {
    ...data,
    timestamp: new Date().toISOString(),
    url: url.pathname,
    referrer: request.headers.get('Referer') || null,
    user_agent: request.headers.get('User-Agent') || null,
    country: request.cf?.country || null,
    city: request.cf?.city || null,
    // Social platform detection
    platform: detectSocialPlatform(request.headers.get('User-Agent') || ''),
  };

  // Log to Cloudflare Analytics (if available in context)
  if (context.env?.ANALYTICS) {
    context.env.ANALYTICS.writeDataPoint(tracking);
  }

  // Also log to console for debugging (shows in Cloudflare dashboard)
  console.log('[OG Analytics]', JSON.stringify(tracking));
}

function detectSocialPlatform(ua) {
  const lower = ua.toLowerCase();
  if (lower.includes('facebookexternalhit') || lower.includes('facebot')) return 'facebook';
  if (lower.includes('twitterbot')) return 'twitter';
  if (lower.includes('whatsapp')) return 'whatsapp';
  if (lower.includes('slackbot')) return 'slack';
  if (lower.includes('linkedinbot')) return 'linkedin';
  if (lower.includes('discordbot')) return 'discord';
  if (lower.includes('telegrambot')) return 'telegram';
  if (lower.includes('applebot')) return 'imessage';
  return 'unknown';
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

    // Pull stats for rich OG cards
    const stats = {};
    data.stats.forEach((s) => {
      stats[s.stat.name] = s.base_stat;
    });
    const bst = Object.values(stats).reduce((sum, val) => sum + val, 0);

    // Pull abilities
    const abilities = data.abilities
      .filter((a) => !a.is_hidden) // Non-hidden abilities only for OG card
      .map((a) => formatPokemonName(a.ability.name));
    const hiddenAbility = data.abilities.find((a) => a.is_hidden);

    return {
      name: displayName,
      types,
      id: data.id,
      stats,
      bst,
      abilities,
      hiddenAbility: hiddenAbility ? formatPokemonName(hiddenAbility.ability.name) : null,
      height: data.height,
      weight: data.weight,
    };
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

async function handlePokemonRoute(id, context) {
  const info = await fetchPokemonInfo(id);
  if (!info) {
    // Track failed lookup
    logAnalytics(context, {
      event: 'og_card_404',
      pokemon_id: id,
    });

    return buildOgHtml({
      title: `Pokemon #${padId(id)} — ${SITE_NAME}`,
      description: DEFAULT_DESCRIPTION,
      image: ARTWORK_URL(id),
      url: `${SITE_URL}/pokemon/${id}`,
    });
  }

  // Track OG card view with rich metadata
  logAnalytics(context, {
    event: 'og_card_view',
    pokemon_id: info.id,
    pokemon_name: info.name,
    types: info.types.join(','),
    bst: info.bst,
  });

  const typeStr = info.types.join(' / ');
  const heightM = (info.height / 10).toFixed(1);
  const weightKg = (info.weight / 10).toFixed(1);

  // Rich description with stats and abilities
  const description =
    `${info.name} • ${typeStr} type\n` +
    `HP ${info.stats.hp} • ATK ${info.stats.attack} • DEF ${info.stats.defense} • BST ${info.bst}\n` +
    `Abilities: ${info.abilities.join(', ')}${info.hiddenAbility ? ` • Hidden: ${info.hiddenAbility}` : ''}\n` +
    `${heightM}m tall, ${weightKg}kg`;

  return buildOgHtml({
    title: `${info.name} #${padId(info.id)} — ${SITE_NAME}`,
    description,
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

  // Log all crawler requests
  logAnalytics(context, {
    event: 'crawler_request',
    path: path,
  });

  // /pokemon/:id
  match = path.match(/^\/pokemon\/(\d+)$/);
  if (match) {
    return handlePokemonRoute(parseInt(match[1], 10), context);
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
