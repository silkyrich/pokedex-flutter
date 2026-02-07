# Pokemon Image Trim Technique

## Problem
PokeAPI's official artwork images are 475×475px with approximately 22px of transparent padding on all edges. This excess whitespace makes Pokemon appear smaller and less prominent in grid layouts.

## Solution: Uniform Trim
The key insight is that **every PokeAPI artwork has identical padding**. This allows us to apply a uniform 22px crop to all images without needing per-image analysis.

### Why This Works
- All Pokemon images have the same 22px border
- Cropping the same amount from every image preserves relative sizes
- A Pikachu will still appear smaller than a Wailord
- No image processing or storage needed

## Implementation

### 1. Server-Side (OG Images, Embeds)
Use [wsrv.nl](https://wsrv.nl) - a free, open-source image proxy that crops on-the-fly:

```javascript
const CROPPED_ARTWORK_URL = (id) =>
  `https://wsrv.nl/?url=raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${id}.png&cx=22&cy=22&cw=431&ch=431`;
```

**Parameters:**
- `cx=22, cy=22` - Crop starting position (22px from top-left)
- `cw=431, ch=431` - Crop dimensions (475 - 22 - 22 = 431)

**Benefits:**
- Zero processing cost for our infrastructure
- wsrv.nl fetches from PokeAPI, crops, and serves
- No copyrighted bytes touch our servers
- Works for social media OG images, embeds, etc.

### 2. Client-Side (Flutter App)
Use `ClipRect` + `Transform.scale` for visual cropping:

```dart
Widget _buildCroppedArtwork(Widget child) {
  return ClipRect(
    child: Transform.scale(
      scale: 475 / 431,  // 1.102... - zoom in slightly
      child: child,
    ),
  );
}
```

**How it works:**
- Scale up the image by 475/431 (≈1.102)
- ClipRect cuts off the overflow
- Zero processing cost - pure CSS transform
- Works on any artwork image

## Numbers
- Original: 475×475px
- Trim: 22px from each edge
- Result: 431×431px of actual content
- Scale factor: 475/431 ≈ 1.1021

## Commit History
- Original implementation: `claude/pokemon-transparent-backgrounds-6hLAh`
- Server-side (wsrv.nl): commit `40cb08e`
- Client-side (ClipRect): commit `f0ae207`
- Applied everywhere: commit `7fc396b`

## Remember
This is a **uniform** trim, not per-image cropping. The magic is that all Pokemon share the same border size, making this simple technique possible while preserving their true relative sizes.
