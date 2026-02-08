# DexGuide Project State

Last updated: 2026-02-08

## Project Overview

**Name**: DexGuide (formerly Pokemon Database)
**Live Site**: https://dexguide.gg
**Repository**: https://github.com/silkyrich/pokedex-flutter
**Tech Stack**: Flutter Web, Cloudflare Pages, Cloudflare Functions
**Main App Location**: `pokemondb/` subdirectory

## Current Status

### ✅ Recently Completed (2026-02-08)

1. **Version Tracking System** - FULLY OPERATIONAL
   - `/api/version` endpoint returns deployment metadata
   - `scripts/generate_version.sh` generates version.json at build time
   - `scripts/check_deployment.sh` verifies deployed vs local versions
   - Build process updated to generate version info before Flutter build
   - About screen displays version information

2. **Deployment Pipeline** - FIXED
   - Fixed `build.sh` to generate version.json before Flutter build
   - Fixed Cloudflare Pages Functions routing for `/api/*` endpoints
   - Updated `_routes.json` to include `/api/*` in Functions routing
   - Version endpoint integrated into catch-all function at `functions/[[path]].js`

3. **Image Optimization** - COMPLETED
   - Pokemon images cropped to remove whitespace (22px trim, 475px → 431px)
   - Server-side cropping via wsrv.nl proxy
   - Client-side scaling with ClipRect + Transform.scale
   - Documented in `image-trim-technique.md`

### 🚀 Key Features

- **Pokemon Database**: Browse all 1025+ Pokemon with stats, types, moves
- **Team Builder**: Build and analyze competitive teams
- **Team Coverage Analysis**: Analyze type coverage and weaknesses
- **Damage Calculator**: Calculate battle damage with type effectiveness
- **Move Database**: Search and filter all Pokemon moves
- **Type Matchups**: Interactive type effectiveness chart
- **Collection Tracker**: Track your Pokemon collection
- **Pokemon Suggestions**: Get Pokemon suggestions based on team needs
- **Open Graph Cards**: Rich link previews for social media sharing
- **Twitter Player Cards**: Interactive Pokemon cards in tweets

### 📁 Project Structure

```
pokedex-flutter/
├── pokemondb/                    # Main Flutter app
│   ├── lib/
│   │   ├── main.dart            # App entry point
│   │   ├── models/              # Data models (Pokemon, Move, etc.)
│   │   ├── screens/             # UI screens
│   │   ├── services/            # API services, app state
│   │   └── widgets/             # Reusable components
│   ├── web/
│   │   ├── _routes.json         # Cloudflare Pages routing config
│   │   └── version.json         # Build metadata (generated)
│   ├── scripts/
│   │   ├── generate_version.sh  # Generate version.json at build time
│   │   └── check_deployment.sh  # Verify deployment status
│   └── build/web/               # Flutter build output (gitignored)
├── functions/                    # Cloudflare Pages Functions (repository root)
│   ├── [[path]].js              # Catch-all for OG cards + API routes
│   └── api/version.js           # Version endpoint (unused, inline in catch-all)
├── build.sh                      # Cloudflare Pages build script
└── image-trim-technique.md       # Image cropping documentation
```

### 🔧 Build & Deployment

**Build Command** (Cloudflare Pages):
```bash
./build.sh
```

**Build Process**:
1. Install Flutter (if not available)
2. Navigate to `pokemondb/`
3. Run `./scripts/generate_version.sh` to create version.json
4. Run `flutter pub get`
5. Run `flutter build web --release`

**Deployment Target**: `pokemondb/build/web/`

**Verify Deployment**:
```bash
cd pokemondb
./scripts/check_deployment.sh
# Or check API directly:
curl https://dexguide.gg/api/version | jq .
```

### 🔗 API Endpoints

- `https://dexguide.gg/api/version` - Deployment version info
  - Returns: commit SHA, branch, environment, deployment time
  - Used for: Deployment verification

### ⚙️ Configuration Files

**_routes.json** (`pokemondb/web/_routes.json`):
- Controls Cloudflare Pages routing between Functions and static assets
- `include`: Routes handled by Functions (Pokemon detail pages, API, embeds)
- `exclude`: Routes served as static assets (assets directory)

**Current routing**:
```json
{
  "include": ["/pokemon/*", "/embed/*", "/battle/*/*", "/api/*"],
  "exclude": ["/assets/*"]
}
```

### 🎨 Image Handling

**Technique**: 22px uniform crop on PokeAPI artwork
- Original: 475x475px with whitespace
- Cropped: 431x431px (22px trim on each edge)
- **Server-side**: wsrv.nl proxy with `cx=22&cy=22&cw=431&ch=431`
- **Client-side**: Flutter `ClipRect` + `Transform.scale(1.102)`

**Why**: Removes dead space while preserving relative Pokemon sizes

See: `image-trim-technique.md` for full details

### 📊 Data Source

**Primary API**: PokeAPI (https://pokeapi.co)
- Pokemon data, moves, abilities, types
- Evolution chains, species info
- Cached in-memory via `PokeApiService`

**Currently Using** (5 endpoints):
- `/pokemon/{id}` - Pokemon data
- `/pokemon-species/{id}` - Species info
- `/evolution-chain/{id}` - Evolution data
- `/move/{id}` - Move details
- `/pokemon?limit=10000` - Pokemon list

### 🚧 Known Issues / Future Work

**From Plan File** (`~/.claude/plans/elegant-hugging-turing.md`):
- Phase 1: Core Pokemon Enrichment (abilities details, breeding info)
- Phase 2: Items Database & Enhanced Evolution
- Phase 3: Locations & Encounters
- Phase 4: Game Versions, Pokedexes & Growth Rates

**Current Focus**: Version tracking system is complete. No active blockers.

### 🔐 Deployment Credentials

**Cloudflare Pages**:
- Account ID: b306b1f03a33077c78a3fecccaf8dc8c
- Project: pokedex-flutter
- Auth: Global API Key (stored in user's environment)

### 📝 Important Patterns

**Service Layer**: `lib/services/pokeapi_service.dart`
- In-memory caching
- Batch operations for performance
- Lazy loading patterns

**UI Components**:
- `PokemonImage` widget for all Pokemon artwork
- `TypeBadge` for type display
- `StatBar` for stat visualization
- `_sectionCard` pattern for detail screens

**State Management**:
- Provider pattern via `app_state.dart`
- SharedPreferences for persistence

### 🐛 Common Debugging

**Deployment not updating?**
1. Check commit: `./scripts/check_deployment.sh`
2. Check Cloudflare API: See deployment logs
3. Verify build.sh ran version generation

**Functions not working?**
1. Check `_routes.json` includes the route
2. Verify catch-all function doesn't block it
3. Check Cloudflare deployment logs for compilation errors

**Images not loading?**
1. Verify wsrv.nl proxy is accessible
2. Check PokeAPI artwork URLs
3. Ensure PokemonImage widget used correctly

### 📚 Key Documentation Files

- `VERSION_README.md` - Version tracking system overview
- `image-trim-technique.md` - Image cropping technique
- `~/.claude/plans/elegant-hugging-turing.md` - Full PokeAPI v2 integration plan

### 🎯 Quick Commands

```bash
# Check deployment status
cd pokemondb && ./scripts/check_deployment.sh

# Generate version locally
cd pokemondb && ./scripts/generate_version.sh

# Build locally
cd pokemondb && flutter build web --release

# Run dev server
cd pokemondb && flutter run -d chrome

# Check version endpoint
curl https://dexguide.gg/api/version | jq .
```

### 📋 Session Continuity Notes

**Last Working On**: Version tracking system deployment
**Last Commits**: 213a1d7 (version tracking complete)
**Production Status**: ✅ Up to date
**No Active Blockers**: Ready for next feature work

**Next Suggested Work**:
- Review plan file for Phase 1 implementation (Pokemon enrichment)
- Or continue with any user-requested features

---

**Note**: This file should be updated at major milestones or when project state changes significantly. Use it as a reference point when resuming work.
