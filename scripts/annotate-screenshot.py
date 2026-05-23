#!/usr/bin/env python3
"""
annotate-screenshot.py — Overlay a coordinate grid on a screenshot.

Usage:
    python3 annotate-screenshot.py INPUT.png OUTPUT.png [--grid N] [--marks "X1,Y1 X2,Y2 ..."]

Options:
    --grid N      Grid spacing in pixels (default: 100). Reduce for zoomed views.
    --marks XS    Space-separated list of X,Y pairs to mark with crosshairs.

Output:
    A copy of the input with:
      - Semi-transparent coordinate grid (every N px)
      - Axis labels at each grid line
      - Optional crosshair markers at specified coordinates

Purpose:
    Claude reads the annotated image and can identify element coordinates precisely
    from the grid labels instead of guessing from visual position.
"""

import sys
import argparse
from PIL import Image, ImageDraw, ImageFont

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Input PNG path")
    parser.add_argument("output", help="Output PNG path")
    parser.add_argument("--grid", type=int, default=100, help="Grid spacing in pixels")
    parser.add_argument("--marks", type=str, default="", help="Crosshair marks: 'X1,Y1 X2,Y2'")
    return parser.parse_args()

def draw_grid(img, grid_size):
    """Draw semi-transparent coordinate grid with axis labels."""
    w, h = img.size

    # Create overlay for semi-transparent grid lines
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    grid_draw = ImageDraw.Draw(overlay)

    GRID_COLOR = (255, 80, 80, 60)       # Red, semi-transparent
    LABEL_BG   = (0, 0, 0, 160)          # Dark background for labels
    LABEL_FG   = (255, 255, 80, 255)     # Yellow label text
    ZERO_COLOR = (255, 80, 80, 120)      # Slightly stronger at 0

    # Vertical lines (X axis labels at top)
    for x in range(0, w, grid_size):
        color = ZERO_COLOR if x == 0 else GRID_COLOR
        grid_draw.line([(x, 0), (x, h)], fill=color, width=1)
        # Label background + text
        label = str(x)
        lw = len(label) * 7 + 4
        grid_draw.rectangle([x + 1, 2, x + lw, 16], fill=LABEL_BG)
        grid_draw.text((x + 3, 3), label, fill=LABEL_FG)

    # Horizontal lines (Y axis labels at left)
    for y in range(0, h, grid_size):
        color = ZERO_COLOR if y == 0 else GRID_COLOR
        grid_draw.line([(0, y), (w, y)], fill=color, width=1)
        label = str(y)
        lw = len(label) * 7 + 4
        grid_draw.rectangle([2, y + 1, lw, y + 15], fill=LABEL_BG)
        grid_draw.text((3, y + 2), label, fill=LABEL_FG)

    # Composite grid onto image
    result = Image.alpha_composite(img.convert("RGBA"), overlay)
    return result

def draw_marks(img, marks_str):
    """Draw crosshair + coordinate label at each specified X,Y point."""
    if not marks_str.strip():
        return img

    draw = ImageDraw.Draw(img)
    CROSS_COLOR = (0, 255, 128, 255)   # Bright green
    CROSS_BG    = (0, 0, 0, 200)

    for pair in marks_str.strip().split():
        try:
            x, y = map(int, pair.split(","))
        except ValueError:
            continue

        # Draw crosshair lines
        arm = 20
        draw.line([(x - arm, y), (x + arm, y)], fill=CROSS_COLOR, width=2)
        draw.line([(x, y - arm), (x, y + arm)], fill=CROSS_COLOR, width=2)
        draw.ellipse([(x-4, y-4), (x+4, y+4)], fill=CROSS_COLOR)

        # Coordinate label
        label = f"({x}, {y})"
        lw = len(label) * 7 + 6
        lx = x + 10 if x + lw < img.width else x - lw - 5
        ly = y - 18 if y - 18 > 0 else y + 8
        draw.rectangle([lx, ly, lx + lw, ly + 15], fill=CROSS_BG)
        draw.text((lx + 3, ly + 2), label, fill=CROSS_COLOR)

    return img

def main():
    args = parse_args()
    img = Image.open(args.input)
    img = draw_grid(img, args.grid)
    if args.marks:
        img = draw_marks(img, args.marks)
    img.convert("RGB").save(args.output, "PNG")
    print(args.output)

if __name__ == "__main__":
    main()
