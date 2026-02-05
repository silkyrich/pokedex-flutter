#!/usr/bin/env python3
"""Generate an A4 PDF with 8 DexDB marketing cards, each with a QR code."""

import io
import qrcode
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white, black
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader

URL = "https://silkyrich.github.io/pokedex-flutter/"
OUTPUT = "/home/user/pokedex-flutter/dexdb-cards.pdf"

# A4 dimensions
PAGE_W, PAGE_H = A4  # 210mm x 297mm in points

# Card layout: 2 columns x 4 rows = 8 cards
COLS = 2
ROWS = 4
MARGIN_X = 10 * mm
MARGIN_Y = 8 * mm
GAP_X = 6 * mm
GAP_Y = 5 * mm

CARD_W = (PAGE_W - 2 * MARGIN_X - (COLS - 1) * GAP_X) / COLS
CARD_H = (PAGE_H - 2 * MARGIN_Y - (ROWS - 1) * GAP_Y) / ROWS

# Colors
PRIMARY = HexColor("#3B5BA7")  # Ocean theme blue
ACCENT = HexColor("#E65100")   # Fire orange
DARK_BG = HexColor("#1a1a2e")
LIGHT_TEXT = HexColor("#e0e0e0")


def make_qr(url: str) -> ImageReader:
    """Generate a QR code as a reportlab ImageReader."""
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=20,
        border=2,
    )
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="#1a1a2e", back_color="white").convert("RGB")
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return ImageReader(buf)


def draw_card(c: canvas.Canvas, x: float, y: float, w: float, h: float, qr_img):
    """Draw a single marketing card at (x, y) with size (w, h)."""
    r = 3 * mm  # corner radius

    # --- Card background with gradient effect ---
    # Dark background
    c.saveState()
    c.setFillColor(DARK_BG)
    c.roundRect(x, y, w, h, r, fill=1, stroke=0)

    # Accent stripe at top
    stripe_h = 8 * mm
    c.setFillColor(PRIMARY)
    c.rect(x, y + h - stripe_h - r, w, stripe_h + r, fill=1, stroke=0)
    # Re-round the top corners
    c.setFillColor(DARK_BG)
    c.rect(x, y, w, h - stripe_h, fill=1, stroke=0)
    # Redraw rounded rect as clip path overlay
    c.setFillColor(PRIMARY)
    c.roundRect(x, y + h - stripe_h - 2, w, stripe_h + 2 + r, r, fill=1, stroke=0)

    # --- Top stripe: site name ---
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 14)
    c.drawCentredString(x + w / 2, y + h - stripe_h + 1.5 * mm, "DexDB")
    c.setFont("Helvetica", 6.5)
    c.setFillColor(HexColor("#c0d0ff"))
    c.drawCentredString(x + w / 2, y + h - stripe_h - 3 * mm + 1 * mm, "silkyrich.github.io/pokedex-flutter")

    # --- Tagline ---
    tag_y = y + h - stripe_h - 8 * mm
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 9)
    c.drawCentredString(x + w / 2, tag_y, "Your Free Pokemon Database")

    c.setFont("Helvetica", 6.5)
    c.setFillColor(LIGHT_TEXT)
    line1_y = tag_y - 10
    c.drawCentredString(x + w / 2, line1_y, "Stats \u2022 Moves \u2022 Type Matchups \u2022 Quiz")
    c.drawCentredString(x + w / 2, line1_y - 9, "Battle Simulator \u2022 Team Builder \u2022 1025 Pokemon")

    # --- QR Code ---
    qr_size = min(w * 0.52, h * 0.38)
    qr_x = x + (w - qr_size) / 2
    qr_y = y + 13 * mm
    # White background behind QR
    pad = 2 * mm
    c.setFillColor(white)
    c.roundRect(qr_x - pad, qr_y - pad, qr_size + 2 * pad, qr_size + 2 * pad,
                2 * mm, fill=1, stroke=0)
    c.drawImage(qr_img, qr_x, qr_y, qr_size, qr_size)

    # --- "Scan Me" label ---
    c.setFillColor(ACCENT)
    badge_w = 22 * mm
    badge_h = 5 * mm
    badge_x = x + (w - badge_w) / 2
    badge_y = qr_y - badge_h - 2 * mm
    c.roundRect(badge_x, badge_y, badge_w, badge_h, 2 * mm, fill=1, stroke=0)
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 7)
    c.drawCentredString(x + w / 2, badge_y + 1.5 * mm, "SCAN ME!")

    # --- Cut line guides (light dashes) ---
    c.restoreState()


def draw_cut_guides(c: canvas.Canvas):
    """Draw faint cut marks at card boundaries."""
    c.saveState()
    c.setStrokeColor(HexColor("#cccccc"))
    c.setLineWidth(0.3)
    c.setDash(2, 3)

    # Vertical lines between columns
    for col in range(1, COLS):
        lx = MARGIN_X + col * (CARD_W + GAP_X) - GAP_X / 2
        c.line(lx, 3 * mm, lx, PAGE_H - 3 * mm)

    # Horizontal lines between rows
    for row in range(1, ROWS):
        ly = MARGIN_Y + row * (CARD_H + GAP_Y) - GAP_Y / 2
        c.line(3 * mm, ly, PAGE_W - 3 * mm, ly)

    c.restoreState()


def main():
    qr_img = make_qr(URL)
    c = canvas.Canvas(OUTPUT, pagesize=A4)
    c.setTitle("DexDB - QR Cards")
    c.setAuthor("DexDB")

    # Draw 8 cards (2 cols x 4 rows)
    for row in range(ROWS):
        for col in range(COLS):
            cx = MARGIN_X + col * (CARD_W + GAP_X)
            cy = MARGIN_Y + (ROWS - 1 - row) * (CARD_H + GAP_Y)
            draw_card(c, cx, cy, CARD_W, CARD_H, qr_img)

    draw_cut_guides(c)
    c.save()
    print(f"PDF saved to {OUTPUT}")
    print(f"Card size: {CARD_W/mm:.1f}mm x {CARD_H/mm:.1f}mm")
    print(f"Page: A4 (210mm x 297mm), 8 cards with cut guides")


if __name__ == "__main__":
    main()
