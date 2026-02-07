/**
 * DexGuide — Cloudflare Pages Function (catch-all)
 *
 * Runs on every request to dexguide.gg. Four jobs:
 *
 * 1. OG IMAGE GENERATION: /og/pokemon/:id.png renders a beautiful
 *    type-colored card image via satori + resvg (workers-og). Cached
 *    at the edge for 7 days. Used as og:image for rich link previews.
 *
 * 2. CRAWLER REQUESTS: Returns a small HTML page with correct Open Graph
 *    meta tags so link previews in iMessage, Slack, Discord, Twitter,
 *    Facebook etc. show the right Pokemon artwork, name, and stats.
 *
 * 3. ANALYTICS TRACKING: Logs every OG card view with rich metadata
 *    (Pokemon ID, types, BST, social platform, country) for measuring
 *    viral spread and understanding sharing patterns.
 *
 * 4. REGULAR USERS: Falls through to static assets. If no static file
 *    matches (SPA deep link like /pokemon/6), the _redirects rule
 *    serves index.html so Flutter's router handles it client-side.
 *
 * No copyrighted assets stored — OG image URLs point to PokeAPI's
 * hosted artwork on GitHub.
 */

import { ImageResponse, loadGoogleFont } from 'workers-og';

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
    let flavorText = null;
    let genus = null;
    try {
      const speciesResp = await fetch(data.species.url, {
        cf: { cacheTtl: 604800, cacheEverything: true },
      });
      if (speciesResp.ok) {
        const species = await speciesResp.json();
        const en = species.names?.find((n) => n.language.name === 'en');
        if (en) displayName = en.name;
        // Grab the genus (e.g. "Worm Pokémon")
        const genusEntry = species.genera?.find((g) => g.language.name === 'en');
        if (genusEntry) genus = genusEntry.genus;
        // Grab a flavor text — prefer recent English entries
        const flavorEntries = (species.flavor_text_entries || [])
          .filter((f) => f.language.name === 'en');
        if (flavorEntries.length > 0) {
          // Pick the last entry (most recent game) and clean up whitespace
          flavorText = flavorEntries[flavorEntries.length - 1].flavor_text
            .replace(/[\n\r\f]/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();
        }
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
      flavorText,
      genus,
    };
  } catch {
    return null;
  }
}

// --- OG image generation (satori + resvg via workers-og) ---

const TYPE_COLORS = {
  normal:   { bg: '#A8A77A', dark: '#6D6D4E' },
  fire:     { bg: '#EE8130', dark: '#9C531F' },
  water:    { bg: '#6390F0', dark: '#445E9C' },
  electric: { bg: '#F7D02C', dark: '#A1871F' },
  grass:    { bg: '#7AC74C', dark: '#4E8234' },
  ice:      { bg: '#96D9D6', dark: '#638D8B' },
  fighting: { bg: '#C22E28', dark: '#7D1F1A' },
  poison:   { bg: '#A33EA1', dark: '#6B2669' },
  ground:   { bg: '#E2BF65', dark: '#927D44' },
  flying:   { bg: '#A98FF3', dark: '#6D5E9C' },
  psychic:  { bg: '#F95587', dark: '#A13959' },
  bug:      { bg: '#A6B91A', dark: '#6D7815' },
  rock:     { bg: '#B6A136', dark: '#786824' },
  ghost:    { bg: '#735797', dark: '#493963' },
  dragon:   { bg: '#6F35FC', dark: '#4924A1' },
  dark:     { bg: '#705746', dark: '#49392F' },
  steel:    { bg: '#B7B7CE', dark: '#787887' },
  fairy:    { bg: '#D685AD', dark: '#9B6470' },
};

/**
 * Generates a 1200x630 PNG card image for a Pokemon.
 * Used as og:image for rich link previews everywhere.
 */
async function generateOgImage(info) {
  const primaryType = info.types[0].toLowerCase();
  const secondaryType = info.types.length > 1 ? info.types[1].toLowerCase() : null;
  const primary = TYPE_COLORS[primaryType] || TYPE_COLORS.normal;
  const secondary = secondaryType ? (TYPE_COLORS[secondaryType] || primary) : primary;
  const heightM = (info.height / 10).toFixed(1);
  const weightKg = (info.weight / 10).toFixed(1);

  const artworkUrl = ARTWORK_URL(info.id);

  // Load two font weights for visual hierarchy
  const [fontRegular, fontBold] = await Promise.all([
    loadGoogleFont({ family: 'Inter', weight: 400 }),
    loadGoogleFont({ family: 'Inter', weight: 700 }),
  ]);

  // Stat bar helper — returns an HTML string for a single stat row
  const statBar = (label, value, max = 255) => {
    const pct = Math.min((value / max) * 100, 100);
    return `
      <div style="display: flex; align-items: center; gap: 8px; width: 100%;">
        <div style="display: flex; font-size: 16px; color: rgba(255,255,255,0.7); width: 36px; justify-content: flex-end;">${label}</div>
        <div style="display: flex; flex: 1; height: 8px; background: rgba(0,0,0,0.3); border-radius: 4px; overflow: hidden;">
          <div style="display: flex; width: ${pct}%; height: 100%; background: white; border-radius: 4px;"></div>
        </div>
        <div style="display: flex; font-size: 18px; font-weight: 700; color: white; width: 36px;">${value}</div>
      </div>`;
  };

  // Type badge helper
  const typeBadge = (typeName) => {
    const tc = TYPE_COLORS[typeName.toLowerCase()] || TYPE_COLORS.normal;
    return `<div style="display: flex; background: ${tc.bg}; border: 2px solid rgba(255,255,255,0.4); border-radius: 20px; padding: 6px 18px; font-size: 18px; font-weight: 700; color: white; text-transform: uppercase; letter-spacing: 1px; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));">${typeName}</div>`;
  };

  const html = `
    <div style="display: flex; width: 1200px; height: 630px; background: linear-gradient(135deg, ${primary.bg}, ${secondary.bg}, ${primary.dark}); font-family: 'Inter', sans-serif; color: white; position: relative; overflow: hidden;">

      <!-- Subtle pokeball watermark -->
      <div style="display: flex; position: absolute; top: -80px; right: -80px; width: 400px; height: 400px; border-radius: 200px; border: 40px solid rgba(255,255,255,0.06);"></div>
      <div style="display: flex; position: absolute; top: 80px; right: 80px; width: 80px; height: 80px; border-radius: 40px; border: 20px solid rgba(255,255,255,0.06);"></div>

      <!-- Left side: Info -->
      <div style="display: flex; flex-direction: column; justify-content: center; padding: 56px 0 56px 56px; flex: 1;">

        <!-- ID number -->
        <div style="display: flex; font-size: 22px; color: rgba(255,255,255,0.5); font-weight: 700; margin-bottom: 4px;">#${String(info.id).padStart(3, '0')}</div>

        <!-- Name -->
        <div style="display: flex; font-size: 64px; font-weight: 700; color: white; margin-bottom: 16px; filter: drop-shadow(0 2px 8px rgba(0,0,0,0.3));">${info.name}</div>

        <!-- Genus -->
        ${info.genus ? `<div style="display: flex; font-size: 20px; color: rgba(255,255,255,0.7); margin-bottom: 20px; font-style: italic;">${info.genus}</div>` : ''}

        <!-- Type badges -->
        <div style="display: flex; gap: 10px; margin-bottom: 28px;">
          ${info.types.map(t => typeBadge(t)).join('')}
        </div>

        <!-- Stats -->
        <div style="display: flex; flex-direction: column; gap: 6px; width: 340px;">
          ${statBar('HP', info.stats.hp)}
          ${statBar('ATK', info.stats.attack)}
          ${statBar('DEF', info.stats.defense)}
          ${statBar('SPA', info.stats['special-attack'])}
          ${statBar('SPD', info.stats['special-defense'])}
          ${statBar('SPE', info.stats.speed)}
        </div>

        <!-- BST + physical -->
        <div style="display: flex; gap: 16px; margin-top: 16px; font-size: 15px; color: rgba(255,255,255,0.5);">
          <div style="display: flex;">BST ${info.bst}</div>
          <div style="display: flex;">${heightM}m</div>
          <div style="display: flex;">${weightKg}kg</div>
        </div>
      </div>

      <!-- Right side: Artwork -->
      <div style="display: flex; align-items: center; justify-content: center; width: 480px; padding: 40px;">
        <img src="${artworkUrl}" width="400" height="400" style="display: flex; filter: drop-shadow(0 12px 32px rgba(0,0,0,0.5));" />
      </div>

      <!-- DexGuide branding bar -->
      <div style="display: flex; position: absolute; bottom: 0; left: 0; right: 0; height: 40px; background: rgba(0,0,0,0.3); align-items: center; justify-content: space-between; padding: 0 56px;">
        <div style="display: flex; font-size: 16px; font-weight: 700; color: rgba(255,255,255,0.6);">DexGuide</div>
        <div style="display: flex; font-size: 14px; color: rgba(255,255,255,0.4);">dexguide.gg</div>
      </div>
    </div>`;

  return new ImageResponse(html, {
    width: 1200,
    height: 630,
    fonts: [
      { name: 'Inter', data: fontRegular, weight: 400, style: 'normal' },
      { name: 'Inter', data: fontBold, weight: 700, style: 'normal' },
    ],
  });
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
      background: #2a2a2a;
      padding: 12px;
    }

    /* Simple Pokemon Card */
    .card {
      background: linear-gradient(135deg, #f4e5a8 0%, #e8d284 100%);
      border-radius: 16px;
      padding: 6px;
      box-shadow: 0 8px 24px rgba(0,0,0,0.4);
    }

    .card-inner {
      background: #f5f0e8;
      border-radius: 12px;
      padding: 16px;
    }

    /* Header */
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }

    .name {
      font-size: 28px;
      font-weight: bold;
      color: #333;
    }

    .hp {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 24px;
      font-weight: bold;
      color: #d32f2f;
    }

    .stage {
      font-size: 12px;
      color: #666;
      margin-bottom: 10px;
    }

    /* Types */
    .types {
      display: flex;
      gap: 6px;
      margin-bottom: 10px;
    }

    .type {
      padding: 4px 10px;
      border-radius: 10px;
      color: white;
      font-size: 11px;
      font-weight: bold;
      text-transform: uppercase;
      text-decoration: none;
      display: inline-block;
    }

    /* Artwork */
    .artwork {
      background: linear-gradient(135deg, ${primaryColor}20, ${primaryColor}10);
      border: 2px solid ${primaryColor}40;
      border-radius: 10px;
      padding: 12px;
      margin-bottom: 10px;
      text-align: center;
      height: 240px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .artwork img {
      max-width: 90%;
      max-height: 90%;
      filter: drop-shadow(0 4px 8px rgba(0,0,0,0.15));
    }

    /* Stats */
    .stats {
      background: white;
      border: 2px solid #ddd;
      border-radius: 8px;
      padding: 10px;
      margin-bottom: 8px;
    }

    .stat {
      display: flex;
      align-items: center;
      padding: 4px 0;
      gap: 8px;
    }

    .stat-name {
      font-size: 11px;
      font-weight: bold;
      color: #555;
      min-width: 40px;
    }

    .stat-bar {
      flex: 1;
      height: 5px;
      background: #eee;
      border-radius: 3px;
      overflow: hidden;
    }

    .stat-fill {
      height: 100%;
      background: ${primaryColor};
    }

    .stat-value {
      font-size: 16px;
      font-weight: bold;
      color: ${primaryColor};
      min-width: 35px;
      text-align: right;
    }

    /* Abilities */
    .abilities {
      background: white;
      border: 2px solid #ddd;
      border-radius: 8px;
      padding: 10px;
      margin-bottom: 8px;
    }

    .abilities-title {
      font-size: 10px;
      font-weight: bold;
      color: #999;
      text-transform: uppercase;
      margin-bottom: 6px;
    }

    .ability {
      font-size: 11px;
      color: #333;
      font-weight: 600;
      padding: 5px 8px;
      background: ${primaryColor}15;
      border-left: 3px solid ${primaryColor};
      border-radius: 3px;
      margin-bottom: 4px;
    }

    .ability:last-child { margin-bottom: 0; }

    /* Footer */
    .footer {
      display: flex;
      justify-content: space-between;
      font-size: 10px;
      color: #666;
      padding-top: 6px;
    }

    .footer span { font-weight: 600; }

    /* Buttons */
    .buttons {
      display: flex;
      gap: 6px;
      margin-top: 10px;
    }

    .btn {
      flex: 1;
      padding: 10px;
      background: ${primaryColor};
      color: white;
      text-decoration: none;
      text-align: center;
      border-radius: 6px;
      font-size: 12px;
      font-weight: bold;
      display: block;
    }

    .btn.secondary {
      background: white;
      color: ${primaryColor};
      border: 2px solid ${primaryColor};
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="card-inner">
      <div class="header">
        <div class="name">${info.name}</div>
        <div class="hp"><span style="font-size:18px">HP</span> ${info.stats.hp}</div>
      </div>

      <div class="stage">Basic Pokémon</div>

      <div class="types">
        ${info.types.map(t => `<a href="${SITE_URL}/?type=${t.toLowerCase()}" target="_top" class="type" style="background: ${typeColors[t.toLowerCase()] || '#777'}">${t}</a>`).join('')}
      </div>

      <div class="artwork">
        <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${info.id}.png" alt="${info.name}">
      </div>

      <div class="stats">
        <div class="stat">
          <span class="stat-name">ATK</span>
          <div class="stat-bar"><div class="stat-fill" style="width: ${(info.stats.attack / 255) * 100}%"></div></div>
          <span class="stat-value">${info.stats.attack}</span>
        </div>
        <div class="stat">
          <span class="stat-name">DEF</span>
          <div class="stat-bar"><div class="stat-fill" style="width: ${(info.stats.defense / 255) * 100}%"></div></div>
          <span class="stat-value">${info.stats.defense}</span>
        </div>
        <div class="stat">
          <span class="stat-name">SPD</span>
          <div class="stat-bar"><div class="stat-fill" style="width: ${(info.stats.speed / 255) * 100}%"></div></div>
          <span class="stat-value">${info.stats.speed}</span>
        </div>
      </div>

      <div class="abilities">
        <div class="abilities-title">Abilities</div>
        ${info.abilities.map(a => `<div class="ability">${a}</div>`).join('')}
        ${info.hiddenAbility ? `<div class="ability">${info.hiddenAbility} (Hidden)</div>` : ''}
      </div>

      <div class="footer">
        <span>#${String(info.id).padStart(3, '0')}</span>
        <span>${heightM}m • ${weightKg}kg • BST ${info.bst}</span>
      </div>

      <div class="buttons">
        <a href="${SITE_URL}/pokemon/${info.id}" class="btn" target="_top">View Details</a>
        <a href="${SITE_URL}/team-builder?add=${info.id}" class="btn secondary" target="_top">Add to Team</a>
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

  // Lead with the Pokedex flavor text — that's the hook.
  // Fall back to a compact stat summary if flavor text is unavailable.
  let description;
  if (info.flavorText) {
    const genusLine = info.genus ? `The ${info.genus}. ` : '';
    description = `${genusLine}${info.flavorText} — ${typeStr} type, BST ${info.bst}.`;
  } else {
    const heightM = (info.height / 10).toFixed(1);
    const weightKg = (info.weight / 10).toFixed(1);
    description =
      `${typeStr} type · BST ${info.bst} · ${heightM}m · ${weightKg}kg. ` +
      `Stats, moves, matchups, and more on DexGuide.`;
  }

  return buildOgHtml({
    title: `${info.name} #${padId(info.id)} — ${SITE_NAME}`,
    description,
    image: `${SITE_URL}/og/pokemon/${info.id}.png`,
    url: `${SITE_URL}/pokemon/${id}`,
    twitterCard: 'summary_large_image',
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

  // /og/pokemon/:id.png — Generated OG card image (serve to everyone)
  match = path.match(/^\/og\/pokemon\/(\d+)\.png$/);
  if (match && request.method === 'GET') {
    const id = parseInt(match[1], 10);

    // Check edge cache first
    const cache = await caches.open('og-images');
    const cacheKey = new Request(url.toString());
    const cached = await cache.match(cacheKey);
    if (cached) return cached;

    const info = await fetchPokemonInfo(id);
    if (!info) {
      return new Response('Pokemon not found', { status: 404 });
    }

    logAnalytics(context, {
      event: 'og_image_generate',
      pokemon_id: id,
      pokemon_name: info.name,
    });

    const imageResponse = await generateOgImage(info);

    // Cache the PNG for 7 days at the edge
    const response = new Response(await imageResponse.arrayBuffer(), {
      headers: {
        'Content-Type': 'image/png',
        'Cache-Control': 'public, max-age=604800',
      },
    });

    context.waitUntil(cache.put(cacheKey, response.clone()));
    return response;
  }

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
