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

function buildOgHtml({ title, description, image, url, twitterCard, playerUrl, playerWidth, playerHeight }) {
  const esc = (s) =>
    s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');

  const card = twitterCard || 'summary_large_image';

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
  <meta name="twitter:card" content="${esc(card)}" />
  <meta name="twitter:title" content="${esc(title)}" />
  <meta name="twitter:description" content="${esc(description)}" />
  <meta name="twitter:image" content="${esc(image)}" />
  ${playerUrl ? `
  <!-- Twitter Player Card (Interactive Embed) -->
  <meta name="twitter:player" content="${esc(playerUrl)}" />
  <meta name="twitter:player:width" content="${esc(playerWidth || '520')}" />
  <meta name="twitter:player:height" content="${esc(playerHeight || '730')}" />` : ''}

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

// --- Embed page builder for Twitter player card ---

function buildEmbedHtml(info) {
  const typeColors = {
    normal: '#A8A878', fire: '#F08030', water: '#6890F0', electric: '#F8D030',
    grass: '#78C850', ice: '#98D8D8', fighting: '#C03028', poison: '#A040A0',
    ground: '#E0C068', flying: '#A890F0', psychic: '#F85888', bug: '#A8B820',
    rock: '#B8A038', ghost: '#705898', dragon: '#7038F8', dark: '#705848',
    steel: '#B8B8D0', fairy: '#EE99AC',
  };

  const primaryColor = typeColors[info.types[0].toLowerCase()] || '#777';
  const heightM = (info.height / 10).toFixed(1);
  const weightKg = (info.weight / 10).toFixed(1);

  return new Response(
    `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${info.name} - Pokémon Card</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Gill Sans', 'Gill Sans MT', Calibri, sans-serif;
      background: #1a1a1a;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 20px;
    }

    /* Pokemon Card Container */
    .pokemon-card {
      width: 520px;
      height: 730px;
      background: linear-gradient(135deg, #f4e5a8 0%, #e8d284 100%);
      border-radius: 20px;
      padding: 8px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.5), inset 0 0 20px rgba(255,255,255,0.3);
      position: relative;
      overflow: hidden;
    }

    /* Holographic shine effect */
    .pokemon-card::before {
      content: '';
      position: absolute;
      top: -50%;
      left: -50%;
      width: 200%;
      height: 200%;
      background: linear-gradient(45deg,
        transparent 30%,
        rgba(255,255,255,0.1) 40%,
        rgba(255,255,255,0.3) 50%,
        rgba(255,255,255,0.1) 60%,
        transparent 70%);
      animation: shine 8s infinite;
      pointer-events: none;
    }

    @keyframes shine {
      0%, 100% { transform: translate(-50%, -50%) rotate(0deg); }
      50% { transform: translate(50%, 50%) rotate(180deg); }
    }

    /* Card body */
    .card-body {
      background: #f5f0e8;
      height: 100%;
      border-radius: 14px;
      padding: 20px;
      position: relative;
      box-shadow: inset 0 0 10px rgba(0,0,0,0.1);
    }

    /* Header with name and HP */
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 6px;
    }

    .pokemon-name {
      font-size: 32px;
      font-weight: bold;
      color: #333;
      text-shadow: 1px 1px 2px rgba(0,0,0,0.1);
    }

    .hp-display {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 28px;
      font-weight: bold;
      color: #d32f2f;
    }

    .hp-label {
      font-size: 20px;
      font-weight: bold;
    }

    /* Evolution stage */
    .evolution-stage {
      font-size: 13px;
      color: #666;
      margin-bottom: 12px;
      font-weight: 600;
    }

    /* Type badges */
    .type-line {
      display: flex;
      gap: 8px;
      margin-bottom: 12px;
    }

    .type-badge {
      padding: 4px 12px;
      border-radius: 12px;
      color: white;
      font-size: 13px;
      font-weight: bold;
      text-transform: uppercase;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }

    /* Artwork frame */
    .artwork-frame {
      background: linear-gradient(135deg, ${primaryColor}20, ${primaryColor}10);
      border: 3px solid ${primaryColor}40;
      border-radius: 12px;
      padding: 16px;
      margin-bottom: 12px;
      position: relative;
      height: 280px;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
    }

    .artwork-frame::after {
      content: '';
      position: absolute;
      inset: 0;
      background: radial-gradient(circle at 30% 40%, rgba(255,255,255,0.2) 0%, transparent 60%);
      pointer-events: none;
    }

    .artwork-frame img {
      width: 95%;
      height: auto;
      filter: drop-shadow(0 8px 16px rgba(0,0,0,0.2));
      position: relative;
      z-index: 1;
      animation: float 3s ease-in-out infinite;
    }

    @keyframes float {
      0%, 100% { transform: translateY(0px); }
      50% { transform: translateY(-10px); }
    }

    /* Stats section (styled like Pokemon card moves) */
    .stats-section {
      background: white;
      border: 2px solid #ddd;
      border-radius: 10px;
      padding: 14px;
      margin-bottom: 10px;
    }

    .stat-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 6px 0;
      border-bottom: 1px solid #eee;
    }

    .stat-row:last-child { border-bottom: none; }

    .stat-name {
      font-size: 13px;
      font-weight: bold;
      color: #555;
      text-transform: uppercase;
    }

    .stat-value {
      font-size: 20px;
      font-weight: bold;
      color: ${primaryColor};
    }

    .stat-bar {
      flex: 1;
      margin: 0 12px;
      height: 6px;
      background: #eee;
      border-radius: 3px;
      overflow: hidden;
      position: relative;
    }

    .stat-bar-fill {
      height: 100%;
      background: linear-gradient(90deg, ${primaryColor}, ${primaryColor}dd);
      border-radius: 3px;
    }

    /* Abilities section */
    .abilities-section {
      background: white;
      border: 2px solid #ddd;
      border-radius: 10px;
      padding: 12px;
      margin-bottom: 10px;
    }

    .abilities-title {
      font-size: 11px;
      font-weight: bold;
      color: #999;
      text-transform: uppercase;
      margin-bottom: 8px;
      letter-spacing: 0.5px;
    }

    .ability-item {
      font-size: 13px;
      color: #333;
      font-weight: 600;
      padding: 6px 10px;
      background: ${primaryColor}15;
      border-left: 3px solid ${primaryColor};
      border-radius: 4px;
      margin-bottom: 6px;
    }

    .ability-item:last-child { margin-bottom: 0; }

    .ability-hidden {
      opacity: 0.7;
      border-left-color: #999;
    }

    /* Card footer */
    .card-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-top: 8px;
      font-size: 11px;
      color: #666;
    }

    .card-number {
      font-weight: bold;
    }

    .card-info {
      font-weight: 600;
    }

    /* Interactive buttons */
    .cta-buttons {
      position: absolute;
      bottom: 12px;
      left: 12px;
      right: 12px;
      display: flex;
      gap: 8px;
      opacity: 0;
      transition: opacity 0.3s;
    }

    .pokemon-card:hover .cta-buttons {
      opacity: 1;
    }

    .cta-btn {
      flex: 1;
      padding: 12px;
      background: ${primaryColor};
      color: white;
      text-decoration: none;
      text-align: center;
      border-radius: 8px;
      font-size: 13px;
      font-weight: bold;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      transition: all 0.2s;
    }

    .cta-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 16px rgba(0,0,0,0.4);
    }

    .cta-btn.secondary {
      background: white;
      color: ${primaryColor};
      border: 2px solid ${primaryColor};
    }
  </style>
</head>
<body>
  <div class="pokemon-card">
    <div class="card-body">
      <!-- Header: Name and HP -->
      <div class="card-header">
        <div class="pokemon-name">${info.name}</div>
        <div class="hp-display">
          <span class="hp-label">HP</span>
          <span>${info.stats.hp}</span>
        </div>
      </div>

      <!-- Evolution stage -->
      <div class="evolution-stage">Basic Pokémon</div>

      <!-- Type badges (clickable to filter by type) -->
      <div class="type-line">
        ${info.types.map(t => `<a href="${SITE_URL}/?type=${t.toLowerCase()}" target="_top" class="type-badge" style="background: ${typeColors[t.toLowerCase()] || '#777'}; text-decoration: none;">${t}</a>`).join('')}
      </div>

      <!-- Artwork -->
      <div class="artwork-frame">
        <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${info.id}.png" alt="${info.name}">
      </div>

      <!-- Stats (styled like card moves) -->
      <div class="stats-section">
        <div class="stat-row">
          <span class="stat-name">ATK</span>
          <div class="stat-bar"><div class="stat-bar-fill" style="width: ${(info.stats.attack / 255) * 100}%"></div></div>
          <span class="stat-value">${info.stats.attack}</span>
        </div>
        <div class="stat-row">
          <span class="stat-name">DEF</span>
          <div class="stat-bar"><div class="stat-bar-fill" style="width: ${(info.stats.defense / 255) * 100}%"></div></div>
          <span class="stat-value">${info.stats.defense}</span>
        </div>
        <div class="stat-row">
          <span class="stat-name">SPD</span>
          <div class="stat-bar"><div class="stat-bar-fill" style="width: ${(info.stats.speed / 255) * 100}%"></div></div>
          <span class="stat-value">${info.stats.speed}</span>
        </div>
      </div>

      <!-- Abilities -->
      <div class="abilities-section">
        <div class="abilities-title">Abilities</div>
        ${info.abilities.map(a => `<div class="ability-item">${a}</div>`).join('')}
        ${info.hiddenAbility ? `<div class="ability-item ability-hidden">${info.hiddenAbility} (Hidden)</div>` : ''}
      </div>

      <!-- Card footer -->
      <div class="card-footer">
        <span class="card-number">#${String(info.id).padStart(3, '0')}</span>
        <span class="card-info">${heightM}m • ${weightKg}kg • BST ${info.bst}</span>
      </div>

      <!-- Interactive buttons (show on hover) -->
      <div class="cta-buttons">
        <a href="${SITE_URL}/pokemon/${info.id}" class="cta-btn" target="_top">View Full Entry</a>
        <a href="${SITE_URL}/team-builder?add=${info.id}" class="cta-btn secondary" target="_top">Add to Team</a>
      </div>
    </div>
  </div>
</body>
</html>`,
    {
      status: 200,
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=3600',
        'X-Frame-Options': 'ALLOW-FROM https://twitter.com',
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
    // Twitter player card for interactive embed
    twitterCard: 'player',
    playerUrl: `${SITE_URL}/embed/pokemon/${id}`,
    playerWidth: '480',
    playerHeight: '600',
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
  const url = new URL(request.url);
  const path = url.pathname;
  let match;

  // /embed/pokemon/:id - Twitter player card (serve to everyone, not just crawlers)
  match = path.match(/^\/embed\/pokemon\/(\d+)$/);
  if (match && request.method === 'GET') {
    const id = parseInt(match[1], 10);
    const info = await fetchPokemonInfo(id);
    if (!info) {
      return new Response('Pokemon not found', { status: 404 });
    }

    // Track embed view
    logAnalytics(context, {
      event: 'embed_view',
      pokemon_id: id,
      pokemon_name: info.name,
    });

    return buildEmbedHtml(info);
  }

  // Only intercept other GET requests from crawlers
  if (request.method !== 'GET' || !isCrawler(request)) {
    return context.next();
  }

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
